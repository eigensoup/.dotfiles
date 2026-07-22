#!/bin/bash
set -euo pipefail

# bin/setup-editors.sh
# Idempotent setup for VS Code-family editor settings and extensions.

# Resolve repository root
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

# Print helpers
print_success() {
  echo -e "  ${GREEN}✓${NC} $1"
}

print_info() {
  echo -e "  ${BLUE}ℹ${NC} $1"
}

print_warning() {
  echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "  ${RED}✗${NC} $1"
}

print_step() {
  echo -e "\n${BOLD}${PURPLE}➔ $1${NC}"
}

echo -e "${BOLD}${CYAN}"
cat << "EOF"
    ___       __  ___ _ _           
   /   \___  / /_/ _(_) | ___  ___  
  /  /\ / _ \/ __/ _/ / |/ _ \/ __| 
 /  /_// (_) / /_/ // / |  __/\__ \ 
/_____/ \___/\__/_//_/_|_|\___||___/ 
                                    
EOF
echo -e "${NC}"

echo -e "${BOLD}${CYAN}================================================================${NC}"
echo -e "${BOLD}${CYAN}  VS Code-family Editor Configuration Setup${NC}"
echo -e "${DIM}  Repository Root: $REPO_ROOT${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

# 1. Check and Install VS Code if missing
print_step "Checking VS Code installation..."
VSCODE_INSTALLED=0
if [ -d "/Applications/Visual Studio Code.app" ] || [ -d "$HOME/Applications/Visual Studio Code.app" ] || command -v code &>/dev/null; then
  print_success "Visual Studio Code is already installed."
  VSCODE_INSTALLED=1
else
  print_warning "Visual Studio Code was not found."
  if command -v brew &>/dev/null; then
    print_info "Homebrew detected. Auto-installing Visual Studio Code..."
    if brew install --cask visual-studio-code; then
      print_success "Visual Studio Code installed successfully!"
      VSCODE_INSTALLED=1
    else
      print_error "Failed to install Visual Studio Code via Homebrew."
      exit 1
    fi
  else
    print_error "Homebrew is not installed. Unable to auto-install VS Code."
    echo -e "  Please install Homebrew (https://brew.sh) or download VS Code manually from:"
    echo -e "  ${BOLD}https://code.visualstudio.com/${NC}"
    exit 1
  fi
fi

# 2. Detect other editors
print_step "Detecting installed editors..."

CURSOR_INSTALLED=0
if [ -d "/Applications/Cursor.app" ] || [ -d "$HOME/Applications/Cursor.app" ] || command -v cursor &>/dev/null; then
  print_success "Cursor detected."
  CURSOR_INSTALLED=1
else
  print_info "Cursor not found (skipping symlink/extensions)."
fi

ANTIGRAVITY_INSTALLED=0
if [ -d "/Applications/Antigravity IDE.app" ] || [ -d "$HOME/Applications/Antigravity IDE.app" ] || [ -d "/Applications/Antigravity.app" ] || [ -d "$HOME/Applications/Antigravity.app" ] || command -v antigravity &>/dev/null; then
  print_success "Antigravity IDE detected."
  ANTIGRAVITY_INSTALLED=1
else
  print_info "Antigravity IDE not found (skipping symlink/extensions)."
fi

# 3. Dynamically configure targets and sources based on presence
TARGETS=()
SOURCES=()
EDITORS=()

if [ "$VSCODE_INSTALLED" -eq 1 ]; then
  TARGETS+=("$HOME/Library/Application Support/Code/User/settings.json")
  SOURCES+=("$REPO_ROOT/editors/vscode/settings.json")
  EDITORS+=("code")
fi

if [ "$CURSOR_INSTALLED" -eq 1 ]; then
  TARGETS+=("$HOME/Library/Application Support/Cursor/User/settings.json")
  SOURCES+=("$REPO_ROOT/editors/cursor/settings.json")
  EDITORS+=("cursor")
fi

if [ "$ANTIGRAVITY_INSTALLED" -eq 1 ]; then
  TARGETS+=("$HOME/Library/Application Support/Antigravity IDE/User/settings.json")
  SOURCES+=("$REPO_ROOT/editors/antigravity/settings.json")
  EDITORS+=("antigravity")
fi

# Ensure each source settings file exists
for source in "${SOURCES[@]}"; do
  if [ ! -f "$source" ]; then
    print_error "Source settings file not found at $source"
    exit 1
  fi
done

