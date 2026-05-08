#!/usr/bin/env bash
# setup-ai.sh — Generate an AI assistant config file from the software-dev-agentic templates.
# Safe to re-run — will prompt before overwriting an existing file.
#
# Usage:
#   scripts/setup-ai.sh --ai=copilot --platform=ios [--app-name=MyApp]
#   scripts/setup-ai.sh --ai=gemini  --platform=web [--app-name=MyApp]

set -euo pipefail

SUBMODULE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$SUBMODULE/../.." && pwd)"

# ── Parse args ────────────────────────────────────────────────────────────────

AI=""
PLATFORM=""
APP_NAME=""

for arg in "$@"; do
  case "$arg" in
    --ai=*)       AI="${arg#--ai=}" ;;
    --platform=*) PLATFORM="${arg#--platform=}" ;;
    --app-name=*) APP_NAME="${arg#--app-name=}" ;;
  esac
done

if [ -z "$AI" ]; then
  echo "Error: --ai is required. Options: copilot, gemini"
  exit 1
fi

if [ -z "$PLATFORM" ]; then
  echo "Error: --platform is required. Options: ios, web, flutter, android"
  exit 1
fi

TEMPLATE="$SUBMODULE/lib/ai-platforms/$AI/template.md"
if [ ! -f "$TEMPLATE" ]; then
  echo "Error: no template for '$AI' at $TEMPLATE"
  exit 1
fi

# ── Resolve output path per AI ─────────────────────────────────────────────────

case "$AI" in
  copilot)
    OUTPUT="$PROJECT_ROOT/.github/copilot-instructions.md"
    mkdir -p "$PROJECT_ROOT/.github"
    ;;
  gemini)
    OUTPUT="$PROJECT_ROOT/GEMINI.md"
    ;;
  *)
    echo "Error: unknown AI '$AI'. Options: copilot, gemini"
    exit 1
    ;;
esac

# ── Prompt before overwrite ───────────────────────────────────────────────────

if [ -f "$OUTPUT" ]; then
  printf "  '%s' already exists. Overwrite? [y/N]: " "$(basename "$OUTPUT")"
  read -r confirm
  case "$confirm" in
    y|Y|yes|YES) ;;
    *) echo "  Skipped."; exit 0 ;;
  esac
fi

# ── Prompt for app name if missing ────────────────────────────────────────────

if [ -z "$APP_NAME" ]; then
  printf "  App name (replaces [APP_NAME] in template): "
  read -r APP_NAME
fi

# ── Generate ──────────────────────────────────────────────────────────────────

echo "Generating $AI config (platform: $PLATFORM)..."

# Substitute placeholders
sed \
  -e "s/\[APP_NAME\]/${APP_NAME:-MyApp}/g" \
  -e "s/\[PLATFORM\]/$PLATFORM/g" \
  "$TEMPLATE" > "$OUTPUT"

echo "  wrote  $OUTPUT"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "Done. $AI is configured for $PLATFORM."
echo ""
case "$AI" in
  copilot)
    echo "Next steps:"
    echo "  1. Review .github/copilot-instructions.md"
    echo "  2. git add .github/copilot-instructions.md && git commit -m 'chore: add copilot instructions'"
    ;;
  gemini)
    echo "Next steps:"
    echo "  1. Review GEMINI.md — Gemini will auto-import .claude/reference/ files via @import"
    echo "  2. git add GEMINI.md && git commit -m 'chore: add gemini instructions'"
    ;;
esac
