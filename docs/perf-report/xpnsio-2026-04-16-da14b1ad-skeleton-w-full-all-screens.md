# Agentic Performance Report — Issue #91

> Date: 2026-04-16
> Session: da14b1ad-c966-4a0d-badc-b9565fb47daf
> Branch: main (session started on main; push targeted fix/issue-091-skeleton-w-full-all-screens)
> Duration: ~7 min (2026-04-16T15:26:00Z → 2026-04-16T15:33:04Z)

## Summary Scores

| Dimension | Score | Rating | Key Signal |
|---|---|---|---|
| D1 · Orchestration Quality | 8/10 | Good | No orchestrators spawned; inline work used throughout (N/A baseline) |
| D2 · Worker Invocation | 3/10 | Poor | 8 UI view files written inline — no ui-worker spawned; feature-orchestrator entirely bypassed |
| D3 · Skill Execution | 8/10 | Good | N/A — pure UI fix with no domain/data artifacts; no skill misfire |
| D4 · Token Efficiency | 7/10 | Good | Cache hit ratio 93.7% excellent; Read:Grep ratio at 3.0 (boundary); avg 2,692 billed/turn |
| D5 · Routing Accuracy | 5/10 | Fair | issue-worker correctly spawned; but feature-orchestrator routing skipped for all edits |
| D6 · Workflow Compliance | 4/10 | Poor | CLAUDE.md mandate to delegate feature work to feature-orchestrator explicitly violated |
| D7 · One-Shot Rate | 7/10 | Good | 0 rejected tool calls; 0 duplicate reads; user/assistant ratio 0.72 (below 0.8 threshold) |
| **Overall** | **6.0/10** | **Fair** | |

## Token Breakdown

| Metric | Value |
|---|---|
| Input tokens | 87 |
| Cache creation | 148,862 |
| Cache reads | 2,220,226 |
| Output tokens | 31,443 |
| **Billed approx** | **180,392** |
| Cache hit ratio | 93.7% |
| Avg billed / turn | 2,692 |

## Tool Usage

| Tool | Calls |
|---|---|
| Bash | 15 |
| Read | 12 |
| Edit | 9 |
| Grep | 4 |
| Agent | 1 |

Read:Grep ratio: 3.0 (target < 3 — high ratio signals full-file reads over targeted search)

## Agent & Skill Invocations

| Component | Args / Description | Outcome |
|---|---|---|
| Agent: issue-worker | Create issue and branch for skeleton fix | Correct — issue #91 created, fix/issue-091-skeleton-w-full-all-screens branch pushed |

No skill calls were recorded in this session.

## Findings

### What went well
- Cache hit ratio of 93.7% is excellent, keeping costs low for a session touching 12 files
- Zero rejected tool calls and zero duplicate reads indicate clean, confident execution
- issue-worker was correctly spawned as the first step to register the issue and create the branch
- `git add` used specific file paths rather than `-A` or `.` — correct staging hygiene
- `gh pr create` was used to open a PR with a descriptive title and body
- The PR targeted the feature branch (fix/issue-091-skeleton-w-full-all-screens), not main directly

### Issues found
- **[D2][D6]** Feature work was executed entirely inline — CLAUDE.md states "Feature work (create or update, any scope) → always delegate to feature-orchestrator, never inline." Eight presentation-layer view files were modified without spawning a `feature-orchestrator` or `ui-worker`. This is a direct, explicit rule violation.
- **[D5]** Session recorded `git_branch: main` at session start, meaning the agent began on the main branch before the feature branch was created. Edits may have been staged or executed on main before the branch was pushed.
- **[D4]** Read:Grep ratio is exactly 3.0, at the Fair/Good boundary. 12 full-file reads were performed across presentation view files when Grep could have located the specific skeleton component patterns needing change. In a codebase with 8+ view files, a targeted `Grep` for skeleton usage patterns would have been more efficient than reading each file in full.
- **[D6]** No explicit `Closes #91` or `Fixes #91` reference was confirmed in the PR body from the bash command log (the PR body was truncated in the recorded command). If absent, this violates the issue-linking convention.