# 4. Setup User directories and create symlinks
print_step "Configuring settings symlinks..."
for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  source="${SOURCES[$i]}"
  parent_dir="$(dirname "$target")"
  
  # Ensure the directory exists
  if [ ! -d "$parent_dir" ]; then
    print_info "Creating directory: $parent_dir"
    mkdir -p "$parent_dir"
  fi

  # Check if target is a symbolic link
  if [ -L "$target" ]; then
    resolved_target=$(readlink "$target")
    if [ "$resolved_target" = "$source" ]; then
      print_success "Symlink correct: $target"
      continue
    else
      print_warning "Symlink points to '$resolved_target' instead of '$source'. Fixing..."
      rm "$target"
    fi
  # Check if target is a regular file
  elif [ -f "$target" ]; then
    backup_file="${target}.backup.$(date +%Y%m%d%H%M%S)"
    print_warning "$target is a regular file. Backing up to '$backup_file'..."
    mv "$target" "$backup_file"
  fi

  # Create the symbolic link
  ln -sf "$source" "$target"
  print_success "Created symlink: $target -> $source"
done

# 5. Build list of extensions to install
EXTENSIONS=(
  "PKief.material-icon-theme"
  "PKief.material-product-icons"
  "usernamehw.errorlens"
  "aaron-bond.better-comments"
  "esbenp.prettier-vscode"
  "ms-python.black-formatter"
  "James-Yu.latex-workshop"
  "andreilucaci.everforest-pro"
)

if [ -n "${SHARED_THEME_EXTENSION_ID:-}" ]; then
  print_info "Using configured theme extension ID: $SHARED_THEME_EXTENSION_ID"
  EXTENSIONS+=("$SHARED_THEME_EXTENSION_ID")
fi

# 6. Install shared extensions for detected editor CLIs
print_step "Installing extensions for detected editors..."
for editor in "${EDITORS[@]}"; do
  if command -v "$editor" &>/dev/null; then
    echo -e "  Installing extensions for '${BOLD}$editor${NC}'..."
    
    # Query currently installed extensions once to optimize checks
    installed_exts=$("$editor" --list-extensions 2>/dev/null || echo "")
    
    for ext in "${EXTENSIONS[@]}"; do
      if echo "$installed_exts" | grep -qi "^$ext$"; then
        echo -e "    ${GREEN}✓${NC} Extension '$ext' is already installed."
      else
        echo -e "    ${BLUE}⚙${NC} Installing $ext..."
        if "$editor" --install-extension "$ext" &>/dev/null; then
          echo -e "    ${GREEN}✓${NC} Installed $ext."
        else
          echo -e "    ${YELLOW}⚠${NC} Failed to install $ext. Skipping..."
        fi
      fi
    done
  else
    print_warning "CLI command '$editor' is not available in PATH. Skipping extension installation for it."
    echo -e "    You can install them manually inside the editor's extensions panel:"
    for ext in "${EXTENSIONS[@]}"; do
      echo -e "    - $ext"
    done
  fi
done

# 7. Handle optional Maple Mono installation
if [ "${SKIP_FONT_INSTALL:-}" = "1" ]; then
  print_info "Skipping font installation (SKIP_FONT_INSTALL is set)."
else
  print_step "Checking Maple Mono NF font..."
  if command -v brew &>/dev/null; then
    if brew list --cask font-maple-mono-nf &>/dev/null; then
      print_success "font-maple-mono-nf is already installed via Homebrew."
    else
      print_info "Installing font-maple-mono-nf via Homebrew..."
      if brew install --cask font-maple-mono-nf &>/dev/null; then
        print_success "font-maple-mono-nf installed successfully!"
      else
        print_warning "Failed to install font-maple-mono-nf via Homebrew."
      fi
    fi
  else
    print_warning "Homebrew not found. Please install 'font-maple-mono-nf' manually."
  fi
fi

# 8. Verify links and exit status
print_step "Verifying symlink status..."
VERIFICATION_FAILED=0

for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  source="${SOURCES[$i]}"
  expected_literal="~${source#$HOME}"
  
  if [ -L "$target" ]; then
    resolved_dest=$(readlink "$target")
    if [ "$resolved_dest" = "$source" ]; then
      print_success "Valid link: $target -> $expected_literal"
    else
      print_error "Invalid link: $target (Expected: $source, Got: $resolved_dest)"
      VERIFICATION_FAILED=1
    fi
  else
    print_error "Not a symlink: $target"
    VERIFICATION_FAILED=1
  fi
done

echo -e "\n${BOLD}${CYAN}================================================================${NC}"
if [ "$VERIFICATION_FAILED" -ne 0 ]; then
  print_error "Setup complete with errors. Please check the logs above."
  echo -e "${BOLD}${CYAN}================================================================${NC}"
  exit 1
else
  print_success "${BOLD}All editor configurations completed successfully!${NC}"
  echo -e "${BOLD}${CYAN}================================================================${NC}"
  exit 0
fi
