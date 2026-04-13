# Context Efficiency — Round 2 Investigation

> Date: 2026-04-13
> Type: Investigation
> Related: [01-token-optimization.md](./01-token-optimization.md)
> Sessions analysed: Issue #73 / xpnsio split-bill MVP (2026-04-12, 6.4/10)

## Trigger

Entry 01 applied five fixes on 2026-04-11. The xpnsio split-bill session (Issue #73, 2026-04-12) is the first real-world data point after those fixes. The session produced a complete 34-file, 5-layer feature. Results were good on output quality — but D4 (Token Efficiency) scored 4/10, identical to the pre-fix sessions in Entry 01.

Additionally, an external strategies document ("Token Efficiency Strategies for Local Agentic Architectures") was reviewed against the current architecture to identify any uncovered gaps.

---

## Session Data — Issue #73 (xpnsio split-bill MVP)

| Metric | Value | Signal |
|--------|-------|--------|
| Duration | ~12 hours | Long session — possible mid-run context loss |
| Cache hit ratio | 97.1% | Excellent — caching layer is working |
| Billed approx | ~498K tokens | High absolute cost despite good cache |
| Avg billed / turn | ~2,848 | Reasonable per-turn, high total due to 175 turns |
| read_grep_ratio | **25** (0 Grep, 25 Read) | **P7 violation — fix from 01 not sticking** |
| Duplicate reads | 2 | `temp-dir/prd-split-bill.md` read twice |
| Workers spawned | feature-orchestrator ✓ | Correct delegation pattern used |
| skill_calls | `[]` | Workers bypassed — agents spawned directly |

---

## Findings

### Finding 1 — P7 Fix Not Sticking: 0 Grep Calls (Critical)

Entry 01 added `Grep before Read` to all workers on 2026-04-11. The split-bill session on 2026-04-12 still shows 0 Grep calls. The rule exists in the prompt but isn't actionable enough — it reads as a guideline, not a decision gate.

Root cause: the current wording is a bullet under "Search Rules." There is no concrete decision table telling the agent *when* to Grep vs when to Read. Under token pressure or when file paths are already known, the agent defaults to Read.

### Finding 2 — presentation-worker Returns Content, Not a Path (P8 Violation)

`presentation-worker` line 49 explicitly instructs the worker to return the full StateHolder contract to the orchestrator:

```
Return created/updated file paths **and the complete StateHolder contract**:
- StateHolder class/hook name and file path
- State fields (what the UI renders)
- Event/Action cases
- Navigator/coordinator protocol name and methods
- DI factory method or binding key
```

This was designed to avoid `ui-worker` re-reading files. But it passes rich structured content through the orchestrator's context window, which violates P8 (Orchestrators Coordinate, Not Execute). By Phase 4, the orchestrator is holding the StateHolder contract in addition to file path lists from all prior phases.

The blackboard pattern requires the orchestrator to hold *pointers*, not *content*.

### Finding 3 — No Orchestrator State File → Duplicate Artifact Reads

The duplicate PRD read (`temp-dir/prd-split-bill.md` read twice) is a direct symptom of the orchestrator having no persistence layer. In a 12-hour session, the orchestrator's rolling context eventually drops earlier artifacts — causing re-reads of files it already processed.

Entry 01 fixed duplicate reads between orchestrator and workers (P8/P9 fix). This is a different problem: the orchestrator re-reading its own inputs across a long session because there is no state checkpoint.

---

## Design Principles Alignment

| Principle | Finding | Status |
|-----------|---------|--------|
| **P7 — Three-Tier Knowledge** (Grep-first) | Fix applied 2026-04-11 but session shows 0 Grep calls | ⚠️ Regression — rule not strong enough |
| **P8 — Orchestrators Coordinate, Not Execute** | `presentation-worker` returns StateHolder content, not a path | ❌ Violation — open |
| **P4 — Context Isolation** | No state file → orchestrator re-reads its own artifacts | ❌ Gap — open |

---

## External Strategy Review

Compared against "Token Efficiency Strategies for Local Agentic Architectures" (three strategies: Blackboard Pattern, Ephemeral Workers, Amnesic Orchestrator):

| Strategy | In repo? | Gap |
|----------|----------|-----|
| Blackboard / pointer passing | Mostly yes — orchestrator enforces path-only handoffs | presentation→ui is the one violation (Finding 2) |
| Ephemeral spawn-and-die workers | Yes — `isolation: worktree` enforces this | No gap |
| Amnesic orchestrator / state file | No | Finding 3 — no state persistence, mid-run re-reads occur |

One additional strategy not covered in the external doc: **skill atomicity as a context bound**. Because skills are single-purpose and each worker invokes exactly one skill per task, workers only load the reference sections relevant to that skill. This is the main per-worker context control — worth preserving explicitly as a design constraint.

---

## Recommended Fixes

### A. Rewrite Grep-before-Read as a Decision Gate (P7) — Highest Impact

Replace the current `Search Rules` bullet with an explicit decision table. The agent must not branch to `Read` without first asking whether a Grep would suffice.

**Proposed wording for all workers:**

```markdown
## Search Protocol — Never Violate

Before any Read call, answer: "Do I need the full file, or just a specific symbol/section?"

| What you need | Tool to use |
|---|---|
| A specific class, function, or type | `Grep` for the name |
| A section of a reference doc | `Grep` for the section heading |
| The full file structure (e.g. for style-matching a new file) | `Read` — justified |
| Confirmation a file exists | `Glob` |

Read a full file only when: (a) you need its complete structure to write a new matching file, or (b) Grep returned no results.
```

### B. Handoff File for presentation → ui (P8)

`presentation-worker` should write the StateHolder contract to a file, not return it as prose.

1. Worker writes `.claude/runs/<feature>/stateholder-contract.md` containing the contract
2. Worker returns only the file path to the orchestrator
3. `feature-orchestrator` passes the path (not the content) to `ui-worker`
4. `ui-worker` reads the contract directly from disk

The "don't re-read" benefit is preserved. Orchestrator stays lean.

### C. Orchestrator State File (P4)

`feature-orchestrator` writes a checkpoint after each phase:

```json
{
  "feature": "<name>",
  "completed_phases": ["domain", "data"],
  "artifacts": {
    "prd": "<path>",
    "domain": ["<path>", ...],
    "data": ["<path>", ...]
  },
  "next_phase": "presentation"
}
```

Written to `.claude/runs/<feature>/state.json`. If the session runs long and the orchestrator loses earlier context, it reads the state file rather than re-reading source artifacts.

### D. Standardized `## Output` Section for All Workers (Parsing Reliability)

Workers currently return file paths embedded in prose. Define a strict output section all workers must end with:

```markdown
## Output
- path/to/created/file1
- path/to/created/file2
```

The orchestrator extracts paths from this section only — no prose parsing, no ambiguity. This makes state file writes in Fix C reliable.

---

## Priority

| # | Fix | Principle | Evidence |
|---|-----|-----------|----------|
| 1 | Rewrite Search Protocol as decision gate | P7 | 0 Grep / 25 Read post-fix | ✅ Applied 2026-04-13 |
| 2 | Standardized `## Output` section | P8 | Needed for Fix 3 to be reliable | ✅ Applied 2026-04-13 |
| 3 | Orchestrator state file | P4 | Duplicate PRD read in 12h session | ✅ Applied 2026-04-13 |
| 4 | Handoff file for pres→ui | P8 | Content passed through orchestrator | ✅ Applied 2026-04-13 |

---

## Open Items from Entry 01

- Structural split of `reference/data.md` (529 lines) and `reference/utilities.md` (487 lines) — still open, medium impact
