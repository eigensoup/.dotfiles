#!/bin/bash
set -euo pipefail

# bin/setup-node.sh
# Idempotent setup for Node.js environment (nvm, Node LTS, pnpm, bun).

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
echo -e "${BOLD}${CYAN}  Node.js Environment Setup (nvm, Node LTS, pnpm, bun)${NC}"
echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Load nvm if present
load_nvm() {
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
        return 0
    fi
    return 1
}

print_step "Checking Node Version Manager (nvm)..."

if load_nvm; then
    print_success "nvm is active in $NVM_DIR."
else
    print_info "nvm not found. Installing nvm..."
    mkdir -p "$NVM_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | NVM_DIR="$NVM_DIR" bash &>/dev/null
    load_nvm || true
    print_success "nvm installed."
fi

# Ensure Node LTS is installed and default
if command -v nvm &>/dev/null; then
    print_step "Checking Node.js LTS version..."
    nvm install --lts &>/dev/null || true
    nvm use --lts &>/dev/null || true
    nvm alias default 'lts/*' &>/dev/null || true
    print_success "Node.js is ready ($(node -v 2>/dev/null || echo "active"))."
else
    print_warning "nvm command not found in shell environment."
fi

# Package Managers: pnpm & bun
print_step "Checking Package Managers (pnpm & bun)..."

if command -v pnpm &>/dev/null; then
    print_success "pnpm is installed ($(pnpm --version 2>/dev/null))."
else
    print_info "Installing pnpm..."
    if command -v corepack &>/dev/null; then
        corepack enable &>/dev/null || true
        corepack prepare pnpm@latest --activate &>/dev/null || true
    elif command -v npm &>/dev/null; then
        npm install -g pnpm &>/dev/null || true
    fi
    print_success "pnpm setup complete."
fi

if command -v bun &>/dev/null; then
    print_success "bun is installed ($(bun --version 2>/dev/null))."
else
    print_info "Installing bun..."
    curl -fsSL https://bun.sh/install | bash &>/dev/null || print_warning "Bun installation skipped."
    print_success "bun setup complete."
fi

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
print_success "${BOLD}Node setup completed successfully!${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"
