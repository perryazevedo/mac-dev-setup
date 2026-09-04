#!/usr/bin/env bash
set -u

missing=0

ok() { printf 'ok    %s\n' "$1"; }
miss() {
  printf 'MISS  %s\n' "$1"
  missing=$((missing + 1))
}

check_cmd() {
  local name="$1"
  local hint="${2:-}"
  if command -v "$name" >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/$name" ]] || [[ -x "$HOME/.grok/bin/$name" ]]; then
    local resolved
    resolved="$(command -v "$name" 2>/dev/null || true)"
    [[ -n "$resolved" ]] || resolved="$HOME/.local/bin/$name"
    ok "$name  ($resolved)"
  else
    if [[ -n "$hint" ]]; then
      miss "$name  → $hint"
    else
      miss "$name"
    fi
  fi
}

check_cask() {
  local name="$1"
  if command -v brew >/dev/null 2>&1 && brew list --cask "$name" >/dev/null 2>&1; then
    ok "cask $name"
  else
    miss "cask $name  → brew install --cask $name"
  fi
}

path_has() {
  local dir="$1"
  case ":$PATH:" in
    *":$dir:"*) ok "PATH contains $dir" ;;
    *) miss "PATH missing $dir  → add export PATH=\"$dir:\$PATH\" to ~/.zshrc" ;;
  esac
}

echo "== mac-dev-setup doctor =="
echo

echo "-- CLIs --"
check_cmd brew
check_cmd git
check_cmd gh            "brew install gh"
check_cmd mise          "brew install mise"
check_cmd claude        "curl -fsSL https://claude.ai/install.sh | bash"
check_cmd grok          "curl -fsSL https://x.ai/cli/install.sh | bash"
check_cmd origin        "curl -fsSL https://downloads.cursor.com/origin/install.sh | sh"
check_cmd cursor        "brew install --cask cursor"
check_cmd cursor-agent  "brew install --cask cursor-cli"
check_cmd codex         "brew install --cask codex"
check_cmd pass-cli      "curl -fsSL https://proton.me/download/pass-cli/install.sh | bash"
check_cmd proton-drive  "see README Proton Drive CLI (versioned binary)"

echo
echo "-- Casks --"
check_cask cursor
check_cask claude
check_cask grok-bot
check_cask linear
check_cask orbstack
check_cask ghostty

echo
echo "-- PATH --"
path_has "$HOME/.local/bin"
path_has "$HOME/.grok/bin"

echo
if [[ "$missing" -eq 0 ]]; then
  echo "All checks passed."
  exit 0
fi

echo "$missing item(s) missing. Re-run ./scripts/bootstrap.sh or use the hints above."
exit 1
