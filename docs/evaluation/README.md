# Agentic Evaluation

A serialized log of observations, investigations, and improvements specific to the **[software-dev-agentic](https://github.com/handharr-labs/software-dev-agentic)** repository — tracking how this toolkit evolves against the [Core Design Principles](https://jurnal.atlassian.net/wiki/spaces/~611df3da650a26006e44928d/pages/51126370416) and [Shared Submodule Architecture](https://jurnal.atlassian.net/wiki/spaces/~611df3da650a26006e44928d/pages/51129909710).

Each entry is numbered in sequence. Entries may be:
- **Observation** — something noticed, not yet acted on
- **Investigation** — deeper analysis of a problem
- **Improvement** — a change made and its outcome

---

## Log

| # | Title | Type | Date | Principles Touched | Status |
|---|-------|------|------|--------------------|--------|
| 01 | [Token Optimization](./01-token-optimization.md) | Investigation | 2026-04-10 | P4, P7, P8, P9 | In progress |
| 02 | [Context Efficiency — Round 2](./02-context-efficiency-round-2.md) | Improvement | 2026-04-13 | P4, P7, P8 | Done |
| 03 | [Worker Routing and Validation Loop](./03-worker-routing-and-validation.md) | Improvement | 2026-04-13 | D2, D6, D7 | Done |
| 04 | [Delegation Guard Hook](./04-delegation-guard-hook.md) | Improvement | 2026-04-13 | D2, D6 | Done |
| 05 | [Delegation Flag TTL and Orchestrator Read Efficiency](./05-flag-ttl-and-read-efficiency.md) | Improvement | 2026-04-13 | D1, D4, D6 | Done |
| 06 | [Delegation Guard — Autonomous Resolution and Worktree Isolation](./06-delegation-guard-autonomous-resolution.md) | Improvement | 2026-04-14 | D1, D2, D6 | Done |
| 07 | [Orchestrator Read Discipline and Worktree Isolation at Invocation](./07-orchestrator-read-discipline-and-invocation-isolation.md) | Improvement | 2026-04-14 | D1, D2, D4 | Done |
| 08 | [Fix Branch Delegation Guard Gap](./08-fix-branch-delegation-guard-gap.md) | Improvement | 2026-04-16 | D2, D6 | Done |

---

## How to Add an Entry

1. Create `docs/evaluation/NN-short-title.md` (next number in sequence)
2. Add a row to the Log table above
3. Use the header format:

```
> Date: YYYY-MM-DD
> Type: Observation | Investigation | Improvement
> Related: link to previous entry if continuing a thread
```
