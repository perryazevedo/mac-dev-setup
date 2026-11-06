#!/usr/bin/env bash
# Per-machine configuration that bootstrap.sh does not do: SSH keys and host
# aliases, git identity with per-folder commit emails, PATH ordering that
# survives macOS path_helper, pinned mise global tools, and a mode-600 env
# file for secrets. Everything machine-specific comes from
# ~/.config/mac-dev-setup/machine.conf, which is never committed. See
# configs/machine.conf.example for the shape.
#
# Every step prints what it will do, is idempotent, and can be run on its own:
#   ./scripts/setup-machine.sh                 # all steps
#   ./scripts/setup-machine.sh --only ssh      # one step (ssh git path mise env)
#   ./scripts/setup-machine.sh --server        # also report agent-server settings
#
# Works with the macOS /bin/bash (3.2): no associative arrays, no mapfile.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF_DIR="$HOME/.config/mac-dev-setup"
CONF="$CONF_DIR/machine.conf"
CONF_EXAMPLE="$REPO_ROOT/configs/machine.conf.example"
GIT_INCLUDE_DIR="$CONF_DIR/git"
ENV_FILE="$HOME/.config/claude/env"
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
SSH_CONFIG="$SSH_DIR/config"
ZPROFILE="$HOME/.zprofile"
ZSHRC="$HOME/.zshrc"
MISE_GLOBAL_CONFIG="$HOME/.config/mise/config.toml"
MISE_SHIMS="$HOME/.local/share/mise/shims"

ALL_STEPS="ssh git path mise env"

# Values read from machine.conf (defaults so `set -u` is happy if a key is missing)
GIT_NAME=""
SSH_HOSTS=()
GIT_FOLDER_EMAILS=()
MISE_TOOLS=()
ENV_VARS=()

say()    { echo ">> $*"; }
header() { echo; echo "-- $1 --"; }
die()    { echo ">> Error: $*" >&2; exit 1; }
interactive() { [[ -t 0 ]]; }
has_cmd() { command -v "$1" >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/$1" ]]; }

# ask_yn "question" [y|n]  → 0 for yes. Non-interactive runs never say yes to
# anything optional; they report what was skipped instead.
ask_yn() {
  local q="$1" def="${2:-n}" hint reply
  if ! interactive; then
    say "(non-interactive) skipping: $q"
    return 1
  fi
  if [[ "$def" == y ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  read -r -p ">> $q $hint " reply || reply=""
  reply="$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')"
  case "$reply" in
    y|yes) return 0 ;;
    n|no)  return 1 ;;
    "")    [[ "$def" == y ]] ;;
    *)     return 1 ;;
  esac
}

# write_if_changed FILE CONTENT LABEL → writes only when different, mode 600
write_if_changed() {
  local file="$1" content="$2" label="$3"
  if [[ -f "$file" ]] && [[ "$(cat "$file")" == "$content" ]]; then
    say "$label already up to date ($file)"
    return 0
  fi
  (umask 077; printf '%s\n' "$content" > "$file")
  chmod 600 "$file"
  say "$label written → $file"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--only STEP[,STEP...]] [--server] [--help]

Steps (default: all, in this order): $ALL_STEPS
  ssh    ~/.ssh/id_ed25519 if absent, Host blocks in ~/.ssh/config, ssh-copy-id offer
  git    user.name, per-folder commit emails via includeIf, gpgsign check
  path   ~/bin and mise shims ahead of /usr/bin in ~/.zprofile (path_helper-proof)
  mise   pin global tool versions from machine.conf
  env    $ENV_FILE (mode 600, names only) sourced from ~/.zshrc

Flags:
  --only STEP   run only this step; repeat or comma-separate for several
  --server      additionally report sleep, FileVault/auto-login and firewall
                state for a machine that runs unattended (report only)
  --help        this text

Config: $CONF (mode 600, never committed).
Created interactively on first run; shape in configs/machine.conf.example.
EOF
}

# ---------------------------------------------------------------------------
# machine.conf
# ---------------------------------------------------------------------------

# Write a bash array assignment with one quoted item per line.
conf_array() {
  local name="$1"; shift
  echo "$name=("
  local item
  for item in "$@"; do
    [[ -n "$item" ]] && printf '  "%s"\n' "$item"
  done
  echo ")"
}

