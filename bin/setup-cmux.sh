#!/bin/bash
set -euo pipefail

# bin/setup-cmux.sh
# Idempotent cmux setup: install app, link shared files, seed per-machine templates.
# cmux.json and sidebars/projects.js are copied (never linked or overwritten) because
# they hold your own project list, which stays out of this public repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

parse_hard_flag "$@"
print_header "cmux Setup"

print_step "Checking cmux..."
ensure_cask "cmux.app" "cmux" "cmux"

print_step "Linking cmux dock & PR-count script..."
for f in dock.json pr-counts.sh; do
  link_file "$REPO_ROOT/cmux/$f" "$HOME/.config/cmux/$f" "cmux $f"
done

print_step "Seeding cmux templates (kept if present)..."
for f in cmux.json sidebars/projects.js; do
  target="$HOME/.config/cmux/$f"
  if [ -e "$target" ]; then
    print_success "cmux $f already exists; leaving it alone."
  else
    mkdir -p "$(dirname "$target")"
    sed "s|__HOME__|$HOME|g" "$REPO_ROOT/cmux/$f" > "$target"
    print_success "Created $target from template."
  fi
done

echo ""
print_success "${BOLD}cmux configured.${NC} Add your projects to ~/.config/cmux/sidebars/projects.js and cmux.json, then: cmux sidebar select projects"
