#!/bin/bash
set -euo pipefail

# install.sh
# Main installer for dotfiles.

# Resolve the repository root reliably regardless of current working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Colors & Formatting
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symlinks $source into $target, backing up any pre-existing regular file first.
link_dotfile() {
    local source="$1" target="$2" label="$3"
    if [ -L "$target" ]; then
        local resolved
        resolved=$(readlink "$target")
        if [ "$resolved" = "$source" ]; then
            echo "✓ $label is already linked correctly."
        else
            echo "➔ $label is a symlink pointing to '$resolved'. Fixing..."
            rm "$target"
            ln -sf "$source" "$target"
            echo "✓ Successfully linked $label."
        fi
    elif [ -f "$target" ]; then
        if cmp -s "$target" "$source"; then
            echo "➔ $label is identical to the repository version. Replacing with symlink..."
            rm "$target"
        else
            local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
            echo "⚠ $label is a regular file and differs. Backing up to '$backup'..."
            mv "$target" "$backup"
        fi
        ln -sf "$source" "$target"
        echo "✓ Successfully linked $label."
    else
        ln -sf "$source" "$target"
        echo "✓ Successfully linked $label."
    fi
}

# Homebrew Setup (macOS only)
if [ "$(uname)" = "Darwin" ]; then
    echo ""
    echo -e "${CYAN}${BOLD}Checking Homebrew & System Dependencies...${NC}"
    if ! command -v brew &>/dev/null; then
        echo "➔ Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Configure Homebrew path immediately for the current shell session
        if [ "$(uname -m)" = "arm64" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "✓ Homebrew is already installed."
    fi

    # Install packages from Brewfile
    if [ -f "$REPO_ROOT/Brewfile" ]; then
        echo "➔ Installing and bundling packages from Brewfile..."
        brew bundle --file="$REPO_ROOT/Brewfile"
        echo "✓ Brewfile packages successfully installed."
    fi
fi

# Invoke the editor setup script
"$REPO_ROOT/bin/setup-editors.sh"

# Zsh Configuration Setup
echo ""
echo -e "${CYAN}${BOLD}Setting up Zsh Configuration...${NC}"

link_dotfile "$REPO_ROOT/.zshrc" "$HOME/.zshrc" ".zshrc"
link_dotfile "$REPO_ROOT/.p10k.zsh" "$HOME/.p10k.zsh" ".p10k.zsh"

# Secrets File Setup
SECRETS_DIR="$HOME/.zsh"
SECRETS_FILE="$SECRETS_DIR/secrets.zsh"

if [ -f "$SECRETS_FILE" ] || [ -f "$HOME/zsh/secrets.zsh" ]; then
    read -r -p "⚠ secrets.zsh already exists. Overwrite? [y/N] " REPLY || REPLY=""
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "➔ Overwriting secrets file at $SECRETS_FILE..."
        mkdir -p "$SECRETS_DIR"
        cat << 'EOF' > "$SECRETS_FILE"
# ==============================================================================
# Local Secrets & API Keys (DO NOT commit to dotfiles repository)
# ==============================================================================

export GEMINI_API_KEY=""
EOF
        echo "✓ Overwrote secrets file with GEMINI_API_KEY stub."
    else
        echo "✓ Leaving existing secrets file untouched."
    fi
else
    echo "➔ Creating secrets file at $SECRETS_FILE..."
    mkdir -p "$SECRETS_DIR"
    cat << 'EOF' > "$SECRETS_FILE"
# ==============================================================================
# Local Secrets & API Keys (DO NOT commit to dotfiles repository)
# ==============================================================================

export GEMINI_API_KEY=""
EOF
    echo "✓ Created secrets file with GEMINI_API_KEY stub."
fi

# iTerm2 Configuration Check (macOS only)
if [ "$(uname)" = "Darwin" ]; then
    echo ""
    echo -e "${CYAN}${BOLD}Checking iTerm2 Configuration...${NC}"
    
    PREFS_FOLDER=$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || echo "")
    LOAD_PREFS=$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null || echo "0")
    
    # Standardize path (handle ~ and trailing slashes)
    PREFS_FOLDER="${PREFS_FOLDER/#\~/$HOME}"
    PREFS_FOLDER="${PREFS_FOLDER%/}"
    EXPECTED_FOLDER="$REPO_ROOT/iterm"
    EXPECTED_FOLDER="${EXPECTED_FOLDER%/}"
    
    if [ "$PREFS_FOLDER" = "$EXPECTED_FOLDER" ] && [ "$LOAD_PREFS" = "1" ]; then
        echo "✓ iTerm2 is already configured to use preferences from: $EXPECTED_FOLDER"
    else
        echo "➔ iTerm2 preferences not yet linked. Automating configuration..."
        
        defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$EXPECTED_FOLDER"
        defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
        
        echo "✓ Successfully linked iTerm2 configuration folder to: $EXPECTED_FOLDER"
        
        # Check if iTerm2 is running and prompt restart if necessary
        if pgrep -x "iTerm2" >/dev/null; then
            echo -e "${CYAN}${BOLD}Note:${NC} iTerm2 is currently running. Please RESTART iTerm2 for preferences to apply."
        fi
    fi
fi

