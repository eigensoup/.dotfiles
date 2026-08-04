#!/bin/bash
set -euo pipefail

# uninstall.sh
# Safely uninstalls dotfiles symlinks and restores backups if available.

# Resolve the repository root reliably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Colors & Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_step() {
    echo -e "\n${BOLD}${PURPLE}➔ $1${NC}"
}

echo -e "${BOLD}${CYAN}================================================================${NC}"
echo -e "${BOLD}${CYAN}  Dotfiles Uninstaller${NC}"
echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

# Target files managed by install.sh, setup-editors.sh, and setup-mcps.sh
TARGETS=(
    "$HOME/.zshrc"
    "$HOME/.p10k.zsh"
    "$HOME/Library/Application Support/Code/User/settings.json"
    "$HOME/Library/Application Support/Cursor/User/settings.json"
    "$HOME/Library/Application Support/Antigravity IDE/User/settings.json"
    "$HOME/.gemini/antigravity-cli/mcp_config.json"
    "$HOME/.gemini/antigravity-ide/mcp_config.json"
    "$HOME/.gemini/antigravity/mcp_config.json"
    "$HOME/Library/Application Support/Code/User/mcp.json"
    "$HOME/.cursor/mcp.json"
    "$HOME/Library/Application Support/Cursor/User/mcp.json"
    "$HOME/.copilot/mcp-config.json"
)

# Helper function to find latest backup file for a target
find_latest_backup() {
    local target="$1"
    local dir
    dir="$(dirname "$target")"
    local base
    base="$(basename "$target")"
    
    # Look for files matching $base.backup.*
    find "$dir" -maxdepth 1 -name "${base}.backup.*" 2>/dev/null | sort -r | head -n 1
}

# 1. Unlink Managed Files
print_step "Checking and removing symlinks..."

for target in "${TARGETS[@]}"; do
    if [ -L "$target" ]; then
        resolved_target=$(readlink "$target" 2>/dev/null || echo "")
        
        # Check if symlink points into our repo
        if [[ "$resolved_target" == "$REPO_ROOT"* ]]; then
            rm "$target"
            print_success "Removed symlink: $target"
            
            # Check for backup file to restore
            latest_backup=$(find_latest_backup "$target")
            if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
                mv "$latest_backup" "$target"
                print_success "Restored backup: $latest_backup -> $target"
            fi
        else
            print_info "Skipping symlink not pointing to this repo: $target -> $resolved_target"
        fi
    elif [ -e "$target" ]; then
        print_info "$target exists but is not a symlink to this repository. Leaving untouched."
    else
        print_info "Target does not exist: $target"
    fi
done

# 2. Revert iTerm2 Preferences (macOS only)
if [ "$(uname)" = "Darwin" ]; then
    print_step "Checking iTerm2 preferences..."
    
    PREFS_FOLDER=$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || echo "")
    PREFS_FOLDER="${PREFS_FOLDER/#\~/$HOME}"
    PREFS_FOLDER="${PREFS_FOLDER%/}"
    EXPECTED_FOLDER="$REPO_ROOT/iterm"
    EXPECTED_FOLDER="${EXPECTED_FOLDER%/}"
    
    if [ "$PREFS_FOLDER" = "$EXPECTED_FOLDER" ]; then
        defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false 2>/dev/null || true
        defaults delete com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || true
        print_success "Unlinked iTerm2 preferences folder and restored default preferences loading."
    else
        print_info "iTerm2 is not currently linked to this repo's preferences."
    fi
fi

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
print_success "${BOLD}Uninstallation complete!${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"
