#!/usr/bin/env bash
# clean-ai.sh — Remove an AI assistant config file from the project.
#
# Usage:
#   scripts/clean-ai.sh --ai=copilot
#   scripts/clean-ai.sh --ai=gemini

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# ── Parse args ────────────────────────────────────────────────────────────────

AI=""
for arg in "$@"; do
  case "$arg" in
    --ai=*) AI="${arg#--ai=}" ;;
  esac
done

if [ -z "$AI" ]; then
  echo "Error: --ai is required. Options: copilot, gemini"
  exit 1
fi

# ── Resolve target file ───────────────────────────────────────────────────────

case "$AI" in
  copilot) TARGET="$PROJECT_ROOT/.github/copilot-instructions.md" ;;
  gemini)  TARGET="$PROJECT_ROOT/GEMINI.md" ;;
  *)
    echo "Error: unknown AI '$AI'. Options: copilot, gemini"
    exit 1
    ;;
esac

# ── Remove ────────────────────────────────────────────────────────────────────

if [ ! -f "$TARGET" ]; then
  echo "  Nothing to remove — '$TARGET' does not exist."
  exit 0
fi

printf "  Remove '%s'? [y/N]: " "$(basename "$TARGET")"
read -r confirm
case "$confirm" in
  y|Y|yes|YES)
    rm "$TARGET"
    echo "  removed  $TARGET"
    ;;
  *)
    echo "  Skipped."
    ;;
esac
