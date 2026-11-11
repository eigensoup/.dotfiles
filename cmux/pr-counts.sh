#!/bin/sh
# Writes open-PR counts per repo for a GitHub owner into a cmux sidebar (which
# can't make network calls itself). cmux hot-reloads the sidebar on save.
# Usage: pr-counts.sh <owner> [sidebar.js]   (default: ~/.config/cmux/sidebars/projects.js)
set -e
owner="${1:?usage: pr-counts.sh <github-owner> [sidebar.js]}"
f=$(realpath "${2:-$HOME/.config/cmux/sidebars/projects.js}")
counts=$(gh search prs --owner "$owner" --state open --limit 500 --json repository \
  --jq 'map(.repository.name) | group_by(.) | map({(.[0]): length}) | add // {} | tojson')
sed -i '' "s|^const PR_COUNTS = .*|const PR_COUNTS = $counts;|" "$f"
echo "$counts"
