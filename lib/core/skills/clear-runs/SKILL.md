---
name: clear-runs
description: Remove all orchestrator run state from .claude/runs/. Clears stale state.json and stateholder-contract.md artifacts left by feature-orchestrator, pres-orchestrator, and other orchestrators.
user-invocable: true
tools: Bash
---

Remove all run state artifacts from `.claude/runs/`.

## What this clears

`.claude/runs/` holds per-feature orchestrator state written during a session:
- `state.json` — completed phases and artifact paths
- `stateholder-contract.md` — shared context passed between workers

Stale entries from completed or abandoned sessions accumulate here and can cause orchestrators to skip phases they've already recorded as done, even in a fresh session on a new feature.

## Steps

1. Find the project root:
```bash
git rev-parse --show-toplevel
```

2. List what will be removed (show the user before deleting):
```bash
ls "$PROJECT_ROOT/.claude/runs/" 2>/dev/null || echo "(runs/ is already empty)"
```

3. Ask the user to confirm if any entries are listed. If the directory is already empty, report that and stop.

4. Remove all run subdirectories:
```bash
rm -rf "$PROJECT_ROOT/.claude/runs"/*/
```

5. Confirm the directory is now empty:
```bash
ls "$PROJECT_ROOT/.claude/runs/" && echo "(done)" || echo "(done — runs/ is now empty)"
```

Report how many entries were removed.

## Note

This does not touch `.claude/.delegated-*` flags or `.claude/.session-id`. Those are managed by the `require-feature-orchestrator` hook automatically.
