# Fix Branch Delegation Guard Gap

> Date: 2026-04-16
> Type: Improvement
> Related: [04-delegation-guard-hook.md](./04-delegation-guard-hook.md), [06-delegation-guard-autonomous-resolution.md](./06-delegation-guard-autonomous-resolution.md)
> Sessions analysed: xpnsio split-bill-ui-bugs #93 (2026-04-16, session 6edff413), xpnsio skeleton-w-full-all-screens #91 (2026-04-16, session da14b1ad)
> Perf reports: [xpnsio-2026-04-16-6edff413-split-bill-ui-bugs](../perf-report/xpnsio-2026-04-16-6edff413-split-bill-ui-bugs.md), [xpnsio-2026-04-16-da14b1ad-skeleton-w-full-all-screens](../perf-report/xpnsio-2026-04-16-da14b1ad-skeleton-w-full-all-screens.md)

## Trigger

Two back-to-back xpnsio sessions on 2026-04-16 both scored Fair (6.7/10 and 6.0/10) with the same core violation: inline edits to feature directory files without delegating to feature-orchestrator.

- **Issue #93** (split-bill-ui-bugs) — main agent performed 4 direct `Edit` calls to `SplitBillFormView.tsx` and `page.tsx` after spawning `debug-orchestrator`. Branch: `fix/issue-093-split-bill-ui-bugs`.
- **Issue #91** (skeleton-w-full-all-screens) — 8 UI view files edited entirely inline, `feature-orchestrator` never spawned. Branch: `fix/issue-091-skeleton-w-full-all-screens`.

Both violations were on `fix/*` branches. Both should have been blocked by `require-feature-orchestrator.sh` — but weren't.

---

## Root Cause Analysis

The branch guard in `require-feature-orchestrator.sh` used an allowlist pattern:

```bash
if [[ "$BRANCH" != feat/* && "$BRANCH" != feature/* ]]; then
  exit 0
fi
```

This only enforced delegation on `feat/*` and `feature/*` branches. Any other branch prefix — including `fix/*`, `chore/*`, `refactor/*` — bypassed the hook entirely. Since issue-worker creates `fix/issue-NNN-*` branches for bug fixes, every bug fix session was unguarded.

The flaw is in the framing: the hook assumed "feature branches need delegation" rather than "all work branches need delegation." The correct invariant is that `src/` edits should always go through feature-orchestrator unless we're on a trunk branch (`main` or `develop`) where direct edits are expected.

---

## Changes Made

### Updated: `lib/core/hooks/require-feature-orchestrator.sh`

Replaced the allowlist branch pattern with a blocklist:

```bash
# Before
if [[ "$BRANCH" != feat/* && "$BRANCH" != feature/* ]]; then
  exit 0
fi

# After
if [[ "$BRANCH" == "main" || "$BRANCH" == "develop" ]]; then
  exit 0
fi
```

This means any branch that is not `main` or `develop` will trigger the delegation check when editing a feature directory file. Covers `fix/*`, `feat/*`, `feature/*`, `chore/*`, `refactor/*`, and any future naming conventions without needing to enumerate them.

---

## Downstream Impact

The hook is a core asset (`lib/core/hooks/`) and is symlinked into downstream projects via `setup-symlinks.sh` / `setup-packages.sh`. Projects that have already run setup will pick up the change automatically on their next Claude Code session start (the hook is read at execution time, not cached). No re-sync needed.

---

## Open Questions

1. **Worker identity in hook** (carried from Entry 06, 07) — the hook still cannot distinguish a worker `Edit` (legitimate, inside worktree) from a root-agent `Edit` (violation). The `fix/*` guard gap masked this: now that all work branches are covered, a correctly delegated fix session will also hit the hook and require a valid `delegation.json` entry. This is the correct behavior, but it means the feature-orchestrator (or debug-orchestrator) must reliably write the delegation entry at session start. Worth monitoring in upcoming perf reports.

2. **debug-orchestrator delegation entry** — `require-feature-orchestrator.sh` checks for a delegation entry keyed by branch slug. The feature-orchestrator writes this entry. It is unclear whether debug-orchestrator also writes it — if not, a correctly delegated debug session will still be blocked. This should be verified.
