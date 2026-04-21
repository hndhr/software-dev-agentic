# Token Optimization — Journey Observation

> Date: 2026-04-10 (updated 2026-04-11, fixes applied 2026-04-11)
> Context: web-agentic is productive enough to close 3–5 issues per 5-hour Claude Code session, but that productivity is accelerating token consumption to unsustainable levels. This doc investigates where tokens drain and maps findings against the [Core Design Principles](https://jurnal.atlassian.net/wiki/spaces/~611df3da650a26006e44928d/pages/51126370416).
> Sessions analysed: Issue #53 (2026-04-11, 6.3/10) · Issue #26 (2026-04-10, 7.0/10)

## Design Principles Alignment Check

Before fixing anything, map findings against the principles to understand whether this is a _violation_ or a _gap in the current implementation_.

| Principle | What It Says | Current State | Gap? |
|-----------|-------------|---------------|------|
| **P4 — Context Isolation** | Workers run in isolated context windows. Main session only sees the result. | ✅ Workers do run isolated | Isolation is correct but each worker still pays the full reference doc cost independently |
| **P5 — Preloaded Skills** | Monitor total preloaded size — if it exceeds ~500 lines, split the agent | ✅ Skills not overloaded | Reference docs (not skills) are the bloat — separate problem |
| **P7 — Three-Tier Knowledge** | Skills reference Tier 3 files with _precise section pointers_, never embed content | ✅ Fixed — Grep-first rule added to all workers; Reference lines now mandate Grep before Read | Was: workers loaded full reference files |
| **P9 — Delegation Threshold** | If it takes fewer tokens to DO than to DELEGATE, do it directly | ✅ Fixed — Phase 2 reads removed from both orchestrators | Was: orchestrator Phase 2 reads duplicated what workers already do |
| **P8 — Orchestrators Coordinate, Not Execute** | Orchestrators gather input, spawn workers — workers execute | ✅ Fixed — orchestrators now pass only file path lists, not file contents | Was: orchestrators accumulated codebase reads across all phases |

**Summary:** P7, P8, and P9 violations are now fixed. Real session data confirmed both violations with measurable ratios (see Empirical Evidence below) before fixes were applied on 2026-04-11.

---

## Identified Drains

### 1. Reference Docs — Biggest Culprit (4,523 lines total)

| File | Lines |
|------|-------|
| `reference/data.md` | 529 |
| `reference/utilities.md` | 487 |
| `reference/presentation.md` | 405 |
| `reference/project.md` | 391 |
| `reference/domain.md` | 349 |
| `reference/database.md` | 343 |
| `reference/modular.md` | 260 |
| `reference/testing.md` | 232 |
| `reference/server-actions.md` | 227 |

Workers read from `reference/` before writing code. When 3 workers run sequentially inside one orchestrator, the same docs are potentially loaded 3× into separate contexts.

### 2. Orchestrator Accumulates Everything

`feature-orchestrator` spawns domain → data → presentation workers sequentially. The orchestrator receives each worker's output and passes it to the next — so by Phase 4 its context holds all three workers' outputs.

### 3. Duplicate File Reads — Orchestrator AND Workers Read the Same Files ✅ Fixed

Files were read twice: once by the orchestrator in Phase 2, then again by the worker in its own workflow step.

**`feature-orchestrator` Phase 2 reads (now removed):**
| File | Was also read by |
|------|-------------|
| `Glob: src/domain/entities/*.ts` | `domain-worker` step 3 |
| `Read: src/di/container.client.ts` | `presentation-worker` step 3 |
| `Read: src/presentation/navigation/routes.ts` | `presentation-worker` step 3 |
| `Glob: src/data/dtos/*.ts` | _(only orchestrator — orphaned read)_ |

**`backend-orchestrator` Phase 2 reads (now removed):**
| File | Was also read by |
|------|-------------|
| `Glob: src/data/repositories/*DbRepositoryImpl.ts` | `data-worker` step 3 |
| `Glob: src/data/mappers/db/DbErrorMapper.ts` | `data-worker` step 3 |

Fix: Phase 2 removed from both orchestrators. Workers own their own context reads. Orchestrators now pass only created file paths between workers.

### 4. Reference Doc Load per Worker ✅ Partially Fixed

Workers reference large docs via a `Reference:` pointer at the bottom of each agent file. Previously, agents would read these docs in full.

| Worker | Reference docs | Total lines |
|--------|----------------------|-------------|
| `domain-worker` | `reference/domain.md` | 349 |
| `data-worker` | `reference/data.md` + `reference/database.md` | 872 |
| `presentation-worker` | `reference/presentation.md` + `reference/server-actions.md` + `reference/di.md` + `reference/navigation.md` | 632+ |
| `test-worker` | `reference/testing.md` | 232 |

A full `feature-orchestrator` run (domain → data → presentation) loads ~1,853 lines of reference docs across three sub-agent contexts. These are fresh contexts, so the docs aren't shared — each worker pays the full cost independently.

Fix applied: all worker `Reference:` lines now mandate `Grep` for the relevant section before `Read`. Full splitting of the reference docs (fix C) remains open — see Recommended Fixes.

### 5. Inline Execution for Large Multi-Layer Features (P9 Violation) — Behavioural

Issue #53 implemented a 44-file feature spanning 5 architectural layers entirely inline — no workers spawned. Per P9, when a task touches more than 3 layers it should be delegated to a `feature-orchestrator`. Inline execution accumulates all writes in the main session context, driving avg billed/turn up to ~3,412.

Issue #26 correctly spawned `feature-orchestrator` but with `isolation: ""` — worktree isolation would have prevented context bleed.

Fix applied: `feature-orchestrator` now mandates `isolation: worktree` in its delegation instructions. The inline execution pattern is behavioural and cannot be fully enforced via agent files — relies on consistent workflow compliance.

### 6. All Workers Default to Sonnet ✅ Fixed

Code-generation workers that fill templates don't need Sonnet-class reasoning, but all workers previously used `model: sonnet`.

Fix applied: `domain-worker`, `data-worker`, and `test-worker` downgraded to `model: haiku`. `presentation-worker` stays on Sonnet — DI wiring and route decisions require architectural judgment.

---

## Empirical Evidence from Real Sessions

Two wehire sessions were analysed post-implementation to validate the drains identified above.

| Metric | Issue #26 (Apr 10) | Issue #53 (Apr 11) |
|---|---|---|
| Overall score | 7.0/10 | 6.3/10 |
| Duration | ~15h 15m | ~13h |
| Cache hit ratio | 97.2% | 97.5% |
| Billed approx | ~644K tokens | ~737K tokens |
| Avg billed / turn | ~2,863 | ~3,412 |
| read_grep_ratio | **37.0** (critical) | **6.8** (P7 violation) |
| Workers spawned | feature-orchestrator ✓ | None ✗ |
| Worktree isolation | ✗ missing | n/a |
| Feature branch during work | ✓ | ✗ (worked on main) |

**read_grep_ratio** is the most consistent finding across both sessions. Issue #26's ratio of 37.0 (37 Read / 1 Grep) is the single largest efficiency gap observed — entire files read when symbol-level Grep would have located the target. Issue #53 at 6.8 (41 Read / 6 Grep) still exceeds the P7 target of < 3. Note: some Read calls hit downstream project-specific files (e.g. `Code.gs`) — those are out of scope for web-agentic fixes and will be addressed in downstream configuration.

Both sessions had excellent cache hit ratios (97%+), confirming the caching layer works — the problem is upstream: unnecessary reads inflate cache creation cost and context size, not cache misses.

---

## Recommended Fixes

### High Impact

**A. Move context reads into workers, not orchestrators** ✅ Done

Removed all Phase 2 file reads from `feature-orchestrator` and `backend-orchestrator`. Each worker now owns its own context reads. Orchestrators pass only intent (feature name, fields, operations) to the first worker.

**B. Downgrade mechanical workers to Haiku** ✅ Done

`domain-worker`, `data-worker`, and `test-worker` changed to `model: haiku`. `presentation-worker` kept on Sonnet. `feature-orchestrator`, `backend-orchestrator`, `arch-review-worker`, `debug-worker` kept on Sonnet.

> Note: Haiku is ~5–8× cheaper per token than Sonnet. Workers that follow a deterministic skill procedure (no architectural judgment needed) are safe candidates.

**C. Grep-first rule for reference doc access** ✅ Done

All workers now have a "Search Rules" section mandating `Grep` before `Read`. `Reference:` lines updated to instruct workers to Grep for the relevant section by keyword before reading the full file.

Full structural splitting of `data.md` (529 lines) and `utilities.md` (487 lines) remains open — tracked as a medium-term improvement.

**D. Always set `isolation: worktree` on feature-orchestrator** ✅ Done

`feature-orchestrator` Phase 2 now mandates `isolation: worktree` for all worker spawns.

**E. Pass file paths between workers, not content** ✅ Done

Both orchestrators now instruct: "Pass only the list of created file paths from each worker as input to the next — never pass file contents."

### Medium Impact

**F. Use the reference index for selective loading** ✅ Done

All worker Reference lines now include: "If uncertain which reference file covers a topic, check `reference/index.md` first." Workers consult the index to identify the right file, then Grep into it — avoiding full reads of the wrong file.

**G. Strip explanatory comments from skill templates** ✅ Done

Removed redundant instructional content from templates:
- `test-create-mock/template.md` — removed 14-line usage example (covered by SKILL.md's Return instruction)
- `domain-create-repository/template.md` — removed `// Include only the methods that were requested`
- `data-create-datasource/template.md` — removed `// Include only requested operations`
- `data-create-repository-impl/template.md` — removed `// repeat pattern for each method`

ORM-specific comments in `data-create-db-datasource` and `data-create-db-repository` were kept — they are code generation hints, not explanatory padding.

---

## Quick Wins — Applied 2026-04-11

1. ✅ `model: haiku` added to `data-worker.md`, `test-worker.md`, `domain-worker.md`
2. ✅ Phase 2 file reads removed from `feature-orchestrator` and `backend-orchestrator`
3. ✅ Both orchestrators updated: "Pass only the list of created file paths"
4. ✅ `isolation: worktree` mandated in `feature-orchestrator` Phase 2
5. ✅ Grep-first "Search Rules" section added to all workers; Reference lines updated

**Remaining open:**
- Structural split of `reference/data.md` and `reference/utilities.md` by operation type (medium impact, tracked under fix C)

---

## Connection to Shared Submodule Architecture

The [Shared Submodule doc](https://jurnal.atlassian.net/wiki/spaces/~611df3da650a26006e44928d/pages/51129909710) explicitly solves the platform-skills problem via on-demand `Read` instead of preloading. The same principle applies here to reference docs:

> "On-demand cost: one Read call at the start of execution — negligible compared to preloading 3 skill files permanently."

The web-agentic reference docs should adopt the same pattern: workers `Grep` for the specific section they need rather than loading the full file. This aligns with the shared submodule's context efficiency model and is consistent across all platforms.

---

## Notes

- Session IDs cannot be used to pull Anthropic usage analytics externally
- Token counts per turn are visible in the Claude Code terminal output — watch for spikes after each `Agent()` spawn; orchestrator turns are typically the spike points
- Orchestrators are the highest-leverage place to optimize — they hold the longest-lived context windows
- This observation directly supports decisions for migrating web-agentic into the shared submodule model
