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
# Note: Bootstrap automatically sets up shell hooks (mise, starship, fzf) and trusts the mise config
# After bootstrap, start a new terminal session (or run `exec zsh`) for tools to be available

# 2) Install apps & CLIs with Brewfile
brew bundle --file=./Brewfile

# 3) Provision runtimes (user-global defaults)
mise use -g ruby@latest
mise use -g node@lts
mise use -g bun@latest
corepack enable   # pnpm/yarn shims

# 4) Start services
brew services start postgresql@16
brew services start redis
```

> Optional: Install **OrbStack** (via cask in `Brewfile`) and use it for Docker; or use **Colima** (installed via brew).

---

## What you get

- **Mise**: one tool to manage Ruby, Node, Java, etc. Per-project versions via `.mise.toml`.
- **Ruby** toolchain + common compile deps for Apple Silicon.
- **Node LTS** + **pnpm** (via Corepack) and **Bun** (via Mise) for fast dev/test.
- Databases: **PostgreSQL 16**, **Redis**.
- React Native helpers: **watchman**, **cocoapods**; **Android Studio** via cask.
- Container runtime: **OrbStack** (preferred) or **Colima**.
- CLIs: `ripgrep`, `fd`, `fzf`, `zoxide`, `eza`, `jq`, `yq`, `tree`.
- Terminal: **Ghostty** (GPU-accelerated) with **MesloLGS Nerd Font Mono**.
- Prompt: **Starship** with sensible defaults (`configs/starship.toml`).
- Zsh plugins: **zsh-autosuggestions**, **zsh-syntax-highlighting**.
- Shell aliases: `ls`/`ll`/`la` → **eza** with icons; smart `cd` via **zoxide** (`z`).
- AI: **Claude** desktop app; **Claude Code** CLI (auto-updating native installer).
- Editors: **Cursor** (with `cursor` shell command), **VS Code**, **Zed**.
- DB GUI: **TablePlus** (and optional Postico).

---

## Terminal Compatibility

This setup works across **Ghostty**, **Terminal**, **iTerm2**, and **Warp** on macOS. The bootstrap script configures:

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

### Warp-Specific Notes

If using **Warp**, you may want to:
1. Enable custom prompt: **Settings** → **Features** → **Session** → Enable "Honor user's custom prompt"
2. The Nerd Font (`font-meslo-lg-nerd-font`) is installed automatically via the Brewfile.

All other terminal apps work out of the box -- just start a new terminal session after running the bootstrap script.

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

## Git & GPG (optional)

```bash
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global commit.gpgsign true
git config --global gpg.program $(which gpg)

# Authenticate with GitHub
gh auth login
```

If you use 1Password’s SSH/GPG agent, follow 1Password docs and skip `gpg` key generation here.

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

## Reinstalling on another Mac

1. Install Xcode CLT: `xcode-select --install`
2. Clone this repo.
3. Run `./scripts/bootstrap.sh` (automatically sets up shell hooks and trusts mise config)
4. `brew bundle --file=./Brewfile`
5. Provision runtimes: `mise use -g ruby@latest && mise use -g node@lts && mise use -g bun@latest && corepack enable`
6. Start services: `brew services start postgresql@16 && brew services start redis`

---

## Troubleshooting

- **Ruby compile fails**: Ensure Brew deps (`openssl@3`, `readline`, `libyaml`, `zlib`, `gmp`) are installed. Re-run `mise use -g ruby@latest`.
- **React Native Android Gradle errors**: Confirm JDK 17 is set in Android Studio (Preferences → Build Tools → Gradle).
- **Docker performance**: Try **OrbStack** first; if you prefer FOSS, **Colima** is solid (`brew install colima`).
- **Bun installation**: Bun is installed via `mise use -g bun@latest`, not Homebrew. This is the recommended way to install bun.
- **Mise config not trusted**: The bootstrap script should handle this automatically. If you see trust errors, run `mise trust` in the repo directory.
- **`command not found: corepack` or tools not available**: After running bootstrap, start a new terminal session (or run `exec zsh`) so that mise and other tools are activated. The bootstrap script adds hooks to `~/.zshrc`, but they only load in new shells.
- **Homebrew not found in terminal**: The setup adds Homebrew to both `~/.zprofile` and `~/.zshrc` for compatibility. If `brew` isn't available, try starting a new terminal or running `eval "$(/opt/homebrew/bin/brew shellenv)"` manually.

---

## License

MIT
