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

Copy `.gitconfig.sample` to `~/.gitconfig` and fill in your name/email if you are starting from scratch.

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
3. Run `./scripts/bootstrap.sh` (shell hooks, native CLIs, and `brew bundle`)
4. Sign in: `gh auth login && gh auth setup-git`, `origin auth login`, `pass-cli login`, `proton-drive auth login`
5. Provision runtimes: `mise use -g ruby@latest && mise use -g node@lts && mise use -g bun@latest && corepack enable`
6. Start services: `brew services start postgresql@16 && brew services start redis`
7. Optional: `./scripts/doctor.sh` to confirm everything landed

---

## Troubleshooting

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

---

## License

MIT
