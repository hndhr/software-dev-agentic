#!/usr/bin/env bash
# sync.sh
# Pull the latest web-agentic updates and re-run symlink setup.
# Run from the project root whenever you want to adopt new agents/skills.
#
# Usage:
#   .claude/web-agentic/scripts/sync.sh
#
# What it does:
#   1. git pull inside the submodule
#   2. Re-runs setup-symlinks.sh (link_if_absent is idempotent — safe to re-run)
#   3. Reminds you to commit the updated submodule pointer

set -euo pipefail

SUBMODULE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$SUBMODULE/../.." && pwd)"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
TEMPLATE="$SUBMODULE/CLAUDE-template.md"
BEGIN_MARKER="<!-- BEGIN web-agentic -->"
END_MARKER="<!-- END web-agentic -->"

echo "Pulling latest web-agentic..."
git -C "$SUBMODULE" pull

echo ""
echo "Re-running symlink setup..."
"$SUBMODULE/scripts/setup-symlinks.sh"

# ── Sync managed section in CLAUDE.md ────────────────────────────────────────

echo ""
if [ ! -f "$CLAUDE_MD" ]; then
  echo "skip  CLAUDE.md sync (file not found — run setup-symlinks.sh first)"
elif ! grep -qF "$BEGIN_MARKER" "$CLAUDE_MD"; then
  echo "skip  CLAUDE.md sync (no managed section markers found — add them manually)"
  echo "      Markers: $BEGIN_MARKER ... $END_MARKER"
else
  # Extract the managed block from the template (inclusive of markers)
  managed="$(awk "/$BEGIN_MARKER/{found=1} found{print} /$END_MARKER/{found=0}" "$TEMPLATE")"

  # Replace the managed block in CLAUDE.md using awk
  awk -v block="$managed" \
    -v begin="$BEGIN_MARKER" \
    -v end="$END_MARKER" \
    'BEGIN{skip=0}
     $0 == begin { print block; skip=1; next }
     $0 == end   { skip=0; next }
     !skip        { print }
    ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"

  echo "sync  CLAUDE.md (managed section updated)"
fi

echo ""
echo "Submodule updated. To lock in this version:"
echo "  git add .claude/web-agentic"
echo "  git commit -m 'chore: bump web-agentic to $(git -C "$SUBMODULE" rev-parse --short HEAD)'"
