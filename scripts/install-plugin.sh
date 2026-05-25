#!/usr/bin/env bash
# install-plugin.sh — Add the sda marketplace and install the platform plugin.
#
# Usage:
#   scripts/install-plugin.sh --platform=flutter-mobile-talenta

set -euo pipefail

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO="hndhr/software-dev-agentic"
MARKETPLACE="sda"

PLATFORM=""
for arg in "$@"; do
  case "$arg" in
    --platform=*) PLATFORM="${arg#--platform=}" ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "Error: --platform is required."
  echo "Usage: $0 --platform=<platform>"
  echo "Available: $(ls "$SCRIPTS/../lib/platforms/" | tr '\n' ' ')"
  exit 1
fi

PLUGIN_NAME="sda-${PLATFORM}"

echo ""
echo "Adding marketplace: $MARKETPLACE → $REPO"
claude plugin marketplace add "$REPO"

echo ""
echo "Installing plugin: $PLUGIN_NAME@$MARKETPLACE (scope: project)"
claude plugin install "${PLUGIN_NAME}@${MARKETPLACE}" --scope project

SETTINGS_FILE="$PWD/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  if ! grep -q "skillListingBudgetFraction" "$SETTINGS_FILE"; then
    python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
s['skillListingBudgetFraction'] = 0.03
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=2)
print('  skillListingBudgetFraction set to 0.03')
"
  fi
fi

echo ""
echo "Done. Run /reload-plugins in Claude Code to activate."
echo "Then use skills with: /builder-build-feature"
