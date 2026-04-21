# Worker Routing and Validation Loop

> Date: 2026-04-13
> Type: Improvement
> Related: [02-context-efficiency-round-2.md](./02-context-efficiency-round-2.md)
> Sessions analysed: Issue #73 / xpnsio split-bill MVP (2026-04-13, 5.7/10)

## Trigger

A new perf report for Issue #73 (xpnsio split-bill MVP, 2026-04-13 session) scored 5.7/10 overall — lower than the previous round. The D4 (Token Efficiency) regression from Entry 02 was partially addressed, but two new failure modes appeared: workers were not invoked at all (D2 3/10), and TypeScript validation ran as a 17-step loop instead of a bounded pass (D7).

The session also revealed a routing gap: `feature-orchestrator` was not triggered because the user was **updating** a feature, not creating one.

---

## Session Data — Issue #73 (xpnsio split-bill MVP, 2026-04-13)

| Metric | Value | Signal |
|--------|-------|--------|
| Duration | ~65 min | Moderate session |
| Cache hit ratio | 96.1% | Excellent |
| Billed approx | ~490K tokens | Acceptable |
| Avg billed / turn | ~3,739 | Elevated — main-context work without workers |
| read_grep_ratio | 12.0 (2 Grep, 24 Read) | High — but main-context, not workers |
| Workers spawned | None | D2 failure — no orchestrator or workers used |
| Bash calls | 18 (17× `npx tsc --noEmit`) | D7 failure — iterative TS error loop |
| PR created | No | D6 gap — session ended without `gh pr create` |

---

## Findings

### Finding 1 — Feature-Orchestrator Not Triggered on Update (D2, Critical)

The `feature-orchestrator` description only listed create/add/implement/scaffold as trigger verbs:

```
Invoke when asked to create, add, implement, or scaffold a new feature...
```

When the user was updating an existing feature, the router did not match this agent. Claude worked inline across domain, data, and presentation layers — no workers, no layer isolation, no Search Protocol enforcement.

Root cause: the description acts as the routing signal. Missing verbs = missed route.

### Finding 2 — No Layer Scoping for Update Scenarios (D2)

Even if `feature-orchestrator` had been triggered, Phase 0 only asked "which layers already exist? Skip those." For an update scenario, the correct question is "which layers need changes?" — the existing layer check is inverted and ambiguous for partial updates.

### Finding 3 — TypeScript Validation Loop (D7)

17 of 18 Bash calls were `npx tsc --noEmit` variants with varying truncation flags (`head -60`, `head -80`, `tail -40`, `tail -50`). The agent was iteratively chasing errors — run, see some errors, fix, run again — rather than capturing the full output once and resolving everything in a single pass.

No worker or orchestrator file contained guidance on how to run type checks. The loop pattern emerged from the absence of any constraint.

### Finding 4 — No PR at Session End (D6)

Phase 5 of `feature-orchestrator` only said "report files grouped by layer, suggest next step." No instruction to open a PR. The session ended with the branch un-PR'd.

---

## Fixes Applied

### Fix 1 — Expand Feature-Orchestrator Description (Finding 1)

Added `update, modify, extend` to the description trigger list:

```
Build or update a feature across Clean Architecture layers. Invoke when asked to
create, add, implement, scaffold, update, modify, or extend a feature, screen, or module.
```

### Fix 2 — New or Update? Question in Phase 0 (Finding 2)

Replaced "which layers already exist?" with an explicit branch:

```
New or update?
- New → ask which layers to create (default: all)
- Update → ask which layers need changes; skip all others
```

### Fix 3 — Validation Protocol in All Workers (Finding 3)

Added a `## Validation Protocol` section to `domain-worker`, `data-worker`, and `presentation-worker`:

```
After writing all files, run the project's type checker once:
- Capture the full output — do not truncate
- Fix all reported errors in a single pass
- Run the type checker once more to confirm clean
- Never loop more than twice — if errors persist, surface them to the user
```

### Fix 4 — PR Creation in Phase 5 (Finding 4)

Replaced the Phase 5 summary step with a structured wrap-up:

```
1. Report all created/modified files grouped by layer.
2. Run `gh pr create` if no open PR exists for this branch.
3. Suggest next step (e.g. tests).
```

---

## Principles Alignment

| Finding | Fix | D-Dimension | Status |
|---------|-----|-------------|--------|
| Orchestrator not triggered on updates | Expand description verbs | D2 | ✅ Applied 2026-04-13 |
| All layers re-run for update scope | Phase 0 "new or update?" branch | D2 | ✅ Applied 2026-04-13 |
| 17-step TSC loop | Validation Protocol in workers | D7 | ✅ Applied 2026-04-13 |
| No PR at session end | Phase 5 wrap-up with `gh pr create` | D6 | ✅ Applied 2026-04-13 |

---

## Open Items

- D4 (read:grep ratio) — workers have Search Protocol; will validate in next session whether the ratio improves when workers are properly invoked
- D6 (no git staging before PR) — not explicitly addressed; workers do not currently have a commit step; low priority as `gh pr create` from a clean worktree is sufficient
