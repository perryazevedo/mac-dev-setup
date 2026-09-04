#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Proton Drive CLI has no unversioned latest URL; bump this when Proton ships a new binary.
PROTON_DRIVE_CLI_VERSION="0.8.0"

has_cmd() {
  command -v "$1" >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/$1" ]] || [[ -x "$HOME/.grok/bin/$1" ]]
}

# Ensure Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo ">> If prompted, finish the Xcode CLT install and re-run this script."
fi

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Ensure Homebrew is available in .zshrc (for non-login shells like iTerm)
# This ensures brew works in all terminal contexts
if ! grep -q 'brew shellenv' ~/.zshrc 2>/dev/null; then
  echo '' >> ~/.zshrc
  echo '# Homebrew (ensures brew is available in non-login shells)' >> ~/.zshrc
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
fi

# Core packages needed early
brew update

# Install mise + common shell tools fast (rest via Brewfile)
# Install a minimal set early so the rest of the setup is comfortable.
# Note: These also appear in the Brewfile; duplication is intentional for bootstrapping speed.
brew install mise git gh ripgrep fd fzf zoxide eza jq yq tree gnupg pinentry-mac starship zsh-autosuggestions zsh-syntax-highlighting

# One-time shell hooks (idempotent)
# Ensure .zshrc exists
[ -f ~/.zshrc ] || touch ~/.zshrc

# Mise (must come before starship)
grep -q 'mise activate zsh' ~/.zshrc 2>/dev/null || echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# Starship prompt
grep -q 'starship init zsh' ~/.zshrc 2>/dev/null || echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# Zoxide (smart cd)
grep -q 'zoxide init zsh' ~/.zshrc 2>/dev/null || echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc

# eza aliases (modern ls)
grep -q 'alias ls="eza' ~/.zshrc 2>/dev/null || {
  echo '' >> ~/.zshrc
  echo '# eza aliases' >> ~/.zshrc
  echo 'alias ls="eza --icons"' >> ~/.zshrc
  echo 'alias ll="eza -l --icons"' >> ~/.zshrc
  echo 'alias la="eza -la --icons"' >> ~/.zshrc
}

# Zsh plugins (autosuggestions & syntax highlighting)
grep -q 'zsh-autosuggestions.zsh' ~/.zshrc 2>/dev/null || \
  echo '[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"' >> ~/.zshrc
grep -q 'zsh-syntax-highlighting.zsh' ~/.zshrc 2>/dev/null || \
  echo '[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"' >> ~/.zshrc

# Ghostty SSH TERM fix (some servers don't recognise xterm-ghostty)
if ! grep -q 'Fix TERM for SSH sessions' ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'TERMFIX'

# Fix TERM for SSH sessions under Ghostty
if [[ -n "$SSH_CONNECTION" ]]; then
  export TERM=xterm-256color
fi
TERMFIX
fi

# fzf key-bindings/completion
"$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc || echo "fzf optional installer skipped (non-fatal)"

# Cursor editor shim (open files/folders with `cursor .`)
# brew cask "cursor" also links this; keep the app path as a fallback.
grep -q 'Cursor.app/Contents/Resources/app/bin' ~/.zshrc 2>/dev/null || \
  echo 'export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"' >> ~/.zshrc

# ~/.local/bin (Claude Code, Origin, pass-cli, proton-drive, and other user-local binaries)
mkdir -p "$HOME/.local/bin"
grep -q 'HOME/\.local/bin' ~/.zshrc 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"

# Default editor for git commit etc.
grep -q '^export EDITOR=' ~/.zshrc 2>/dev/null || \
  echo 'export EDITOR="cursor --wait"' >> ~/.zshrc

# --- Native auto-updating CLIs ---

# Claude Code CLI
if ! has_cmd claude; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Grok Build CLI
if ! has_cmd grok; then
  curl -fsSL https://x.ai/cli/install.sh | bash
fi
# The Grok installer usually appends its own PATH/completions block.
# Only add ~/.grok/bin if that block is missing.
if ! grep -q '\.grok/bin' ~/.zshrc 2>/dev/null; then
  echo 'export PATH="$HOME/.grok/bin:$PATH"' >> ~/.zshrc
fi
export PATH="$HOME/.grok/bin:$PATH"

# Cursor Origin CLI (git forge; separate from cursor / cursor-agent)
if ! has_cmd origin; then
  curl -fsSL https://downloads.cursor.com/origin/install.sh | sh
fi

# Proton Pass CLI
if ! has_cmd pass-cli; then
  curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
fi

# Proton Drive CLI (versioned binary; skip without failing bootstrap if the URL 404s)
if ! has_cmd proton-drive; then
  if curl -fsSL "https://proton.me/download/drive/cli/${PROTON_DRIVE_CLI_VERSION}/darwin-arm64/proton-drive" \
      -o "$HOME/.local/bin/proton-drive"; then
    chmod +x "$HOME/.local/bin/proton-drive"
    echo ">> Installed Proton Drive CLI ${PROTON_DRIVE_CLI_VERSION} → ~/.local/bin/proton-drive"
  else
    echo ">> Warning: Proton Drive CLI download failed (version ${PROTON_DRIVE_CLI_VERSION}); skipping"
    rm -f "$HOME/.local/bin/proton-drive"
  fi
