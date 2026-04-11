#!/usr/bin/env bash
# sync.sh
# Pull the latest software-dev-agentic updates and re-run symlink setup.
# Run from the project root whenever you want to adopt new agents/skills.
#
# Usage:
#   .claude/software-dev-agentic/scripts/sync.sh --platform=web
#   .claude/software-dev-agentic/scripts/sync.sh --platform=ios

set -euo pipefail

SUBMODULE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$SUBMODULE/../.." && pwd)"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"

# ── Parse --platform ─────────────────────────────────────────────────────────

PLATFORM=""
for arg in "$@"; do
  case "$arg" in
    --platform=*) PLATFORM="${arg#--platform=}" ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "Error: --platform is required."
  echo "Usage: $0 --platform=web|ios|flutter"
  exit 1
fi

TEMPLATE="$SUBMODULE/platforms/$PLATFORM/CLAUDE-template.md"
BEGIN_MARKER="<!-- BEGIN software-dev-agentic:$PLATFORM -->"
END_MARKER="<!-- END software-dev-agentic:$PLATFORM -->"

echo "Pulling latest software-dev-agentic..."
git -C "$SUBMODULE" pull

echo ""
echo "Re-running symlink setup..."
"$SUBMODULE/scripts/setup-symlinks.sh" --platform="$PLATFORM"

# ── Sync managed section in CLAUDE.md ────────────────────────────────────────

echo ""
if [ ! -f "$CLAUDE_MD" ]; then
  echo "skip  CLAUDE.md sync (file not found — run setup-symlinks.sh first)"
elif ! grep -qF "$BEGIN_MARKER" "$CLAUDE_MD"; then
  echo "skip  CLAUDE.md sync (no managed section markers found)"
  echo "      Add: $BEGIN_MARKER ... $END_MARKER"
elif [ ! -f "$TEMPLATE" ]; then
  echo "skip  CLAUDE.md sync (no CLAUDE-template.md for platform $PLATFORM)"
else
  managed_tmp="$(mktemp)"
  awk "/^${BEGIN_MARKER}$/{found=1} found{print} /^${END_MARKER}$/{found=0}" "$TEMPLATE" > "$managed_tmp"

  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v src="$managed_tmp" '
    $0 == begin { while ((getline line < src) > 0) print line; skip=1; next }
    $0 == end   { skip=0; next }
    !skip        { print }
  ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"

  rm -f "$managed_tmp"
  echo "sync  CLAUDE.md (managed section updated)"
fi

echo ""
echo "Submodule updated. To lock in this version:"
echo "  git add .claude/software-dev-agentic"
echo "  git commit -m 'chore: bump software-dev-agentic to $(git -C "$SUBMODULE" rev-parse --short HEAD)'"
