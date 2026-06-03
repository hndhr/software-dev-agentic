#!/usr/bin/env bash
# Seed ChromaDB from lib/core/knowledge/ and distribute to all platform caches.
# Skips if .version matches the current knowledge tree hash.
# Dashboard writes "dashboard:{timestamp}" to .version — treated as fresh.
#
# Usage:
#   bash scripts/seed-kms.sh          # skip if already current
#   bash scripts/seed-kms.sh --force  # re-seed regardless

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KNOWLEDGE_DIR="$REPO_ROOT/lib/core/knowledge"
SEEDS_DIR="$REPO_ROOT/dist/.kms_seeds"
SHARED_CHROMA="$SEEDS_DIR/.shared/chroma"
VERSION_FILE="$SEEDS_DIR/.version"

FORCE=false
[ "${1:-}" = "--force" ] && FORCE=true

# ── Preflight ──────────────────────────────────────────────────────────────────

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 not found — install Python 3 to use KMS seeding."
  exit 1
fi

if ! python3 -c "import chromadb, yaml" 2>/dev/null; then
  echo "Installing KMS dependencies (one-time)..."
  pip3 install -q -r "$REPO_ROOT/kms/requirements.txt" \
    || { echo "ERROR: pip install failed. Run: pip install chromadb PyYAML"; exit 1; }
fi

# ── Version check ──────────────────────────────────────────────────────────────

current_hash="$(git -C "$REPO_ROOT" rev-parse HEAD:lib/core/knowledge 2>/dev/null || echo "unknown")"
stored_version="$(cat "$VERSION_FILE" 2>/dev/null || echo "")"

if [ "$FORCE" = false ]; then
  if [[ "$stored_version" == "git:$current_hash" ]]; then
    echo "KMS seed is current (${current_hash:0:12}…) — nothing to do."
    echo "Use --force to re-seed anyway."
    exit 0
  fi
  if [[ "$stored_version" == dashboard:* ]]; then
    echo "KMS seed was last updated by dashboard (${stored_version}) — skipping file-based reseed."
    echo "Use --force to overwrite dashboard changes with file-based seed."
    exit 0
  fi
fi

# ── Seed (once, shared) ────────────────────────────────────────────────────────

echo "Seeding from lib/core/knowledge/ ..."
echo "  hash: $current_hash"

mkdir -p "$(dirname "$SHARED_CHROMA")"
rm -rf "$SHARED_CHROMA"

PYTHONPATH="$REPO_ROOT" python3 -m kms.scripts.seed_kms \
  --knowledge-dir "$KNOWLEDGE_DIR" \
  --db-path "$SHARED_CHROMA" 2>&1 | sed 's/^/  /'

# ── Distribute to per-platform caches ─────────────────────────────────────────

# Platforms = all dirs under lib/core/knowledge/ that aren't the flutter base,
# plus any existing plugin dirs not already covered.
platforms=()

for dir in "$KNOWLEDGE_DIR"/*/; do
  name="$(basename "$dir")"
  [ "$name" != "flutter" ] && platforms+=("$name")
done

if [ -d "$REPO_ROOT/dist/plugins" ]; then
  for dir in "$REPO_ROOT/dist/plugins"/*/; do
    name="$(basename "$dir")"
    # Skip if already in list
    already=false
    for p in "${platforms[@]:-}"; do [ "$p" = "$name" ] && already=true && break; done
    $already || platforms+=("$name")
  done
fi

echo ""
echo "Distributing to ${#platforms[@]} platform caches..."

for platform in "${platforms[@]}"; do
  cache_dir="$SEEDS_DIR/$platform"
  mkdir -p "$cache_dir"
  rm -rf "$cache_dir/chroma"
  cp -r "$SHARED_CHROMA" "$cache_dir/chroma"
  echo "$current_hash" > "$cache_dir/.tree"
  echo "  $platform  cached"
done

# ── Write global version marker ────────────────────────────────────────────────

mkdir -p "$SEEDS_DIR"
echo "git:$current_hash" > "$VERSION_FILE"

echo ""
echo "Done — version: git:${current_hash:0:12}…"
echo "  dist/.kms_seeds/.version updated"
echo "  Run 'bash scripts/build-plugin.sh --platform=all' to push into plugins."