fi

# Case-insensitive tab completion
grep -q 'NO_CASE_GLOB' ~/.zshrc 2>/dev/null || {
  echo '' >> ~/.zshrc
  echo '# Case-insensitive completion' >> ~/.zshrc
  echo 'setopt NO_CASE_GLOB' >> ~/.zshrc
  echo 'autoload -Uz compinit && compinit' >> ~/.zshrc
  echo "zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-zA-Z}'" >> ~/.zshrc
}

# History search with arrow keys
grep -q 'history-beginning-search-backward' ~/.zshrc 2>/dev/null || {
  echo '' >> ~/.zshrc
  echo '# History search with arrow keys' >> ~/.zshrc
  echo "bindkey '^[[A' history-beginning-search-backward" >> ~/.zshrc
  echo "bindkey '^[[B' history-beginning-search-forward" >> ~/.zshrc
}

# Trust mise config in this repo (if it exists)
if [ -f "$REPO_ROOT/.mise.toml" ] && command -v mise >/dev/null 2>&1; then
  (cd "$REPO_ROOT" && mise trust . 2>/dev/null && echo ">> Trusted mise config file") \
    || echo ">> Note: Run 'mise trust' in the repo directory if needed"
fi

# --- Config files (copy from repo if not already present) ---

# Ghostty config
if [ ! -f ~/.config/ghostty/config ]; then
  mkdir -p ~/.config/ghostty
  cp "$REPO_ROOT/configs/ghostty/config" ~/.config/ghostty/config
  echo ">> Installed Ghostty config → ~/.config/ghostty/config"
else
  echo ">> Ghostty config already exists, skipping"
fi

# Starship config
if [ ! -f ~/.config/starship.toml ]; then
  mkdir -p ~/.config
  cp "$REPO_ROOT/configs/starship.toml" ~/.config/starship.toml
  echo ">> Installed Starship config → ~/.config/starship.toml"
else
  echo ">> Starship config already exists, skipping"
fi

# Remaining formulae and casks
echo ">> Installing Brewfile packages (idempotent)…"
brew bundle --file="$REPO_ROOT/Brewfile"

# Optional macOS Dock prefs. Restart Dock once if anything changed.
# Hot corner values: 2=Mission Control, 4=Desktop, 5=Start Screen Saver. Modifier 0 = none.
dock_restart=0
if [[ -t 0 ]]; then
  echo
  echo ">> New Macs pin Safari, Mail, Messages, and other apps on the left side of the Dock,"
  echo ">> and may show suggested/recent apps even when they are not open."
  read -r -p ">> Clear pinned Dock apps and hide recents? (keeps Downloads and Trash) [Y/n] " dock_reply || dock_reply=""
  case "$dock_reply" in
    [nN]|[nN][oO])
      echo ">> Leaving Dock as-is"
      ;;
    *)
      defaults write com.apple.dock persistent-apps -array
      defaults write com.apple.dock recent-apps -array
      defaults write com.apple.dock show-recents -bool false
      dock_restart=1
      echo ">> Dock app shortcuts cleared; suggested/recent apps hidden"
      ;;
  esac

  echo
  echo ">> Hot Corners: top-left Screen Saver, top-right Desktop, bottom-right Mission Control."
  echo ">> Bottom-left is left unchanged. Open apps still appear in the Dock while running."
  read -r -p ">> Apply those Hot Corners? [Y/n] " corners_reply || corners_reply=""
  case "$corners_reply" in
    [nN]|[nN][oO])
      echo ">> Leaving Hot Corners as-is"
      ;;
    *)
      defaults write com.apple.dock wvous-tl-corner -int 5
      defaults write com.apple.dock wvous-tl-modifier -int 0
      defaults write com.apple.dock wvous-tr-corner -int 4
      defaults write com.apple.dock wvous-tr-modifier -int 0
      defaults write com.apple.dock wvous-br-corner -int 2
      defaults write com.apple.dock wvous-br-modifier -int 0
      dock_restart=1
      echo ">> Hot Corners set"
      ;;
  esac
fi
if [[ "$dock_restart" -eq 1 ]]; then
  killall Dock 2>/dev/null || true
fi

echo ">> Bootstrap complete."
echo "   Start a new terminal (or run \`exec zsh\`), then:"
echo "   1) gh auth login && gh auth setup-git"
echo "   2) origin auth login"
echo "   3) pass-cli login"
echo "   4) proton-drive auth login"
echo "   5) claude / grok / codex  (browser login on first launch)"
echo "   6) mise use -g ruby@latest"
echo "   7) mise use -g node@lts && mise use -g bun@latest && corepack enable"
echo "   8) brew services start postgresql@16 && brew services start redis"
echo "   Drift check later: ./scripts/doctor.sh"

# React Native: Add Android tools to PATH
# After installing Android Studio and SDK, add this to your ~/.zshrc or ~/.zprofile:
# [ -f "$HOME/mac-dev-setup/scripts/android-env.zsh" ] && source "$HOME/mac-dev-setup/scripts/android-env.zsh"
# See README "React Native Setup" section for full instructions.
