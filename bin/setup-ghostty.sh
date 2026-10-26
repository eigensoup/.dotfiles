#!/bin/bash
set -euo pipefail

# bin/setup-ghostty.sh
# Idempotent Ghostty setup: install app + font, link config.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

parse_hard_flag "$@"
print_header "Ghostty Setup"

print_step "Checking Ghostty & font..."
ensure_cask "Ghostty.app" "ghostty" "Ghostty"
ensure_font

print_step "Linking Ghostty config..."
link_file "$REPO_ROOT/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty" "config.ghostty"

echo ""
print_success "${BOLD}Ghostty configured.${NC} Reload with cmd-shift-, in Ghostty."