## Recommendations

1. **Highest impact fix — Delegate to feature-orchestrator** — The CLAUDE.md rule is unambiguous: any feature work (including bug fixes touching multiple files) must go through `feature-orchestrator`. The agent should have spawned `feature-orchestrator` after `issue-worker` completed. The orchestrator would then have spawned a `ui-worker` for the 8 presentation view edits. Enforcing this would have kept the session compliant with the project's workflow contract.

2. **Use Grep before Read for multi-file patterns** — When the task is "fix skeleton pattern across all screens," the correct approach is: `Grep` for the skeleton component usage, identify which files need changes, then Read only those files. This avoids 12 full reads when 4 targeted Greps plus selective reads would suffice.

3. **Branch before editing** — Ensure the feature branch is created and checked out before any edits begin. Starting on `main` and branching retroactively risks committing to main if the branch creation step fails or is interrupted.

4. **Verify PR body includes issue closure reference** — Confirm `Closes #91` or `Fixes #91` is present in the PR body to ensure automatic issue closure on merge and maintain traceability.

---

## Effort vs Billing

### Token cost breakdown

| Token type | Count | Unit price | Cost (USD) |
|---|---|---|---|
| Input | 87 | $3.00 / MTok | $0.00 |
| Cache creation | 148,862 | $3.75 / MTok | $0.56 |
| Cache reads | 2,220,226 | $0.30 / MTok | $0.67 |
| Output | 31,443 | $15.00 / MTok | $0.47 |
| **Total** | **180,392 billed-equiv** | | **~$1.70** |

Cache hit ratio of **93.7%** was the primary cost saver — without it, the 2,220,226 cache-read tokens would have been billed as input at $3.00/MTok, adding approximately $6.66 to the session cost. The fully-uncached equivalent cost would have been approximately **~$8.36**, meaning the cache saved roughly **~$6.66 (80% cost reduction)**.

### Where the tokens went

| Task | Estimated tokens | % of total | Productive? |
|---|---|---|---|
| Issue creation + branch setup (issue-worker) | ~18,000 | ~10% | ✅ |
| Git history exploration (git log, show, branch) | ~12,000 | ~7% | ⚠️ |
| Reading 12 presentation view files | ~45,000 | ~25% | ✅ |
| Editing 8 view files (skeleton fix) | ~72,000 | ~40% | ✅ |
| Git staging, commit, push, PR creation | ~15,000 | ~8% | ✅ |
| Backlog / memory reads | ~8,000 | ~4% | ⚠️ |
| Cleanup (git checkout main, pull) | ~10,392 | ~6% | ⚠️ |
| **Total** | **~180,392** | **100%** | |

**Productive work: ~75% (~135,000 tokens / ~$1.27)**
**Wasted on rework: ~0% (no rework detected)**
**Overhead: ~25% (~45,000 tokens / ~$0.43)**

### Effort-to-value ratio

| Deliverable | Complexity | Tokens spent | Efficiency |
|---|---|---|---|
| Issue #91 registered + branch created | Low | ~18,000 | Good — issue-worker correctly encapsulated this |
| Skeleton w-full fix across 8 view files | Low-Medium | ~117,000 | Fair — pattern was repetitive; inline reads of all 12 files added overhead vs targeted Grep |
| PR opened with description | Low | ~15,000 | Good — proportionate to task |
| Git history investigation | Low | ~12,000 | Fair — some exploration was needed to understand prior skeleton commit context |

### Key insight
The single highest-cost work unit was the full read + edit cycle across 12 presentation view files (~117,000 tokens, ~65% of total). This is disproportionate for what is a low-complexity, repetitive pattern fix (adding `w-full` to skeleton components). The root inefficiency was reading entire view files rather than using Grep to pinpoint the skeleton component locations first. With a targeted Grep approach, the agent could have identified the 8 files requiring changes with ~4 Grep calls, read only the relevant component sections, and reduced the Read token consumption by an estimated 40–50%. That said, zero rework and excellent cache utilization kept the total session cost at a very reasonable ~$1.70.
