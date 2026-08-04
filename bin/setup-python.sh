#!/bin/bash
set -euo pipefail

# bin/setup-python.sh
# Idempotent setup for Python tooling (uv).

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
echo -e "${BOLD}${CYAN}  Python Tooling Setup (uv)${NC}"
echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

print_step "Checking uv (Extremely fast Python package & project manager)..."

if command -v uv &>/dev/null || [ -x "$HOME/.local/bin/uv" ]; then
    UV_BIN="$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")"
    print_success "uv is installed ($("$UV_BIN" --version 2>/dev/null | head -n 1))."
    print_info "Updating uv to latest version..."
    "$UV_BIN" self update &>/dev/null || print_warning "uv self-update skipped or unneeded."
else
    print_info "uv not found. Installing uv..."
    if command -v brew &>/dev/null; then
        brew install uv &>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh &>/dev/null
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh &>/dev/null
    fi
    print_success "uv installed successfully."
fi

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
print_success "${BOLD}Python setup completed successfully!${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"
