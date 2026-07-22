#!/bin/bash
set -euo pipefail

# bin/setup-editors.sh
# Idempotent setup for VS Code-family editor settings and extensions.

# Resolve repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==========================================="
echo "VS Code-family Editor Configuration Setup"
echo "Repository Root: $REPO_ROOT"
echo "==========================================="

# Configuration targets and their corresponding sources
TARGETS=(
  "$HOME/Library/Application Support/Code/User/settings.json"
  "$HOME/Library/Application Support/Cursor/User/settings.json"
  "$HOME/Library/Application Support/Antigravity IDE/User/settings.json"
)
SOURCES=(
  "$REPO_ROOT/editors/vscode/settings.json"
  "$REPO_ROOT/editors/cursor/settings.json"
  "$REPO_ROOT/editors/antigravity/settings.json"
)

# Ensure each source settings file exists
for source in "${SOURCES[@]}"; do
  if [ ! -f "$source" ]; then
    echo "Error: Source settings file not found at $source" >&2
    exit 1
  fi
done

# 1. Setup User directories and create symlinks
echo "Configuring settings symlinks..."
for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  source="${SOURCES[$i]}"
  parent_dir="$(dirname "$target")"
  
  # Ensure the directory exists
  if [ ! -d "$parent_dir" ]; then
    echo "  [OK] Creating directory: $parent_dir"
    mkdir -p "$parent_dir"
  fi

  # Check if target is a symbolic link
  if [ -L "$target" ]; then
    resolved_target=$(readlink "$target")
    if [ "$resolved_target" = "$source" ]; then
      echo "  [SKIP] $target is already a correct symbolic link."
      continue
    else
      echo "  [WARN] $target is a symlink pointing to '$resolved_target' instead of '$source'. Removing incorrect symlink."
      rm "$target"
    fi
  # Check if target is a regular file
  elif [ -f "$target" ]; then
    backup_file="${target}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  [WARN] $target is a regular file. Backing up to '$backup_file'..."
    mv "$target" "$backup_file"
  fi

  # Create the symbolic link
  echo "  [OK] Symlinking $target -> $source"
  ln -sf "$source" "$target"
done
echo ""

# 2. Build list of extensions to install
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
  echo "Using configured theme extension ID: $SHARED_THEME_EXTENSION_ID"
  EXTENSIONS+=("$SHARED_THEME_EXTENSION_ID")
fi
echo ""

# 3. Install shared extensions for available editor CLIs
EDITORS=("code" "cursor" "antigravity")

for editor in "${EDITORS[@]}"; do
  if command -v "$editor" &>/dev/null; then
    echo "Installing extensions for '$editor'..."
    
    # Query currently installed extensions once to optimize checks
    installed_exts=$("$editor" --list-extensions 2>/dev/null || echo "")
    
    for ext in "${EXTENSIONS[@]}"; do
      if echo "$installed_exts" | grep -qi "^$ext$"; then
        echo "  [SKIP] Extension '$ext' is already installed on '$editor'."
      else
        echo "  [OK] Installing $ext on '$editor'..."
        # Run installation and warn if it fails
        if ! "$editor" --install-extension "$ext"; then
          echo "  [WARN] Failed to install $ext on '$editor'."
        fi
      fi
    done
  else
    echo "==========================================="
    echo "WARNING: Editor CLI '$editor' is not available."
    echo "The following extensions must be installed manually for '$editor':"
    for ext in "${EXTENSIONS[@]}"; do
      echo "  - $ext"
    done
    if [ "$editor" = "antigravity" ]; then
      echo "Note: For Antigravity, some extensions may need to be installed from its Extensions panel if they are unavailable from its extension registry."
    fi
    echo "==========================================="
  fi
  echo ""
done

# 4. Handle optional Maple Mono installation
if [ "${SKIP_FONT_INSTALL:-}" = "1" ]; then
  echo "Skipping font installation (SKIP_FONT_INSTALL is set to 1)."
else
  if command -v brew &>/dev/null; then
    echo "Checking Maple Mono NF font installation..."
    if brew list --cask font-maple-mono-nf &>/dev/null; then
      echo "  [SKIP] font-maple-mono-nf is already installed via Homebrew."
    else
      echo "  [OK] Installing font-maple-mono-nf..."
      # Prevent failure during install
      if ! brew install --cask font-maple-mono-nf; then
        echo "  [WARN] Failed to install font-maple-mono-nf via Homebrew."
      fi
    fi
  else
    echo "==========================================="
    echo "WARNING: Homebrew is not available."
    echo "Please install 'font-maple-mono-nf' manually to support the 'Maple Mono NF' font family referenced in settings."
    echo "==========================================="
  fi
fi
echo ""

# 5. Verify links and exit status
VERIFICATION_FAILED=0

echo "==========================================="
echo "Verifying symlink destinations..."
echo "==========================================="

for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  source="${SOURCES[$i]}"
  
  # Get expected literal for display (replace HOME with ~)
  expected_literal="~${source#$HOME}"
  
  echo "Configured path: $target"
  
  if [ -L "$target" ]; then
    echo "  Is symbolic link: Yes"
    resolved_dest=$(readlink "$target")
    echo "  Resolved destination: $resolved_dest"
    
    if [ "$resolved_dest" = "$source" ]; then
      echo "  Resolved destination equals $expected_literal: Yes"
    else
      echo "  [ERROR] Resolved destination equals $expected_literal: No (Expected: $source)"
      VERIFICATION_FAILED=1
    fi
  else
    echo "  Is symbolic link: No"
    if [ -e "$target" ]; then
      echo "  [ERROR] Path exists but is not a symbolic link."
    else
      echo "  [ERROR] Path does not exist."
    fi
    VERIFICATION_FAILED=1
  fi
  echo ""
done

if [ "$VERIFICATION_FAILED" -ne 0 ]; then
  echo "ERROR: One or more expected settings.json paths are invalid or not configured correctly." >&2
  exit 1
else
  echo "All settings.json paths successfully configured!"
  exit 0
fi
