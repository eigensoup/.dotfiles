#!/bin/bash
set -euo pipefail

# bin/setup-rust.sh
# Idempotent setup for Rust toolchain (rustup, cargo, rustfmt, clippy, rust-analyzer).

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
echo -e "${BOLD}${CYAN}  Rust Toolchain Setup (rustup, cargo, rust-analyzer)${NC}"
echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

# Source cargo env if available
if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
fi

print_step "Checking Rust Toolchain (rustup & cargo)..."

if command -v rustup &>/dev/null; then
    print_success "rustup is already installed ($(rustup --version | head -n 1))."
    print_info "Updating active Rust toolchain..."
    rustup update stable &>/dev/null || print_warning "rustup update failed, using current toolchain."
else
    print_info "rustup not found. Installing Rust toolchain via official installer..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi
    print_success "Rust toolchain installed successfully."
fi

# Ensure essential components are installed
if command -v rustup &>/dev/null; then
    print_step "Checking Rust components (rustfmt, clippy, rust-analyzer)..."
    rustup component add rustfmt clippy rust-analyzer &>/dev/null || print_warning "Failed to add some Rust components."
    print_success "Rust components up to date."
fi

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
print_success "${BOLD}Rust setup completed successfully!${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"
