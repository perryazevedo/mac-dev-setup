# mac-dev-setup

Opinionated, fast macOS development setup for **Ruby on Rails**, **JavaScript/TypeScript**, **React**, **React Native**, and **Angular** on **Apple Silicon**.
Uses **Homebrew** for system packages, **Mise** as the unified runtime/version manager, and a few quality-of-life CLIs.

> Works great for a fresh **Mac Studio** *and* re-provisioning your **MacBook Pro**.

---

## TL;DR

```bash
# 0) Xcode Command Line Tools
xcode-select --install || true

# 1) Clone and run bootstrap
git clone https://your.git.host/you/mac-dev-setup.git
cd mac-dev-setup
./scripts/bootstrap.sh
# Bootstrap installs Homebrew packages (Brewfile), shell hooks, and native CLIs.
# After bootstrap, start a new terminal session (or run `exec zsh`) for tools to be available.
# You will be asked whether to clear pinned Dock apps / hide recents (default: yes),
# and whether to set Hot Corners (Screen Saver, Desktop, Mission Control) (default: yes).

# 2) Sign in to CLIs (browser flows)
gh auth login && gh auth setup-git
origin auth login
pass-cli login
proton-drive auth login
# claude / grok / codex prompt on first launch

# 3) Provision runtimes (user-global defaults)
mise use -g ruby@latest
mise use -g node@lts
mise use -g bun@latest
corepack enable   # pnpm/yarn shims

# 4) Start services
brew services start postgresql@16
brew services start redis

# 5) Per-machine config: SSH hosts, git identity, PATH, mise pins, secrets env file
./scripts/setup-machine.sh
# Asks for a machine-local config on first run (never committed). See "Machine setup".
```

> Optional: Install **OrbStack** (via cask in `Brewfile`) and use it for Docker; or use **Colima** (installed via brew).

On a machine that was set up before this repo was updated, run `./scripts/doctor.sh` to see what is missing.

---

## What you get

- **Mise**: one tool to manage Ruby, Node, Java, etc. Per-project versions via `.mise.toml`.
- **Ruby** toolchain + common compile deps for Apple Silicon.
- **Node LTS** + **pnpm** (via Corepack) and **Bun** (via Mise) for fast dev/test.
- Databases: **PostgreSQL 16**, **Redis**.
- React Native helpers: **watchman**, **cocoapods**; **Android Studio** via cask.
- Container runtime: **OrbStack** (preferred) or **Colima**.
- CLIs: `ripgrep`, `fd`, `fzf`, `zoxide`, `eza`, `jq`, `yq`, `tree`, `gh`.
- Terminal: **Ghostty** (GPU-accelerated) with **MesloLGS Nerd Font Mono**. Terminal.app and iTerm2 still work.
- Prompt: **Starship** with sensible defaults (`configs/starship.toml`).
- Zsh plugins: **zsh-autosuggestions**, **zsh-syntax-highlighting**.
- Shell aliases: `ls`/`ll`/`la` → **eza** with icons; smart `cd` via **zoxide** (`z`).
- Editors: **Cursor** (with `cursor` shell command), **VS Code**, **Zed**.
- DB GUI: **TablePlus** (and optional Postico).
- Issue tracker: **Linear**.

### AI / git / secrets CLIs

| Binary | What it is | How it is installed |
| --- | --- | --- |
| `gh` | GitHub CLI | Homebrew (`Brewfile` + bootstrap early install) |
| `claude` | Claude Code | Native installer (auto-updates) |
| `grok` | Grok Build | Native installer (auto-updates) |
| `cursor` | Open files/folders in Cursor | `cask "cursor"` |
| `cursor-agent` | Cursor terminal coding agent | `cask "cursor-cli"` |
| `origin` | Cursor Origin git forge | Native installer (auto-updates) |
| `codex` | OpenAI Codex CLI | `cask "codex"` |
| `pass-cli` | Proton Pass (secrets, SSH agent) | Native installer (auto-updates) |
| `proton-drive` | Proton Drive filesystem CLI | Versioned official binary |

Matching desktop apps: **Claude**, **ChatGPT**, **Grok Bot**, **Cursor**.

---

## Terminal Compatibility

