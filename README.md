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

Copy `.gitconfig.sample` to `~/.gitconfig` if you are starting from scratch. `scripts/setup-machine.sh` then sets `user.name` and per-folder commit emails for you (see [Machine setup](#machine-setup)); with that model the global `user.email` is an optional default (`GIT_EMAIL`) that the per-folder entries override.

`commit.gpgsign = true` is fine on a laptop. On a headless machine it makes every commit hang waiting for a passphrase unless the signing key has none; `setup-machine.sh` warns when it is on and, with `--server`, offers to turn it off.

---

## Machine setup

`scripts/bootstrap.sh` installs the toolchain. `scripts/setup-machine.sh` does the per-machine layer that otherwise gets done by hand on every new Mac: SSH keys and host aliases, git identity with per-folder commit emails, PATH ordering that survives macOS `path_helper`, pinned mise global tools, and a mode-600 environment file for secrets.

Everything machine-specific lives in **`~/.config/mac-dev-setup/machine.conf`** (mode 600, never committed). The repo ships only `configs/machine.conf.example` with placeholders. On first run the script creates the real file interactively; or copy the example there and edit it.

```bash
./scripts/setup-machine.sh              # all steps, in order
./scripts/setup-machine.sh --only ssh   # one step: ssh | git | path | mise | env
./scripts/setup-machine.sh --only git,path
./scripts/setup-machine.sh --server     # also report agent-server settings (report only)
./scripts/setup-machine.sh --help
```

Every step prints what it is about to do, skips what is already done, and is safe to re-run. Anything optional (`ssh-copy-id`, unsetting a global email, turning gpgsign off) is a yes/no prompt, and a non-interactive run (no TTY) answers no and says what it skipped. The script never prints a secret value, never writes one to a tracked file, and never changes a security setting.

### What each step does

| Step | What it does | Touches |
| --- | --- | --- |
| `ssh` | Generates `~/.ssh/id_ed25519` if absent (comment you supply, never overwrites). Writes one `Host` block per entry in `SSH_HOSTS` (alias, `HostName`, `User`, `IdentityFile`, `IdentitiesOnly yes`), editing in place by alias so re-runs update instead of duplicate; blocks it did not write are left byte for byte. Offers `ssh-copy-id` per host and prints `ssh -G <alias>` for verification. | `~/.ssh/config` |
| `git` | Sets `user.name` globally and, if `GIT_EMAIL` is given, a global `user.email` as the default. Writes one `includeIf "gitdir:<folder>/"` per entry in `GIT_FOLDER_EMAILS`, each pointing at a small gitconfig under `~/.config/mac-dev-setup/git/` that sets that folder's `user.email`. Warns if `commit.gpgsign` is on. | `~/.gitconfig`, `~/.config/mac-dev-setup/git/*.gitconfig` |
| `path` | Creates `~/bin` and puts it and mise's shims ahead of `/usr/bin` in `~/.zprofile`. | `~/.zprofile` |
| `mise` | Pins every `tool@version` in `MISE_TOOLS` with `mise use -g`, so a new machine matches the others instead of drifting to latest. | `~/.config/mise/config.toml` |
| `env` | Creates `~/.config/claude/env` (mode 600) with an empty `export NAME=` line per name in `ENV_VARS`, adds missing names on re-run without touching existing values, and sources it from `~/.zshrc`. | `~/.config/claude/env`, `~/.zshrc` |
| `--server` | Reports `pmset` sleep/autorestart, FileVault vs automatic login, and the application firewall, with what a 24/7 machine wants. Changes nothing. | nothing |

### Why one SSH key but several commit emails

One SSH key proves *who is pushing*; GitHub and the other forges accept it for every account it is added to. Commit *attribution* comes from the email in the commit, not the key. So a second key per employer buys nothing, while a wrong `user.email` quietly attributes work-repo commits to the wrong identity. The `includeIf "gitdir:…/"` blocks make the email follow the folder: everything under `~/Work/` gets the work address, everything under `~/Projects/` the personal one. Broad folders go first and specific projects after, since the last matching `includeIf` wins. A commit anywhere else uses `GIT_EMAIL` if you set one, or fails loudly with "Please tell me who you are" if you left it empty.

### Why PATH goes in `~/.zprofile`, not `~/.zshrc`

macOS runs `/usr/libexec/path_helper` from `/etc/zprofile` for every login shell, and it rebuilds `PATH` with `/usr/bin` first regardless of what was passed in. Non-interactive login shells (launchd jobs, `ssh host cmd`, cron) never read `~/.zshrc`, so a `PATH` set only there, or only in a launchd job's environment, loses and you silently get the system Ruby and Python instead of mise's. `~/.zprofile` runs after `path_helper`, so what it sets wins. This cost a day of debugging on the agent server; the comment in the block says so.

### Secrets: `pass-cli` first, env file second

`pass-cli` is already the secret-handling convention in this repo and is the preferred route whenever a command can be wrapped: `pass-cli run -- claude` injects secrets as environment variables for that process and nothing touches disk. The env file is for what cannot be wrapped (launchd agents, plain shells, tools that read the environment at login). It holds names only when written; you fill the values from Proton Pass, and the password manager remains the canonical copy. Both are documented so a machine can use either; the script reminds you of this and prints the `pass-cli run` form when `pass-cli` is installed.

### By hand, afterwards

- Fill `~/.config/claude/env` from your password manager (the script wrote names only).
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
6. `./scripts/setup-machine.sh` — answer the `machine.conf` prompts (git name, hosts, folder emails, mise pins, env var names). It generates the SSH key, writes the host aliases, includeIf blocks, PATH block, pins mise tools, and creates the env file. Add `--server` on a machine that runs unattended.
7. By hand: fill `~/.config/claude/env`, enable Remote Login on the hosts and `ssh-copy-id` them, add DHCP reservations on the router.
8. New terminal again, then `./scripts/doctor.sh` and `./scripts/setup-machine.sh` once more: the second run should report everything already done.
9. `brew services start postgresql@16 && brew services start redis` if this machine needs them.

---

## Troubleshooting

- **`setup-machine.sh` says no machine.conf**: it only creates the file from a terminal. Run it interactively once, or copy `configs/machine.conf.example` to `~/.config/mac-dev-setup/machine.conf` and `chmod 600` it.
- **Wrong Ruby/Python in a launchd job or `ssh host cmd`**: run `./scripts/setup-machine.sh --only path`, then open a new login shell. See "Why PATH goes in `~/.zprofile`".
- **`git commit` says "Please tell me who you are"**: the folder is not in `GIT_FOLDER_EMAILS`. That is the per-folder email model working; add the folder to `machine.conf` (or set `GIT_EMAIL` for a default) and re-run `--only git`.
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
