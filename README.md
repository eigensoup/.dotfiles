# Dotfiles

A robust dotfiles management system focusing on consistent development environments on macOS.

## Editor Setup (`bin/setup-editors.sh`)

This script manages settings and extensions consistently across Visual Studio Code, Cursor, and Antigravity IDE.

### Canonical Settings Locations
The source of truth for each editor's configuration is managed individually:
* **Visual Studio Code:** `~/.dotfiles/editors/vscode/settings.json` (configured with Everforest Pro Light)
* **Cursor:** `~/.dotfiles/editors/cursor/settings.json` (configured with Solarized Light)
* **Antigravity IDE:** `~/.dotfiles/editors/antigravity/settings.json` (configured with Solarized Light)

### Symbolic Links Configured
The setup script creates necessary configuration directories and symlinks the respective settings file to the following paths:
* **Visual Studio Code:** `~/Library/Application Support/Code/User/settings.json` -> `~/.dotfiles/editors/vscode/settings.json`
* **Cursor:** `~/Library/Application Support/Cursor/User/settings.json` -> `~/.dotfiles/editors/cursor/settings.json`
* **Antigravity IDE:** `~/Library/Application Support/Antigravity IDE/User/settings.json` -> `~/.dotfiles/editors/antigravity/settings.json`

*Note: The script safely bypasses and preserves the separate `~/Library/Application Support/Antigravity` directory.*

### Extension Installation
The script installs the following shared extensions in every supported editor whose command-line interface (CLI) is available on your path (`code`, `cursor`, `antigravity-ide`):
* Material Icon Theme (`PKief.material-icon-theme`)
* Material Product Icons (`PKief.material-product-icons`)
* Error Lens (`usernamehw.errorlens`)
* Better Comments (`aaron-bond.better-comments`)
* Prettier (`esbenp.prettier-vscode`)
* Black Formatter (`ms-python.black-formatter`)
* LaTeX Workshop (`James-Yu.latex-workshop`)

#### Important Integration Notes
* **Separation of Concerns:** While editor settings are fully shared (symlinked), extensions must still be installed separately for each editor.
* **Proprietary Settings:** Proprietary editor-specific settings (e.g., Cursor AI settings or VSCodium integrations) may appear as unknown/unsupported configuration entries in the other editors. They are generally ignored gracefully by each respective platform.
* **Unavailable CLIs:** If an editor's CLI tool is unavailable, the script will skip installing extensions for that editor and output a list of extensions for you to install manually.
* **Antigravity Extensions:** Some extensions may need to be installed from the Extensions panel within Antigravity if they are not available in its extension registry.

### Configuring Custom Theme Extension ID
By default, the script automatically installs the Everforest Pro theme (`andreilucaci.everforest-pro`) for VS Code. If you want to configure or install another theme extension, you can pass its ID using the `SHARED_THEME_EXTENSION_ID` environment variable:

```bash
SHARED_THEME_EXTENSION_ID="publisher.extension-name" ~/.dotfiles/bin/setup-editors.sh
```

### Font Installation Opt-Out
The shared settings configure `Maple Mono NF` as a preferred editor font. The script will automatically attempt to install the cask `font-maple-mono-nf` using Homebrew if Homebrew is available.

You can opt out of this font installation by setting:
```bash
SKIP_FONT_INSTALL=1 ./install.sh
```

---

## Installation & Usage

### 1. Complete Setup
To run the main installer (which automatically invokes the editor setup):
```bash
cd ~/.dotfiles
./install.sh
```

### 2. Editor-Only Setup
To run only the editor configuration and extension manager:
```bash
~/.dotfiles/bin/setup-editors.sh
```
