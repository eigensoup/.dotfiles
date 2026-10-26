#!/bin/bash
set -euo pipefail

# bin/setup-zed.sh
# Idempotent Zed setup: install app + font, link settings, make Zed the default editor.
# Extensions install themselves from "auto_install_extensions" in settings.json.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

ZED_BUNDLE="dev.zed.Zed"
# UTIs and extensions Zed should open by default
ZED_UTIS=(public.plain-text public.source-code public.script public.shell-script public.json
          public.yaml public.xml net.daringfireball.markdown public.python-script
          public.c-source public.swift-source com.netscape.javascript-source)
ZED_EXTS=(md markdown txt lean lake toml json jsonc yaml yml py rs ts tsx js jsx css sh zsh bash
          tex bib cfg ini conf env log csv prisma swift c h cpp hpp go rb sql gitignore)

parse_hard_flag "$@"
print_header "Zed Setup"

print_step "Checking Zed & font..."
ensure_cask "Zed.app" "zed" "Zed"
ensure_font

print_step "Linking Zed settings..."
link_file "$REPO_ROOT/editors/zed/settings.json" "$HOME/.config/zed/settings.json" "settings.json"

print_step "Setting Zed as the default editor..."
git config --global core.editor "zed --wait"
print_success "git core.editor = zed --wait (EDITOR/VISUAL are set in .zshrc)"

if command -v duti &>/dev/null; then
  for uti in "${ZED_UTIS[@]}"; do duti -s "$ZED_BUNDLE" "$uti" all 2>/dev/null || true; done
  for ext in "${ZED_EXTS[@]}"; do duti -s "$ZED_BUNDLE" ".$ext" all 2>/dev/null || true; done
  print_success "Registered Zed as default for text/code file types."
else
  print_warning "duti not found (brew install duti). Skipping Finder file associations."
fi

echo ""
print_success "${BOLD}Zed configured.${NC}"
