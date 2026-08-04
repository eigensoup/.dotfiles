#!/bin/bash
set -euo pipefail

# uninstall.sh
# Safely reverts dotfile configurations and/or completely purges es CLI and repository.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

PURGE_MODE=0
for arg in "$@"; do
    case "$arg" in
        --purge|--all|--full|purge) PURGE_MODE=1 ;;
    esac
done

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

print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_info()    { echo -e "  ${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "  ${RED}✗${NC} $1"; }
print_step()    { echo -e "\n${BOLD}${PURPLE}➔ $1${NC}"; }

echo -e "${BOLD}${CYAN}================================================================${NC}"
if [ "$PURGE_MODE" -eq 1 ]; then
    echo -e "${BOLD}${CYAN}  Full Uninstallation (Purging configs, binary & repository)${NC}"
else
    echo -e "${BOLD}${CYAN}  Removing Dotfile Configs & Restoring Backups${NC}"
fi
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
    local dir base
    dir="$(dirname "$target")"
    base="$(basename "$target")"
    find "$dir" -maxdepth 1 -name "${base}.backup.*" 2>/dev/null | sort -r | head -n 1
}

# 1. Unlink Managed Files & Restore Backups
print_step "Checking and removing symlinks / restoring backups..."

for target in "${TARGETS[@]}"; do
    if [ -L "$target" ]; then
        resolved_target=$(readlink "$target" 2>/dev/null || echo "")
        
        if [[ "$resolved_target" == "$REPO_ROOT"* ]] || [[ "$resolved_target" == *".dotfiles"* ]]; then
            rm -f "$target"
            print_success "Removed symlink: $target"
            
            latest_backup=$(find_latest_backup "$target")
            if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
                mv "$latest_backup" "$target"
                print_success "Restored backup: $(basename "$latest_backup") -> $target"
            fi
        else
            print_info "Skipping external symlink: $target -> $resolved_target"
        fi
    elif [ -f "$target" ]; then
        latest_backup=$(find_latest_backup "$target")
        if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
            rm -f "$target"
            mv "$latest_backup" "$target"
            print_success "Restored backup over modified target: $(basename "$latest_backup") -> $target"
        fi
    fi
done

# 2. Revert Agent Skills
print_step "Cleaning up agent skills..."
if [ -d "$HOME/.agents/skills/ponytail" ]; then
    rm -rf "$HOME/.agents/skills/ponytail"* 2>/dev/null || true
    print_success "Removed ponytail agent skills from ~/.agents/skills/"
fi
if [ -d "$HOME/.agents/skills/smart-commit" ]; then
    rm -rf "$HOME/.agents/skills/smart-commit"* 2>/dev/null || true
    print_success "Removed smart-commit agent skill from ~/.agents/skills/"
fi

# 3. Revert iTerm2 Preferences (macOS only)
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
        print_success "Unlinked iTerm2 preferences folder."
    fi
fi

if [ "$PURGE_MODE" -eq 1 ]; then
    print_step "Purging 'es' CLI binary & dotfiles repository..."
    
    # Remove es binary
    LOCAL_ES="$HOME/.local/bin/es"
    if [ -e "$LOCAL_ES" ] || [ -L "$LOCAL_ES" ]; then
        rm -f "$LOCAL_ES"
        print_success "Removed CLI binary at $LOCAL_ES"
    fi

    # Clean ~/.zshenv PATH entry if added by es
    ZSHENV="$HOME/.zshenv"
    if [ -f "$ZSHENV" ] && grep -q 'export PATH="\$HOME/\.local/bin:\$PATH"' "$ZSHENV" 2>/dev/null; then
        sed -i '' '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "$ZSHENV" 2>/dev/null || true
        print_success "Cleaned $LOCAL_ES PATH export from $ZSHENV"
    fi

    # Remove repository directory if $REPO_ROOT is $HOME/.dotfiles
    if [ "$REPO_ROOT" = "$HOME/.dotfiles" ] && [ -d "$REPO_ROOT" ]; then
        rm -rf "$REPO_ROOT"
        print_success "Removed dotfiles repository directory at $REPO_ROOT"
    else
        print_info "Dotfiles repository at $REPO_ROOT was preserved (not in default $HOME/.dotfiles path)."
    fi

    echo -e "\n${BOLD}${CYAN}================================================================${NC}"
    print_success "${BOLD}Full uninstallation complete! Everything 'es'-related has been removed.${NC}"
    echo -e "${BOLD}${CYAN}================================================================${NC}\n"
else
    echo -e "\n${BOLD}${CYAN}================================================================${NC}"
    print_success "${BOLD}Config removal complete! Reverted to existing setups / backups.${NC}"
    print_info "The 'es' CLI binary and dotfiles repo remain available to re-run 'es install' anytime."
    echo -e "${BOLD}${CYAN}================================================================${NC}\n"
fi