create_conf() {
  say "No $CONF yet. Creating it now (mode 600; it is never committed)."
  say "Leave an answer blank to finish a list. Edit the file by hand later if you prefer."
  echo
  local name hosts=() alias addr user emails=() folder email tools vars

  read -r -p ">> Git user.name (shown on commits): " name || name=""

  echo
  say "SSH hosts. Each one becomes a Host block in ~/.ssh/config."
  while :; do
    read -r -p ">> Host alias (blank to finish): " alias || alias=""
    [[ -n "$alias" ]] || break
    read -r -p ">>   Address (IP or DNS name) for $alias: " addr || addr=""
    read -r -p ">>   SSH username on $alias [$USER]: " user || user=""
    user="${user:-$USER}"
    hosts+=("$alias:$addr:$user")
  done

  echo
  say "Per-folder commit emails. Commits under a folder use that email; the"
  say "global user.email stays unset so misattribution fails loudly instead."
  while :; do
    read -r -p ">> Project folder (e.g. ~/Projects; blank to finish): " folder || folder=""
    [[ -n "$folder" ]] || break
    read -r -p ">>   Commit email for $folder: " email || email=""
    emails+=("${folder/#\~/\$HOME}:$email")
  done

  echo
  say "mise global tools, pinned so machines match (e.g. node@lts ruby@3.3.4 bun@latest)."
  read -r -p ">> Tools, space separated (blank for none): " tools || tools=""

  echo
  say "Secret environment variable NAMES for $ENV_FILE. Names only; you fill the"
  say "values from your password manager afterwards."
  read -r -p ">> Variable names, space separated (blank for none): " vars || vars=""

  mkdir -p "$CONF_DIR"
  chmod 700 "$CONF_DIR"
  # shellcheck disable=SC2086
  (
    umask 077
    {
      echo "# mac-dev-setup machine config. Sourced by bash; keep it to quoted strings."
      echo "# Generated $(date '+%Y-%m-%d') by setup-machine.sh. Never commit this file."
      echo
      printf 'GIT_NAME="%s"\n' "$name"
      echo
      echo "# alias:address:username — one Host block each in ~/.ssh/config"
      conf_array SSH_HOSTS ${hosts[@]+"${hosts[@]}"}
      echo
      echo "# folder:email — includeIf gitdir blocks in ~/.gitconfig"
      conf_array GIT_FOLDER_EMAILS ${emails[@]+"${emails[@]}"}
      echo
      echo "# tool@version — pinned with mise use -g"
      conf_array MISE_TOOLS $tools
      echo
      echo "# Names only. Values live in your password manager."
      conf_array ENV_VARS $vars
    } > "$CONF"
  )
  say "Wrote $CONF"
  echo
}

load_conf() {
  if [[ ! -f "$CONF" ]]; then
    if interactive; then
      create_conf
    else
      die "no $CONF. Run this script from a terminal once to create it, or copy $CONF_EXAMPLE there and edit it (chmod 600)."
    fi
  fi
  local mode
  mode="$(stat -f '%Lp' "$CONF")"
  if [[ "$mode" != "600" ]]; then
    chmod 600 "$CONF"
    say "Fixed $CONF permissions ($mode → 600)"
  fi
  # shellcheck source=/dev/null
  source "$CONF"
}

# ---------------------------------------------------------------------------
# 1. SSH
# ---------------------------------------------------------------------------

# Replace the `Host ALIAS` block (up to the next Host/Match line) in place, or
# append it. Blocks for other aliases are untouched byte for byte.
ssh_config_upsert() {
  local alias="$1" block="$2" tmp
  tmp="$(mktemp)"
  # BSD awk rejects literal newlines in -v values; pass the block with \n escapes instead.
  awk -v alias="$alias" -v block="${block//$'\n'/\\n}" '
    { lines[NR] = $0 }
    END {
      skip = 0; done = 0
      for (i = 1; i <= NR; i++) {
        $0 = lines[i]
        if (!done && $1 == "Host" && NF == 2 && $2 == alias) {
          print block; skip = 1; done = 1; continue
        }
        if (skip) {
          if ($1 == "Host" || $1 == "Match") { skip = 0; print "" } else { continue }
        }
        print lines[i]
      }
      if (!done) {
        if (NR > 0 && lines[NR] != "") print ""
        print block
      }
    }' "$SSH_CONFIG" > "$tmp"
  if cmp -s "$tmp" "$SSH_CONFIG"; then
    say "Host $alias already up to date in $SSH_CONFIG"
  else
    cat "$tmp" > "$SSH_CONFIG"
    say "Host $alias written to $SSH_CONFIG"
  fi
  rm -f "$tmp"
}