This setup works across **Ghostty**, **Terminal.app**, and **iTerm2** on macOS. The bootstrap script configures:

- **Homebrew**: Added to both `~/.zprofile` (login shells) and `~/.zshrc` (non-login shells) for maximum compatibility
- **Mise**: Activated in `~/.zshrc` to manage runtimes
- **Starship**: Initialized in `~/.zshrc` as your prompt
- **Zoxide**: Initialized in `~/.zshrc` for smart directory jumping (`z`)
- **eza aliases**: `ls`, `ll`, `la` with icons
- **Zsh plugins**: autosuggestions and syntax highlighting
- **fzf**: Key bindings and completion installed automatically

### Ghostty (recommended)

**Ghostty** is a GPU-accelerated terminal emulator installed via the Brewfile. The bootstrap script copies `configs/ghostty/config` to `~/.config/ghostty/config` if no config exists yet.

The default Ghostty config sets:
- **Font**: MesloLGS Nerd Font Mono (installed via `font-meslo-lg-nerd-font`)
- **Theme**: Argonaut (run `ghostty +list-themes` to browse alternatives)
- **Background opacity**: 85%

A SSH TERM fix is added to `~/.zshrc` so remote servers that don't recognise `xterm-ghostty` fall back to `xterm-256color`.

### Starship Config

The bootstrap script copies `configs/starship.toml` to `~/.config/starship.toml` if no config exists yet. It includes shorter directory paths, command duration display, and Git status styling.

To use a preset instead, run:

```bash
starship preset tokyo-night -o ~/.config/starship.toml
```

---

## AI coding agents

Bootstrap installs the CLIs. Each one signs in on first launch (browser).

```bash
claude          # Claude Code TUI
grok            # Grok Build TUI
cursor-agent    # Cursor's terminal agent
codex           # OpenAI Codex
```

**`agent` name collision:** Grok's installer also ships a binary named `agent`. This setup treats `agent` as Grok. Invoke Cursor's terminal agent as `cursor-agent`, not `agent`.

### Origin (Cursor git forge)

Origin is Cursor's git host. It is **not** a replacement for GitHub or `gh`.

```bash
origin auth login
origin repo create my-project
git remote add origin https://origin.cursor.com/{owner}/{repo}.git
```

`origin auth login` also installs Origin's git credential helper so `git push` / `git pull` against Origin remotes work.

---

## Proton

`pass-cli` and `proton-drive` are installed by bootstrap. Desktop apps (Pass, Drive, Mail, VPN) stay commented in the Brewfile — uncomment if you want them provisioned automatically.

```bash
pass-cli login
pass-cli run -- my-command          # inject secrets as env vars
# Secret references: pass://vault/item/field
pass-cli ssh-agent                  # use SSH keys stored in Proton Pass

proton-drive auth login             # session stored in macOS Keychain
proton-drive filesystem list /
```

`pass-cli` is installed with Proton's native installer so `pass-cli update` works. Do not also `brew install proton-pass-cli`.

