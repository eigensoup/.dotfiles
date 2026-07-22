#!/bin/bash
set -euo pipefail

# install.sh
# Main installer for dotfiles.

# Resolve the repository root reliably regardless of current working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Colors & Formatting
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Invoke the editor setup script
"$REPO_ROOT/bin/setup-editors.sh"
