#!/usr/bin/env bash
# Hook: Require delegation to feature-orchestrator for feature directory edits on feat/* branches
# Event: PreToolUse on Write|Edit
# Input: JSON on stdin with keys: session_id, tool_name, tool_input
#
# Config: CLAUDE.md ## Feature Directories section (fenced code block) in project root.
# Flag:   .claude/agentic-state/.delegated-<branch-slug> — created by feature-orchestrator at session start,
#         cleared at end. Session-scoped: a new session_id wipes all stale flags automatically.
# Session: .claude/agentic-state/.session-id — tracks the active session; updated on session boundary.
#
# Block condition: feat/* or feature/* branch + file matches a feature dir + no delegation flag

set -euo pipefail

INPUT=$(cat)

TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)

if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  exit 0
fi

# Session boundary detection — wipe stale delegation flags when session_id changes
PROJECT_ROOT_EARLY=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -n "$PROJECT_ROOT_EARLY" ]]; then
  CURRENT_SESSION=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || true)
  SESSION_FILE="$PROJECT_ROOT_EARLY/.claude/agentic-state/.session-id"
  if [[ -n "$CURRENT_SESSION" ]]; then
    STORED_SESSION=$(cat "$SESSION_FILE" 2>/dev/null || true)
    if [[ "$CURRENT_SESSION" != "$STORED_SESSION" ]]; then
      # New session — clear all delegation flags from previous session
      rm -f "$PROJECT_ROOT_EARLY"/.claude/agentic-state/.delegated-* 2>/dev/null || true
      echo "$CURRENT_SESSION" > "$SESSION_FILE"
    fi
  fi
fi

# Not a feat/* or feature/* branch — allow
BRANCH=$(git branch --show-current 2>/dev/null || true)
if [[ "$BRANCH" != feat/* && "$BRANCH" != feature/* ]]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); ti=d.get('tool_input',{}); print(ti.get('file_path', ti.get('path','')))" 2>/dev/null || true)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Parse feature directories from CLAUDE.md ## Feature Directories section
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  exit 0
fi

FEATURE_DIRS=$(python3 - "$CLAUDE_MD" <<'EOF'
import sys, re

content = open(sys.argv[1]).read()
match = re.search(r'## Feature Directories\s+```\s*(.*?)\s*```', content, re.DOTALL)
if match:
    for line in match.group(1).splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            print(line)
EOF
)

if [[ -z "$FEATURE_DIRS" ]]; then
  exit 0
fi

# Check if file path matches a feature directory fragment
IS_FEATURE_FILE=false
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  if [[ "$FILE_PATH" == *"$dir"* ]]; then
    IS_FEATURE_FILE=true
    break
  fi
done <<< "$FEATURE_DIRS"

if [[ "$IS_FEATURE_FILE" == false ]]; then
  exit 0
fi

# Delegation flag set — allow if present and fresh (< 4h); treat stale flag as missing
BRANCH_SLUG=$(echo "$BRANCH" | tr '/' '-')
FLAG_FILE="$PROJECT_ROOT/.claude/agentic-state/.delegated-$BRANCH_SLUG"
if [[ -f "$FLAG_FILE" ]]; then
  FLAG_TIME=$(cat "$FLAG_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  AGE=$((NOW - FLAG_TIME))
  if [[ "$AGE" -lt 14400 ]]; then
    exit 0
  fi
  # Stale flag (> 4h) — fall through to block
fi

# Block — agent must stop and surface to user; must not resolve autonomously
echo "BLOCKED: Feature directory edit on feat/* or feature/* branch requires delegation."
echo ""
echo "  Branch : $BRANCH"
echo "  File   : $FILE_PATH"
echo "  Flag   : $FLAG_FILE (not found or stale > 4h)"
echo ""
echo "STOP. Do not proceed. Do not create the flag. Do not choose an option autonomously."
echo "Tell the user this edit was blocked and ask them how to proceed:"
echo "  - Inline: user must explicitly say to proceed inline"
echo "  - Delegate: invoke feature-orchestrator (recommended)"
exit 2