The Proton Drive CLI is a versioned binary (`PROTON_DRIVE_CLI_VERSION` in `scripts/bootstrap.sh`). Bump that variable when Proton publishes a new release at [proton.me/download/drive/cli](https://proton.me/download/drive/cli/index.html).

---

## React Native Setup

For React Native development targeting both iOS and Android:

### iOS Setup
Ensure you've installed **Xcode** (full app) from the App Store and opened it once. The Xcode Command Line Tools are installed during bootstrap.

### Android Setup

1. **Install Android SDK**: Open **Android Studio** → **SDK Manager** and install:
   - Latest **Android SDK** + **Platform Tools**
   - **Android Emulator** (if needed)

2. **Set Gradle JDK**: Ensure **Gradle JDK = 17** (Android Studio → Preferences → Build Tools → Gradle)

3. **Add Android tools to PATH**: React Native CLI needs `ANDROID_HOME` and Android tools on your PATH. Source the helper script:

```zsh
# Add to ~/.zshrc (or ~/.zprofile for login shells)
[ -f "$HOME/mac-dev-setup/scripts/android-env.zsh" ] && source "$HOME/mac-dev-setup/scripts/android-env.zsh"
```

> Note: Some setups only load `~/.zprofile` in login shells and `~/.zshrc` in interactive shells. Add the line to the file(s) your environment actually loads.

---

## Git, GitHub, and GPG

`gh` is the GitHub CLI (Homebrew). Sign in after bootstrap:

```bash
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global commit.gpgsign true
git config --global gpg.program $(which gpg)

gh auth login
gh auth setup-git
```

If you use 1Password’s SSH/GPG agent, follow 1Password docs and skip `gpg` key generation here. A `1password` / `1password-cli` pair is commented in the Brewfile.

Copy `.gitconfig.sample` to `~/.gitconfig` if you are starting from scratch. `scripts/setup-machine.sh` then sets `user.name` and per-folder commit emails for you (see [Machine setup](#machine-setup)); with that model the global `user.email` stays unset on purpose.

`commit.gpgsign = true` is fine on a laptop. On a headless machine it makes every commit hang waiting for a passphrase unless the signing key has none; `setup-machine.sh` warns when it is on and, with `--server`, offers to turn it off.

---

## Machine setup

`scripts/bootstrap.sh` installs the toolchain. `scripts/setup-machine.sh` does the per-machine layer that otherwise gets done by hand on every new Mac: SSH keys and host aliases, git identity with per-folder commit emails, PATH ordering that survives macOS `path_helper`, pinned mise global tools, and Claude Code deny rules. Two opt-in profiles add the rest: `--server` for the unattended agent host (a mode-600 environment file for secrets, plus a report) and `--client` for a travel laptop (tmux, mosh, gh, Obsidian, Slack, Claude, and a manual-steps list).

Everything machine-specific lives in **`~/.config/mac-dev-setup/machine.conf`** (mode 600, never committed). The repo ships only `configs/machine.conf.example` with placeholders. On first run the script creates the real file interactively; or copy the example there and edit it.

```bash
./scripts/setup-machine.sh              # the steps every machine gets: ssh git path mise claude
./scripts/setup-machine.sh --server     # + the secrets env file, + agent-server report (report only)
./scripts/setup-machine.sh --client     # + tmux, mosh, gh, Obsidian, Slack, Claude, + manual steps
./scripts/setup-machine.sh --only ssh   # one step: ssh | git | path | mise | claude | env | client
./scripts/setup-machine.sh --only git,path
./scripts/setup-machine.sh --help
```

`--server` and `--client` are opposite profiles and cannot be combined: a client machine holds no agent credentials, so it never gets the env file.

Every step prints what it is about to do, skips what is already done, and is safe to re-run. Anything optional (`ssh-copy-id`, unsetting a global email, turning gpgsign off) is a yes/no prompt, and a non-interactive run (no TTY) answers no and says what it skipped. The script never prints a secret value, never writes one to a tracked file, and never changes a security setting.

### What each step does

| Step | What it does | Touches |
| --- | --- | --- |
| `ssh` | Generates `~/.ssh/id_ed25519` if absent (comment you supply, never overwrites). Writes one `Host` block per entry in `SSH_HOSTS` (alias, `HostName`, `User`, `IdentityFile`, `IdentitiesOnly yes`), editing in place by alias so re-runs update instead of duplicate; blocks it did not write are left byte for byte. Offers `ssh-copy-id` per host and prints `ssh -G <alias>` for verification. | `~/.ssh/config` |
| `git` | Sets `user.name` globally. Leaves global `user.email` unset (offers to unset it if set) and writes one `includeIf "gitdir:<folder>/"` per entry in `GIT_FOLDER_EMAILS`, each pointing at a small gitconfig under `~/.config/mac-dev-setup/git/` that sets that folder's `user.email`. Warns if `commit.gpgsign` is on. | `~/.gitconfig`, `~/.config/mac-dev-setup/git/*.gitconfig` |
| `path` | Creates `~/bin` and puts it and mise's shims ahead of `/usr/bin` in `~/.zprofile`. | `~/.zprofile` |
| `mise` | Pins every `tool@version` in `MISE_TOOLS` with `mise use -g`, so a new machine matches the others instead of drifting to latest. | `~/.config/mise/config.toml` |
| `claude` | Merges `claude/deny-rules.json` into `~/.claude/settings.json` and sets `inputNeededNotifEnabled` to `true`. See "Claude Code deny rules" below. Needs `jq`. | `~/.claude/settings.json` (a timestamped `.bak-*` copy is kept whenever it changes) |
| `env` | **`--server` only.** Creates `~/.config/claude/env` (mode 600) with an empty `export NAME=` line per name in `ENV_VARS`, adds missing names on re-run without touching existing values, and sources it from `~/.zshrc`. Without `--server` it prints that it skipped. | `~/.config/claude/env`, `~/.zshrc` |
| `client` | **`--client` only.** `brew bundle --no-upgrade` on `configs/Brewfile.client`, then prints the manual steps Homebrew cannot do. See "Client profile". | Homebrew |
| `--server` | Reports `pmset` sleep/autorestart, FileVault vs automatic login, and the application firewall, with what a 24/7 machine wants. Changes nothing. | nothing |

### Claude Code deny rules

`claude/deny-rules.json` is the `permissions.deny` block from the agent server's `~/.claude/settings.json`, and nothing else from that file. It keeps an agent away from credential files (`~/.ssh`, `~/.config/claude/env`, and similar), from process listing (`ps`, `pgrep`, `top`, `lsof`, `launchctl procinfo`), and from shell tracing (`bash -x`, `set -x`), in the bare form and in the usual wrappers (`sudo`, `env`, `xargs`, `sh -c`, …).

The `claude` step **unions** those rules into the machine's own: rules already in the file stay where they are, missing ones are appended, and every other key (`allow`, `hooks`, `env`, plugins, model, …) is carried through unchanged. It refuses, and changes nothing, if `settings.json` is not valid JSON or `permissions.deny` is not a list. The script also refuses to apply a fragment that has anything but `permissions.deny` in it or anything shaped like a credential, because this file is public.

Because the rules are broad, on a machine where you use Claude Code they also stop Claude from running any command that mentions `~/.ssh` or `~/.config/claude`. That is the point on an agent host; on a laptop you drive by hand, review the list once.

To refresh the fragment from the server (without printing the rest of its settings):

```bash
scp <agent-host>:.claude/settings.json "$TMPDIR/server-settings.json"
jq '{permissions:{deny:.permissions.deny}}' "$TMPDIR/server-settings.json" > claude/deny-rules.json
rm "$TMPDIR/server-settings.json"
git diff claude/deny-rules.json    # read every added line before committing
```

### Client profile

`./scripts/setup-machine.sh --client` is for the laptop you travel with. Homebrew installs what it can (`configs/Brewfile.client`): **tmux**, **mosh**, **gh**, **Obsidian**, **Slack**, and the **Claude** desktop app. It uses `--no-upgrade`, so a re-run installs only what is missing and never upgrades anything. Then it lists what only you can do:

- **WireGuard client**: Mac App Store only (there is no Homebrew cask; the `wireguard-tools` formula is the CLI, not the app that imports Firewalla profiles). Install it, import the profile from the Firewalla app, and test it from a phone hotspot.
- Sign in to Slack, Obsidian and Claude once, and point Obsidian at the vault.
- `mosh` needs `mosh-server` on each host and UDP 60000–61000 reachable over the VPN. If mosh reports `mosh-server: command not found`, the host's non-login PATH lacks Homebrew; pass `--server=/opt/homebrew/bin/mosh-server`.

If a client has an old `~/.config/claude/env`, the step warns about it and leaves it alone.

### Travel-readiness checklist

Do this on the client, at home, the day before you leave. Every box must be ticked on the network you will actually travel on (a phone hotspot), not on home Wi-Fi.

- [ ] **WireGuard profile imported from the Firewalla app and tested from a phone hotspot.** Turn Wi-Fi off on the laptop, join the phone's hotspot, bring the tunnel up. If it connects only on home Wi-Fi it proves nothing.
- [ ] **`ssh` to each host works over the tunnel.** One command per alias in `machine.conf` (two is the documented shape): `ssh -o ConnectTimeout=5 <alias> true && echo ok`. It must not ask for a password; if it does, run `ssh-copy-id <alias>` while still at home.
- [ ] **The agent-server session is visible in the Claude app.** Open the Claude app on the laptop and on the phone and confirm the server's session is listed and answers.
- [ ] **The status page loads over the VPN, with its token from the password manager.** Open it through the tunnel and paste the token from the password manager. The token is never in this repo, `machine.conf`, or the env file.

If a box will not tick, fix it now. Things to check first: that the WireGuard profile on the client is the one the Firewalla app currently shows, that the host still has the address pinned in `machine.conf` (the DHCP reservation), and that Remote Login is still on.

### Why one SSH key but several commit emails

One SSH key proves *who is pushing*; GitHub and the other forges accept it for every account it is added to. Commit *attribution* comes from the email in the commit, not the key. So a second key per employer buys nothing, while a wrong `user.email` quietly attributes work-repo commits to the wrong identity. The `includeIf "gitdir:…/"` blocks make the email follow the folder: everything under `~/Work/` gets the work address, everything under `~/Projects/` the personal one, and a commit anywhere else fails loudly with "Please tell me who you are" instead of guessing.

### Why PATH goes in `~/.zprofile`, not `~/.zshrc`

macOS runs `/usr/libexec/path_helper` from `/etc/zprofile` for every login shell, and it rebuilds `PATH` with `/usr/bin` first regardless of what was passed in. Non-interactive login shells (launchd jobs, `ssh host cmd`, cron) never read `~/.zshrc`, so a `PATH` set only there, or only in a launchd job's environment, loses and you silently get the system Ruby and Python instead of mise's. `~/.zprofile` runs after `path_helper`, so what it sets wins. This cost a day of debugging on the agent server; the comment in the block says so.

### Secrets: `pass-cli` first, env file second

`pass-cli` is already the secret-handling convention in this repo and is the preferred route whenever a command can be wrapped: `pass-cli run -- claude` injects secrets as environment variables for that process and nothing touches disk. The env file is for what cannot be wrapped (launchd agents, plain shells, tools that read the environment at login). It holds names only when written; you fill the values from Proton Pass, and the password manager remains the canonical copy. Both are documented so a machine can use either; the script reminds you of this and prints the `pass-cli run` form when `pass-cli` is installed.

### By hand, afterwards

- On a `--server` machine, fill `~/.config/claude/env` from your password manager (the script wrote names only). A client has no env file.
- Enable **Remote Login** on each host (System Settings → General → Sharing), then run `ssh-copy-id <alias>` from this machine, or answer yes when the script offers.
- Give each host a **DHCP reservation** on the router so the address pinned in `machine.conf` stays pinned.
- Open a new terminal so the `~/.zprofile` and `~/.zshrc` changes apply.
- On an unattended machine, read the `--server` report and decide FileVault vs automatic login yourself.

---

## Per‑project setup with Mise

Each project can pin tool versions and env in `.mise.toml`. Example configuration:

```toml
[tools]
ruby = "3.3.4"
node = "lts"
bun = "latest"
java = "17"

[env]
RAILS_ENV = "development"

[tasks]
setup = "bundle install && pnpm install"
dev   = "bin/dev"
```

When you `cd` into a repo with `.mise.toml`, Mise activates the pinned versions automatically.

---

## New machine in 20 minutes

Order matters: bootstrap first (it installs `mise`, `gh`, `pass-cli`), sign-ins second, then the machine layer.

1. `xcode-select --install`
2. `git clone` this repo, `cd` into it.
3. `./scripts/bootstrap.sh` — Homebrew, Brewfile, shell hooks, native CLIs. Answer the Dock and Hot Corners prompts (default yes). ~10 min, mostly downloads.
4. New terminal (`exec zsh`).
5. Sign in: `gh auth login && gh auth setup-git`, `origin auth login`, `pass-cli login`, `proton-drive auth login`.
6. `./scripts/setup-machine.sh` — answer the `machine.conf` prompts (git name, hosts, folder emails, mise pins, env var names). It generates the SSH key, writes the host aliases, includeIf blocks, PATH block, pins mise tools, and merges the Claude Code deny rules. Add `--server` on a machine that runs unattended (also creates the env file) or `--client` on a travel laptop (installs the client apps).
7. By hand: on a server, fill `~/.config/claude/env`; enable Remote Login on the hosts and `ssh-copy-id` them, add DHCP reservations on the router. On a client, finish the manual steps the script printed and tick the travel-readiness checklist.
8. New terminal again, then `./scripts/doctor.sh` and the same `./scripts/setup-machine.sh` command once more: the second run should report everything already done.
9. `brew services start postgresql@16 && brew services start redis` if this machine needs them.

---

## Troubleshooting

- **`setup-machine.sh` says no machine.conf**: it only creates the file from a terminal. Run it interactively once, or copy `configs/machine.conf.example` to `~/.config/mac-dev-setup/machine.conf` and `chmod 600` it.
- **`claude -p` (or a script that calls it) says "Invalid API key" though you are logged in**: an exported `ANTHROPIC_API_KEY`, for example from `~/.config/claude/env`, takes precedence over the login. Run it as `env -u ANTHROPIC_API_KEY claude -p …`, or remove the variable from the shell. A client machine should not export it at all.
- **`setup-machine.sh` says the `claude` step stopped**: `~/.claude/settings.json` is not valid JSON, or `permissions.deny` is not a list. The script changed nothing; fix the file by hand and re-run `--only claude`. Every change it does make leaves a `settings.json.bak-<timestamp>` beside it.
- **Wrong Ruby/Python in a launchd job or `ssh host cmd`**: run `./scripts/setup-machine.sh --only path`, then open a new login shell. See "Why PATH goes in `~/.zprofile`".
- **`git commit` says "Please tell me who you are"**: the folder is not in `GIT_FOLDER_EMAILS`. That is the per-folder email model working; add the folder to `machine.conf` and re-run `--only git`.
- **Ruby compile fails**: Ensure Brew deps (`openssl@3`, `readline`, `libyaml`, `zlib`, `gmp`) are installed. Re-run `mise use -g ruby@latest`.
- **React Native Android Gradle errors**: Confirm JDK 17 is set in Android Studio (Preferences → Build Tools → Gradle).
- **Docker performance**: Try **OrbStack** first; if you prefer FOSS, **Colima** is solid (`brew install colima`).
- **Bun installation**: Bun is installed via `mise use -g bun@latest`, not Homebrew. This is the recommended way to install bun.
- **Mise config not trusted**: The bootstrap script should handle this automatically. If you see trust errors, run `mise trust` in the repo directory.
- **`command not found: corepack` or tools not available**: After running bootstrap, start a new terminal session (or run `exec zsh`) so that mise and other tools are activated. The bootstrap script adds hooks to `~/.zshrc`, but they only load in new shells.
- **Homebrew not found in terminal**: The setup adds Homebrew to both `~/.zprofile` and `~/.zshrc` for compatibility. If `brew` isn't available, try starting a new terminal or running `eval "$(/opt/homebrew/bin/brew shellenv)"` manually.
- **`command not found: origin` / `pass-cli` / `claude`**: Ensure `~/.local/bin` is on your PATH (`export PATH="$HOME/.local/bin:$PATH"`).
- **`command not found: grok`**: Ensure `~/.grok/bin` is on your PATH. The Grok installer usually adds this itself.
- **`agent` opens Grok instead of Cursor**: That is expected. Use `cursor-agent` for Cursor's terminal agent.
- **Dock still full of default apps**: Re-run bootstrap and answer `y` at the Dock prompt, or run:
  `defaults write com.apple.dock persistent-apps -array && defaults write com.apple.dock recent-apps -array && defaults write com.apple.dock show-recents -bool false && killall Dock`
  That removes pinned app icons (left of the divider) and turns off suggested/recent apps. Open apps still show while running; Downloads and Trash stay.
- **Hot Corners not set**: Re-run bootstrap and answer `y` at the Hot Corners prompt, or run:
  `defaults write com.apple.dock wvous-tl-corner -int 5 && defaults write com.apple.dock wvous-tl-modifier -int 0 && defaults write com.apple.dock wvous-tr-corner -int 4 && defaults write com.apple.dock wvous-tr-modifier -int 0 && defaults write com.apple.dock wvous-br-corner -int 2 && defaults write com.apple.dock wvous-br-modifier -int 0 && killall Dock`
  Top-left Screen Saver, top-right Desktop, bottom-right Mission Control. Bottom-left is left alone.

---

## License

MIT
