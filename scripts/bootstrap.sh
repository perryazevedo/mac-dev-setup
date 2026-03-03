#!/usr/bin/env bash
set -euo pipefail

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

# Ensure Homebrew is available in .zshrc (for non-login shells like iTerm/Warp)
# This ensures brew works in all terminal contexts
if ! grep -q 'brew shellenv' ~/.zshrc 2>/dev/null; then
  echo '' >> ~/.zshrc
  echo '# Homebrew (ensures brew is available in non-login shells)' >> ~/.zshrc
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
fi

# Core packages needed early
brew update

# Install mise + common shells tools fast (rest via Brewfile)
# Install a minimal set early so the rest of the setup is comfortable.
# Note: These also appear in the Brewfile; duplication is intentional for bootstrapping speed.
brew install mise git ripgrep fd fzf zoxide eza jq yq tree gnupg pinentry-mac starship

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
  echo 'source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
grep -q 'zsh-syntax-highlighting.zsh' ~/.zshrc 2>/dev/null || \
  echo 'source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc

# Ghostty SSH TERM fix (some servers don't recognise xterm-ghostty)
if ! grep -q 'SSH_CONNECTION.*TERM=xterm-256color' ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'TERMFIX'

# Fix TERM for SSH sessions under Ghostty
if [[ -n "$SSH_CONNECTION" ]]; then
  export TERM=xterm-256color
fi
TERMFIX
fi

# fzf key-bindings/completion
"$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc || echo "fzf optional installer skipped (non-fatal)"

# Trust mise config in this repo (if it exists)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$REPO_ROOT/.mise.toml" ] && command -v mise >/dev/null 2>&1; then
  cd "$REPO_ROOT" && mise trust . 2>/dev/null && echo ">> Trusted mise config file" || echo ">> Note: Run 'mise trust' in the repo directory if needed"
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

echo ">> Bootstrap base complete. Next steps:"
echo "   1) brew bundle --file=./Brewfile"
echo "   2) mise use -g ruby@latest"
echo "   3) mise use -g node@lts && mise use -g bun@latest && corepack enable"
echo "   4) brew services start postgresql@16 && brew services start redis"


# React Native: Add Android tools to PATH
# After installing Android Studio and SDK, add this to your ~/.zshrc or ~/.zprofile:
# [ -f "$HOME/mac-dev-setup/scripts/android-env.zsh" ] && source "$HOME/mac-dev-setup/scripts/android-env.zsh"
# See README "React Native Setup" section for full instructions.
