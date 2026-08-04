#!/bin/bash
set -euo pipefail

# bin/setup-skills.sh
# Idempotent setup for Agent Skills Manager (asm), ponytail skills & MCP, and smart-commit skill.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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
echo -e "${BOLD}${CYAN}  Agent Skills Setup (asm, ponytail & smart-commit)${NC}"
echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

# 1. Ensure Agent Skills Manager (asm) is installed
print_step "Checking Agent Skills Manager (asm / luongnv89/asm)..."

if command -v asm &>/dev/null; then
    print_success "asm (Agent Skills Manager) is already installed."
else
    print_info "Installing asm (Agent Skills Manager) globally via npm..."
    if command -v npm &>/dev/null; then
        npm install -g agent-skill-manager || {
            print_error "Failed to install agent-skill-manager via npm."
            exit 1
        }
        print_success "Installed agent-skill-manager (asm) successfully."
    else
        print_error "npm is required to install asm."
        exit 1
    fi
fi

# 2. Setup Ponytail local clone & MCP dependencies
print_step "Setting up Ponytail repository and MCP server dependencies..."
PONYTAIL_DIR="$HOME/.local/share/ponytail"

if [ ! -d "$PONYTAIL_DIR" ]; then
    print_info "Cloning ponytail repository to $PONYTAIL_DIR..."
    mkdir -p "$(dirname "$PONYTAIL_DIR")"
    git clone --depth 1 https://github.com/dietrichgebert/ponytail.git "$PONYTAIL_DIR"
    print_success "Cloned ponytail repository."
else
    print_info "Updating ponytail repository at $PONYTAIL_DIR..."
    (cd "$PONYTAIL_DIR" && git pull --rebase --autostash &>/dev/null || true)
    print_success "Ponytail repository is up to date."
fi

if [ -d "$PONYTAIL_DIR/ponytail-mcp" ]; then
    print_info "Installing ponytail-mcp dependencies..."
    (cd "$PONYTAIL_DIR/ponytail-mcp" && npm install --silent &>/dev/null)
    print_success "Ponytail MCP dependencies installed."
fi

# 3. Install Ponytail skills globally across all agents via asm
print_step "Installing Ponytail skills globally across all agent platforms via asm..."
PONYTAIL_SKILLS=(
    "skills/ponytail"
    "skills/ponytail-review"
    "skills/ponytail-audit"
    "skills/ponytail-debt"
    "skills/ponytail-gain"
    "skills/ponytail-help"
)

for skill_path in "${PONYTAIL_SKILLS[@]}"; do
    skill_name="$(basename "$skill_path")"
    print_info "Syncing $skill_name via asm..."
    asm install github:dietrichgebert/ponytail --path "$skill_path" -p all -s global -y --force &>/dev/null || {
        print_warning "Failed to sync $skill_name via asm."
    }
done
print_success "Ponytail skills installed across all agent platforms."

# 4. Install local smart-commit skill via asm
print_step "Installing smart-commit skill globally via asm..."
SMART_COMMIT_SKILL="$REPO_ROOT/skills/smart-commit"

if [ -d "$SMART_COMMIT_SKILL" ]; then
    asm install "$SMART_COMMIT_SKILL" -p all -s global -y --force &>/dev/null || {
        print_warning "Failed to install smart-commit skill via asm."
    }
    print_success "Installed smart-commit skill globally across all agent platforms."
else
    print_error "Smart commit skill source not found at $SMART_COMMIT_SKILL"
fi

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
print_success "${BOLD}Skills setup completed successfully!${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"
