# Eigensoup Dotfiles

A modern, CLI-driven dotfiles & agent environment management system for macOS.

The center of management is the **`es` CLI binary**, which automatically handles dotfile symlinking, GitHub version tracking, MCP server configurations, agent skills, and language toolchains.

---

## Quick Start (Install `es` CLI)

Install the `es` CLI binary directly to `~/.local/bin/es` with a single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/eigensoup/.dotfiles/main/install.sh)"
```

The installer:
1. Installs the `es` CLI binary into `~/.local/bin/es`.
2. Ensures `~/.local/bin` is in your shell `PATH` (via `~/.zshenv`).
3. Clones the public repository to `~/.dotfiles`.
4. Run `es install` to initialize your environment.

---

## `es` CLI Management

Once installed, use the `es` command anywhere in your terminal:

```bash
es <command> [options]
```

### Key Commands

| Command | Description |
| :--- | :--- |
| `es install` | Run interactive TUI to select features (Zsh, Editors, MCPs, Skills, Toolchains). Add `-y` for non-interactive mode. |
| `es update` | Ping GitHub remote (`eigensoup/.dotfiles`), pull latest commit, and update `es` binary (without applying configs). |
| `es sync` | Update local dotfiles repository, update `es` binary, and re-apply configs (`es install --yes`). |
| `es version` | Check local commit SHA against GitHub remote commit SHA and report update availability. |
| `es status` | Display live dashboard of dotfiles symlinks, GitHub version, MCPs, agent skills, and language toolchains. |
| `es zed` / `ghostty` / `vscode` | Set up Zed (default editor), Ghostty, or (opt-in) VS Code with settings and extensions. |
| `es mcps` | Sync MCP server configurations across VS Code, Claude Desktop, and Copilot. |
| `es skills` | Sync Agent Skills (`asm`, `ponytail`, `smart-commit`) across all agent CLIs. |
| `es rust` / `node` / `python` | Setup language toolchains (`rustup`, `node`/`pnpm`/`bun`, `uv`). |
| `es remove` | Revert configs back to existing setups and restore pre-installation backups (retains `es` binary & repo). |
| `es uninstall` | Remove **EVERYTHING** `es`-related (configs, backups, `es` binary, and `~/.dotfiles` repo). |

---

## Environment & Tooling Managed by `es`

### 1. Shell & Terminal
* **Zsh & Powerlevel10k**: `.zshrc` and `.p10k.zsh` symlinked to `~/.dotfiles`.
* **Secrets Stub**: `~/.zsh/secrets.zsh` template for API keys (`GITHUB_PAT`, `OPENAI_API_KEY`, etc.).
* **Ghostty** (`es ghostty`): `~/.config/ghostty/config.ghostty` $\rightarrow$ `ghostty/config.ghostty` (Everforest Light, Maple Mono NF). iTerm2 is retired; see `archive/iterm/`.

### 2. Editors
* **Zed** (default, `es zed`): `~/.config/zed/settings.json` $\rightarrow$ `editors/zed/settings.json`. Extensions install from `auto_install_extensions`. Also sets git `core.editor` and Finder file associations (via `duti`). `EDITOR`/`VISUAL` are set in `.zshrc`.
* **VS Code** (opt-in, `es vscode` or `es install --vscode`): reinstalls the app, links `editors/vscode/settings.json`, and installs every extension in `editors/vscode/extensions.txt`.
* **Fonts**: `font-maple-mono-nf` via Homebrew cask.

### 3. Agent MCP Servers & Skills
* **MCPs**: Configures model context protocol servers for Claude Desktop, Copilot, and VS Code from `mcp/mcp_config.json`. Zed's copy lives under `context_servers` in `editors/zed/settings.json` and must be kept in sync by hand.
* **Agent Skills**: Uses Agent Skills Manager (`asm`) to sync `ponytail` (and sub-skills) and `smart-commit` globally across agent platforms.

### 4. Language Toolchains
* **Rust**: `rustup`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`.
* **Node.js**: `nvm`, Node LTS, `pnpm`, `bun`.
* **Python**: `uv` package manager.

---

## Local Development

If you clone the repository locally:

```bash
git clone https://github.com/eigensoup/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```
