#!/bin/bash
set -euo pipefail

# bin/setup-editors.sh
# Opt-in VS Code setup (Zed is the default editor). Reinstalls VS Code if missing,
# links settings.json, and installs every extension in editors/vscode/extensions.txt.
# Run with: es vscode

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

SETTINGS="$REPO_ROOT/editors/vscode/settings.json"
EXTENSIONS_FILE="$REPO_ROOT/editors/vscode/extensions.txt"

parse_hard_flag "$@"
print_header "VS Code Setup (opt-in)"

print_step "Checking VS Code..."
ensure_cask "Visual Studio Code.app" "visual-studio-code" "Visual Studio Code"
ensure_font

print_step "Linking VS Code settings..."
link_file "$SETTINGS" "$HOME/Library/Application Support/Code/User/settings.json" "settings.json"

print_step "Installing VS Code extensions..."
CODE_BIN="$(command -v code || true)"
[ -z "$CODE_BIN" ] && [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ] \
  && CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

if [ -z "$CODE_BIN" ]; then
  print_warning "'code' CLI not found. Install these manually from $EXTENSIONS_FILE"
else
  installed="$("$CODE_BIN" --list-extensions 2>/dev/null || true)"
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    if echo "$installed" | grep -qix "$ext"; then
      print_success "$ext"
    elif "$CODE_BIN" --install-extension "$ext" &>/dev/null; then
      print_success "Installed $ext"
    else
      print_warning "Failed to install $ext"
    fi
  done < "$EXTENSIONS_FILE"
fi

echo ""
print_success "${BOLD}VS Code configured.${NC}"
