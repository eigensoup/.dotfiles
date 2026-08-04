#!/bin/bash
set -euo pipefail

# install.sh
# Remote & local installer for dotfiles.
# Supports 1-line installation via curl on a brand new Mac out-of-the-box:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/eigensoup/.dotfiles/main/install.sh)"

DOTFILES_DIR="$HOME/.dotfiles"
GITHUB_USER="${DOTFILES_USER:-eigensoup}"
GITHUB_REPO="${DOTFILES_REPO:-.dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"

# Local vs Remote execution check
if [ -f "$(dirname "${BASH_SOURCE[0]}")/bin/es" ]; then
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "➔ Fresh Mac setup detected. Fetching dotfiles from GitHub..."
        mkdir -p "$DOTFILES_DIR"
        curl -fsSL "https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${BRANCH}.tar.gz" \
            | tar -xz -C "$DOTFILES_DIR" --strip-components=1
        echo "✓ Extracted dotfiles to $DOTFILES_DIR"
    fi
fi

# Ensure executable permissions
chmod +x "$DOTFILES_DIR/bin/es" "$DOTFILES_DIR/bin/setup-editors.sh" "$DOTFILES_DIR/bin/setup-mcps.sh" "$DOTFILES_DIR/bin/setup-skills.sh" "$DOTFILES_DIR/bin/setup-rust.sh" "$DOTFILES_DIR/bin/setup-node.sh" "$DOTFILES_DIR/bin/setup-python.sh" "$DOTFILES_DIR/uninstall.sh" 2>/dev/null || true

# Link es CLI binary to ~/.local/bin/es
TARGET_DIR="$HOME/.local/bin"
TARGET_BIN="$TARGET_DIR/es"
SOURCE_BIN="$DOTFILES_DIR/bin/es"

mkdir -p "$TARGET_DIR"

if [ -L "$TARGET_BIN" ] || [ -f "$TARGET_BIN" ]; then
    rm -f "$TARGET_BIN"
fi
ln -sf "$SOURCE_BIN" "$TARGET_BIN"
echo "✓ Installed 'es' CLI binary to $TARGET_BIN"

# Ensure ~/.local/bin is in PATH via ~/.zshenv
ZSHENV="$HOME/.zshenv"
if ! grep -qs '$HOME/.local/bin' "$ZSHENV" 2>/dev/null && ! grep -qs '"$HOME/.local/bin"' "$ZSHENV" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHENV"
    echo "✓ Added $TARGET_DIR to $ZSHENV"
fi

echo ""
echo "➔ To complete dotfiles setup, run:"
echo "    es install"