step_ssh() {
  header "SSH keys and host aliases"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  if [[ -f "$SSH_KEY" ]]; then
    say "Key exists: $SSH_KEY (never overwritten)"
  elif interactive; then
    local comment
    read -r -p ">> No $SSH_KEY. Comment for the new key (e.g. you@this-mac): " comment || comment=""
    [[ -n "$comment" ]] || comment="$USER@$(hostname -s)"
    say "Generating ed25519 key $SSH_KEY (ssh-keygen asks for a passphrase next)"
    ssh-keygen -t ed25519 -C "$comment" -f "$SSH_KEY"
  else
    say "No $SSH_KEY and not interactive; run from a terminal to generate one"
  fi

  [[ -f "$SSH_CONFIG" ]] || (umask 077; touch "$SSH_CONFIG")
  chmod 600 "$SSH_CONFIG"

  if [[ ${#SSH_HOSTS[@]} -eq 0 ]]; then
    say "SSH_HOSTS is empty in machine.conf; no Host blocks to write"
    return 0
  fi

  local entry alias addr user block aliases=()
  for entry in "${SSH_HOSTS[@]}"; do
    IFS=: read -r alias addr user <<<"$entry"
    if [[ -z "$alias" || -z "$addr" || -z "$user" ]]; then
      say "Skipping malformed SSH_HOSTS entry (want alias:address:user): $entry"
      continue
    fi
    block="$(printf 'Host %s\n  HostName %s\n  User %s\n  IdentityFile ~/.ssh/id_ed25519\n  IdentitiesOnly yes' "$alias" "$addr" "$user")"
    ssh_config_upsert "$alias" "$block"
    aliases+=("$alias")
  done
  [[ ${#aliases[@]} -gt 0 ]] || return 0

  if [[ -f "$SSH_KEY.pub" ]]; then
    echo
    say "ssh-copy-id puts this machine's public key on a host so it stops asking for a password."
    say "It must be run from this machine, and the host needs Remote Login enabled"
    say "(System Settings → General → Sharing → Remote Login). Unreachable hosts are normal; retry later."
    for alias in "${aliases[@]}"; do
      if ask_yn "Run ssh-copy-id $alias now?" n; then
        ssh-copy-id -i "$SSH_KEY.pub" -o ConnectTimeout=5 "$alias" \
          || say "ssh-copy-id $alias failed (host off, unreachable, or Remote Login disabled); nothing else changed"
      fi
    done
  fi

  echo
  say "Effective config (ssh -G <alias>):"
  for alias in "${aliases[@]}"; do
    echo "   ssh -G $alias"
    ssh -G -F "$SSH_CONFIG" "$alias" 2>/dev/null | grep -E '^(hostname|user|identityfile|identitiesonly) ' | sed 's/^/      /' \
      || echo "      (ssh -G failed)"
  done
}

# ---------------------------------------------------------------------------
# 2. Git
# ---------------------------------------------------------------------------

step_git() {
  header "Git identity and per-folder commit email"

  if [[ -z "$GIT_NAME" ]]; then
    say "GIT_NAME is empty in machine.conf; leaving user.name alone"
  elif [[ "$(git config --global --get user.name || true)" == "$GIT_NAME" ]]; then
    say "user.name already \"$GIT_NAME\""
  else
    git config --global user.name "$GIT_NAME"
    say "Set global user.name to \"$GIT_NAME\""
  fi

  if [[ -n "$(git config --global --get user.email || true)" ]]; then
    say "Global user.email is set. This setup leaves it unset on purpose: with per-folder"
    say "emails below, a commit outside any mapped folder then fails with 'Please tell me who"
    say "you are' instead of being quietly attributed to the wrong address."
    if ask_yn "Unset the global user.email?" y; then
      git config --global --unset user.email
      say "Unset global user.email"
    fi
  else
    say "Global user.email is unset (intended; per-folder includes supply it)"
  fi

  if [[ ${#GIT_FOLDER_EMAILS[@]} -eq 0 ]]; then
    say "GIT_FOLDER_EMAILS is empty in machine.conf; no includeIf blocks to write"
  else
    mkdir -p "$GIT_INCLUDE_DIR"
    chmod 700 "$CONF_DIR" "$GIT_INCLUDE_DIR"
    local entry folder email slug file key content
    for entry in "${GIT_FOLDER_EMAILS[@]}"; do
      folder="${entry%:*}"
      email="${entry##*:}"
      if [[ -z "$folder" || -z "$email" || "$folder" == "$entry" ]]; then
        say "Skipping malformed GIT_FOLDER_EMAILS entry (want folder:email): $entry"
        continue
      fi
      folder="${folder/#\~/$HOME}"
      folder="${folder%/}"
      slug="$(printf '%s' "${folder#$HOME/}" | tr -c 'A-Za-z0-9._' '-' | tr '[:upper:]' '[:lower:]')"
      file="$GIT_INCLUDE_DIR/$slug.gitconfig"
      content="$(printf '[user]\n\temail = %s' "$email")"
      write_if_changed "$file" "$content" "Email for $folder/"
      key="includeIf.gitdir:$folder/.path"
      if [[ "$(git config --global --get "$key" || true)" == "$file" ]]; then
        say "includeIf for $folder/ already in ~/.gitconfig"
      else
        git config --global "$key" "$file"
        say "Added includeIf \"gitdir:$folder/\" → $file to ~/.gitconfig"
      fi
    done
  fi

  if [[ "$(git config --global --get commit.gpgsign || true)" == "true" ]]; then
    echo
    say "commit.gpgsign is on. On a headless machine every commit hangs waiting for a"
    say "passphrase unless the signing key has none. Turn it off there with:"
    say "   git config --global commit.gpgsign false"
    if [[ "$SERVER" -eq 1 ]] && ask_yn "This is a --server run. Turn commit.gpgsign off on this machine?" y; then
      git config --global commit.gpgsign false
      say "Set commit.gpgsign false"
    fi
  else
    say "commit.gpgsign is off or unset (no headless signing hang to worry about)"
  fi
}

# ---------------------------------------------------------------------------
# 3. PATH
# ---------------------------------------------------------------------------

step_path() {
  header "PATH (~/bin and mise shims, path_helper-proof)"
  mkdir -p "$HOME/bin"
  [[ -f "$ZPROFILE" ]] || touch "$ZPROFILE"

  if grep -q 'mac-dev-setup: PATH' "$ZPROFILE" 2>/dev/null; then
    say "PATH block already in $ZPROFILE"
  else
    say "Appending PATH block to $ZPROFILE (not ~/.zshrc; see the comment in the block)"
    cat >> "$ZPROFILE" <<'ZPROFILE_BLOCK'

# mac-dev-setup: PATH for login shells. This belongs in ~/.zprofile, not ~/.zshrc.
# macOS runs /usr/libexec/path_helper from /etc/zprofile for every login shell, and it
# rebuilds PATH with /usr/bin ahead of whatever PATH was handed in. Non-interactive login
# shells (launchd jobs, `ssh host cmd`, cron) never read ~/.zshrc, so a PATH set only
# there, or only in a launchd job's environment, loses and you silently get the system
# Ruby and Python instead of mise's. ~/.zprofile runs after path_helper, so this wins.
# This cost a day of debugging on the agent server.
export PATH="$HOME/bin:$HOME/.local/share/mise/shims:$PATH"
ZPROFILE_BLOCK
  fi

  # Report on the current shell; the block only takes effect in a new login shell.
  local shims_pos usrbin_pos
  shims_pos="$(echo "$PATH" | tr ':' '\n' | grep -nx "$MISE_SHIMS" | cut -d: -f1 | head -1 || true)"
  usrbin_pos="$(echo "$PATH" | tr ':' '\n' | grep -nx '/usr/bin' | cut -d: -f1 | head -1 || true)"
  if [[ -n "$shims_pos" && -n "$usrbin_pos" && "$shims_pos" -lt "$usrbin_pos" ]]; then
    say "This shell already has mise shims ahead of /usr/bin"
  else
    say "This shell does not yet have mise shims ahead of /usr/bin; open a new terminal (login shell) to pick it up"
  fi
}

# ---------------------------------------------------------------------------
# 4. mise
# ---------------------------------------------------------------------------

step_mise() {
  header "mise global tools"
  if ! has_cmd mise; then
    say "mise not found; run ./scripts/bootstrap.sh first"
    return 0
  fi
  if [[ ${#MISE_TOOLS[@]} -eq 0 ]]; then
    say "MISE_TOOLS is empty in machine.conf; nothing to pin"
    return 0
  fi
  local tool name want have
  for tool in "${MISE_TOOLS[@]}"; do
    name="${tool%%@*}"
    want="${tool#*@}"
    [[ "$tool" == *@* ]] || want="latest"
    have=""
    if [[ -f "$MISE_GLOBAL_CONFIG" ]]; then
      have="$(mise config get --file "$MISE_GLOBAL_CONFIG" "tools.$name" 2>/dev/null || true)"
    fi
    if [[ "$have" == "$want" ]]; then
      say "$name already pinned to $want in $MISE_GLOBAL_CONFIG"
    else
      say "Pinning $name@$want globally (mise use -g $tool; installs if needed)"
      # Run from $HOME so a project .mise.toml in the current directory cannot interfere.
      (cd "$HOME" && mise use -g "$tool") \
        || say "mise use -g $tool failed (see above); fix it and re-run with --only mise"
    fi
  done
}

# ---------------------------------------------------------------------------
# 5. Secrets env file
# ---------------------------------------------------------------------------

step_env() {
  header "Secrets environment file"
  local dir var added=0
  dir="$(dirname "$ENV_FILE")"
  mkdir -p "$dir"
  chmod 700 "$dir"

  if [[ ! -f "$ENV_FILE" ]]; then
    say "Creating $ENV_FILE (mode 600) with empty export lines"
    (
      umask 077
      {
        echo "# Secrets for shells and agents. Fill values from your password manager;"
        echo "# the password manager is the canonical copy, this file is a convenience."
        echo "# Names come from ~/.config/mac-dev-setup/machine.conf (ENV_VARS)."
      } > "$ENV_FILE"
    )
  fi
  chmod 600 "$ENV_FILE"

  if [[ ${#ENV_VARS[@]} -eq 0 ]]; then
    say "ENV_VARS is empty in machine.conf; no names to add"
  else
    for var in "${ENV_VARS[@]}"; do
      if ! [[ "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        say "Skipping invalid variable name: $var"
        continue
      fi
      if grep -qE "^export ${var}=" "$ENV_FILE"; then
        say "$var already present (value untouched)"
      else
        echo "export ${var}=" >> "$ENV_FILE"
        say "Added $var (empty)"
        added=1
      fi
    done
  fi

  [[ -f "$ZSHRC" ]] || touch "$ZSHRC"
  if grep -q '\.config/claude/env' "$ZSHRC" 2>/dev/null; then
    say "~/.zshrc already sources $ENV_FILE"
  else
    {
      echo ''
      echo '# Secrets (names managed by mac-dev-setup; values from your password manager)'
      echo '[ -f "$HOME/.config/claude/env" ] && source "$HOME/.config/claude/env"'
    } >> "$ZSHRC"
    say "Added source line for $ENV_FILE to ~/.zshrc"
  fi

  echo
  say "Reminder: the canonical copy of every value lives in your password manager."
  say "$ENV_FILE is a convenience for shells and agents, not a store. Fill it with:"
  say "   \$EDITOR $ENV_FILE"
  if has_cmd pass-cli; then
    say "pass-cli is installed and is the preferred route when a command can be wrapped:"
    say "   pass-cli run -- claude      # secrets injected as env vars, nothing on disk"
    say "Use the env file for what cannot be wrapped (launchd agents, plain shells)."
  fi
  [[ "$added" -eq 1 ]] && say "New names were added; open a new shell after filling them in."
  return 0
}

# ---------------------------------------------------------------------------
# 6. --server report (never changes anything)
# ---------------------------------------------------------------------------

step_server() {
  header "Agent-server report (--server; report only, nothing is changed)"

  say "Power (pmset -g):"
  pmset -g 2>/dev/null | grep -E '^[[:space:]]*(sleep|disksleep|displaysleep|autorestart|womp|powernap)[[:space:]]' | sed 's/^/      /' \
    || echo "      (pmset -g failed)"
  say "A 24/7 machine wants sleep 0, disksleep 0, autorestart 1 (come back after a power cut),"
  say "womp 1 (wake on LAN). displaysleep can stay. To set:"
  say "   sudo pmset -a sleep 0 disksleep 0 autorestart 1 womp 1"

  echo
  local fv autologin
  fv="$(fdesetup status 2>/dev/null || echo 'FileVault status unknown')"
  autologin="$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true)"
  say "FileVault: $fv"
  if [[ -n "$autologin" ]]; then
    say "Automatic login: on (a user is set)"
  else
    say "Automatic login: off"
  fi
  if [[ "$fv" == *"On"* ]] && [[ -n "$autologin" ]]; then
    say "Conflict: FileVault is on, so after a restart the disk stays locked until someone types"
    say "a password at the pre-boot screen. Automatic login cannot run until then."
  elif [[ "$fv" == *"On"* ]]; then
    say "FileVault is on: after an unattended restart the machine waits at the pre-boot unlock"
    say "screen and no user session exists until someone types a password."
  fi
  say "launchd user agents (~/Library/LaunchAgents) only exist inside a logged-in session."
  say "Without automatic login they do not start after a reboot at all. An unattended box"
  say "needs FileVault off plus automatic login, or a person at the keyboard after every"
  say "power cut. Decide in System Settings; this script never changes security settings."

  echo
  local fw="/usr/libexec/ApplicationFirewall/socketfilterfw"
  if [[ -x "$fw" ]]; then
    say "Application firewall: $("$fw" --getglobalstate 2>/dev/null || echo unknown)"
    say "Stealth mode: $("$fw" --getstealthmode 2>/dev/null || echo unknown)"
  else
    say "Application firewall: socketfilterfw not found"
  fi
  say "When the firewall is on it silently drops inbound connections to a locally served port"
  say "unless the serving binary is allowed, and the allow rule matches the exact binary path."
  say "Homebrew installs under version-specific paths (/opt/homebrew/Cellar/<formula>/<version>/),"
  say "so every brew upgrade changes the path and the rule stops matching. If a service stops"
  say "answering after an upgrade, check System Settings → Network → Firewall first."
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

SERVER=0
ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      [[ $# -ge 2 ]] || die "--only needs a step name"
      ONLY="$ONLY ${2//,/ }"
      shift
      ;;
    --only=*)
      ONLY="$ONLY ${1#--only=}"
      ONLY="${ONLY//,/ }"
      ;;
    --server) SERVER=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac
  shift
done

STEPS="$ALL_STEPS"
if [[ -n "$ONLY" ]]; then
  STEPS=""
  for s in $ONLY; do
    case "$s" in
      ssh|git|path|mise|env) STEPS="$STEPS $s" ;;
      server) SERVER=1 ;;
      *) die "unknown step '$s' (want one of: $ALL_STEPS server)" ;;
    esac
  done
fi

echo "== mac-dev-setup machine setup =="
load_conf
say "Using $CONF"

for s in $STEPS; do
  "step_$s"
done
[[ "$SERVER" -eq 1 ]] && step_server

echo
say "Machine setup complete."
if [[ -z "$ONLY" ]]; then
  echo "   By hand, afterwards:"
  echo "   1) Fill $ENV_FILE from your password manager (names only were written)"
  echo "   2) Enable Remote Login on each host (System Settings → General → Sharing), then ssh-copy-id <alias>"
  echo "   3) Give each host a DHCP reservation on the router so its pinned address stays pinned"
  echo "   4) Open a new terminal so ~/.zprofile and ~/.zshrc changes apply"
fi
