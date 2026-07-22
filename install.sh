#!/bin/bash
set -euo pipefail

# install.sh
# Main installer for dotfiles.

# Resolve the repository root reliably regardless of current working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

echo "==========================================="
echo "Starting dotfiles installation..."
echo "Repository root: $REPO_ROOT"
echo "==========================================="

# Invoke the editor setup script
"$REPO_ROOT/bin/setup-editors.sh"

echo "==========================================="
echo "Dotfiles installation complete!"
echo "==========================================="
