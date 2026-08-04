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
chmod +x "$DOTFILES_DIR/bin/es" "$DOTFILES_DIR/bin/setup-editors.sh" "$DOTFILES_DIR/uninstall.sh" 2>/dev/null || true

# Execute es install (attaching /dev/tty if piped from curl)
if [ ! -t 0 ] && [ -e /dev/tty ]; then
    exec "$DOTFILES_DIR/bin/es" install "$@" </dev/tty
else
    exec "$DOTFILES_DIR/bin/es" install "$@"
fi
