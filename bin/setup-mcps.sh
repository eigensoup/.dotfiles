#!/bin/bash
set -euo pipefail

# bin/setup-mcps.sh
# Installs MCP server configurations across agent CLIs and editors.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_MCP="$REPO_ROOT/mcp/mcp_config.json"

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
echo -e "${BOLD}${CYAN}  MCP Servers Configuration Setup${NC}"
echo -e "${DIM}  Source: $SOURCE_MCP${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

HARD_REWRITE=0
for arg in "$@"; do
    case "$arg" in
        --hard|--write|--copy|-c) HARD_REWRITE=1 ;;
    esac
done

if [ ! -f "$SOURCE_MCP" ]; then
    print_error "Source MCP configuration not found at $SOURCE_MCP"
    exit 1
fi

# List of target config paths for CLIs and Editors
TARGETS=(
    "$HOME/.gemini/antigravity-cli/mcp_config.json"
    "$HOME/.gemini/antigravity-ide/mcp_config.json"
    "$HOME/.gemini/antigravity/mcp_config.json"
    "$HOME/Library/Application Support/Code/User/mcp.json"
    "$HOME/.cursor/mcp.json"
    "$HOME/Library/Application Support/Cursor/User/mcp.json"
    "$HOME/.copilot/mcp-config.json"
)

install_mcp_file() {
    local target="$1"
    local parent_dir
    parent_dir="$(dirname "$target")"

    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi

    if [ "$HARD_REWRITE" -eq 1 ]; then
        if [ -L "$target" ]; then
            rm "$target"
        elif [ -f "$target" ]; then
            if ! cmp -s "$target" "$SOURCE_MCP"; then
                local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
                print_warning "$(basename "$target") differs. Backing up to '$(basename "$backup")'..."
                mv "$target" "$backup"
            fi
        fi
        cp "$SOURCE_MCP" "$target"
        print_success "Wrote standalone MCP config: $target"
    else
        if [ -L "$target" ]; then
            local resolved
            resolved=$(readlink "$target" 2>/dev/null || echo "")
            if [ "$resolved" = "$SOURCE_MCP" ]; then
                print_success "MCP link correct: $target"
                return
            else
                rm "$target"
            fi
        elif [ -f "$target" ]; then
            if cmp -s "$target" "$SOURCE_MCP"; then
                rm "$target"
            else
                local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
                print_warning "Existing file differs. Backing up to '$(basename "$backup")'..."
                mv "$target" "$backup"
            fi
        fi

        ln -sf "$SOURCE_MCP" "$target"
        print_success "Linked MCP config: $target -> $SOURCE_MCP"
    fi
}

print_step "Installing MCP configs across Agent CLIs & Editors..."

for target in "${TARGETS[@]}"; do
    install_mcp_file "$target"
done

# Special merge for Claude Desktop config if installed
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
if [ -d "$(dirname "$CLAUDE_CONFIG")" ]; then
    print_step "Updating Claude Desktop MCP configuration..."
    if [ -f "$CLAUDE_CONFIG" ]; then
        if command -v python3 &>/dev/null; then
            python3 - "$SOURCE_MCP" "$CLAUDE_CONFIG" << 'PYEOF'
import json, sys

source_path, target_path = sys.argv[1], sys.argv[2]
try:
    with open(source_path, 'r') as f:
        mcp_data = json.load(f)
    mcp_servers = mcp_data.get("mcpServers", {})

    try:
        with open(target_path, 'r') as f:
            target_data = json.load(f)
    except Exception:
        target_data = {}

    target_data["mcpServers"] = target_data.get("mcpServers", {})
    target_data["mcpServers"].update(mcp_servers)

    with open(target_path, 'w') as f:
        json.dump(target_data, f, indent=2)
    print("  ✓ Merged MCP servers into Claude Desktop config.")
except Exception as e:
    print(f"  ⚠ Failed to merge Claude Desktop MCP config: {e}")
PYEOF
        else
            install_mcp_file "$CLAUDE_CONFIG"
        fi
    else
        install_mcp_file "$CLAUDE_CONFIG"
    fi
fi

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
print_success "${BOLD}MCP server configuration setup complete!${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"
