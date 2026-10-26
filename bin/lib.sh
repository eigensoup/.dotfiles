#!/bin/bash
# bin/lib.sh
# Shared helpers for setup-*.sh scripts. Source it; do not execute.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_info()    { echo -e "  ${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "  ${RED}✗${NC} $1"; }
print_step()    { echo -e "\n${BOLD}${PURPLE}➔ $1${NC}"; }

print_header() {
  echo -e "${BOLD}${CYAN}================================================================${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
  echo -e "${BOLD}${CYAN}================================================================${NC}"
}

# Parse --hard/--write/--copy/-c into HARD_REWRITE
parse_hard_flag() {
  HARD_REWRITE=0
  for arg in "$@"; do
    case "$arg" in
      --hard|--write|--copy|-c) HARD_REWRITE=1 ;;
    esac
  done
}

# link_file SOURCE TARGET LABEL
# Symlinks TARGET to SOURCE (or copies when HARD_REWRITE=1), backing up a differing file.
link_file() {
  local source="$1" target="$2" label="$3"
  mkdir -p "$(dirname "$target")"

  if [ "${HARD_REWRITE:-0}" -eq 1 ]; then
    [ -L "$target" ] && rm "$target"
    if [ -f "$target" ] && ! cmp -s "$target" "$source"; then
      local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
      print_warning "$label differs from repo. Backing up to '$(basename "$backup")'..."
      mv "$target" "$backup"
    fi
    cp "$source" "$target"
    print_success "Wrote standalone $label -> $target"
    return
  fi

  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$source" ]; then
      print_success "$label is already linked correctly."
      return
    fi
    rm "$target"
  elif [ -f "$target" ]; then
    if cmp -s "$target" "$source"; then
      rm "$target"
    else
      local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
      print_warning "$label differs from repo. Backing up to '$(basename "$backup")'..."
      mv "$target" "$backup"
    fi
  fi
  ln -sf "$source" "$target"
  print_success "Linked $label -> $target"
}

# ensure_cask APP_BUNDLE CASK_NAME LABEL
ensure_cask() {
  local app="$1" cask="$2" label="$3"
  if [ -d "/Applications/$app" ] || [ -d "$HOME/Applications/$app" ]; then
    print_success "$label is already installed."
  elif command -v brew &>/dev/null; then
    print_info "Installing $label via Homebrew..."
    brew install --cask "$cask" && print_success "$label installed." || print_warning "Failed to install $label."
  else
    print_warning "Homebrew not found. Install $label manually."
  fi
}

ensure_font() {
  if [ "${SKIP_FONT_INSTALL:-}" = "1" ]; then return; fi
  ensure_cask_font "font-maple-mono-nf" "Maple Mono NF"
}

ensure_cask_font() {
  local cask="$1" label="$2"
  if ! command -v brew &>/dev/null; then
    print_warning "Homebrew not found. Install '$cask' manually."
  elif brew list --cask "$cask" &>/dev/null; then
    print_success "$label font is already installed."
  elif brew install --cask "$cask" &>/dev/null; then
    print_success "$label font installed."
  else
    print_warning "Failed to install $label font."
  fi
}
