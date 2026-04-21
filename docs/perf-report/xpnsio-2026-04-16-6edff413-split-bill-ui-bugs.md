# Agentic Performance Report — Issue #93

> Date: 2026-04-16
> Session: 6edff413-a0f9-4c1e-94c2-34508459ebea
> Branch: main
> Duration: ~17 min (2026-04-16T15:36:59.873Z → 2026-04-16T15:54:10.647Z)

## Summary Scores

| Dimension | Score | Rating | Key Signal |
|---|---|---|---|
| D1 · Orchestration Quality | 8/10 | Good | debug-orchestrator and issue-worker spawned correctly for bug fix session |
| D2 · Worker Invocation | 7/10 | Good | correct subagent types but main agent performed inline edits that should have been done by debug-worker |
| D3 · Skill Execution | 8/10 | Good | N/A — no skills needed for a bug fix; inline handling appropriate |
| D4 · Token Efficiency | 7/10 | Good | excellent cache hit ratio (95.5%) but read_grep_ratio of 8 violates P7; SplitBillFormView.tsx read 5x |
| D5 · Routing Accuracy | 4/10 | Poor | session recorded on `main` branch; fix work should start on a feature branch immediately |
| D6 · Workflow Compliance | 5/10 | Fair | branch was eventually created but session started on main; git add used specific files correctly; PR created correctly |
| D7 · One-Shot Rate | 8/10 | Good | zero rejected tools; SplitBillFormView.tsx re-read 5 times signals re-orientation overhead |
| **Overall** | **6.7/10** | **Fair** | |

## Token Breakdown

| Metric | Value |
|---|---|
| Input tokens | 65 |
| Cache creation | 60,778 |
| Cache reads | 1,281,690 |
| Output tokens | 22,045 |
| **Billed approx** | **82,888** |
| Cache hit ratio | 95.5% |
| Avg billed / turn | ~1,928 |

## Tool Usage

| Tool | Calls |
|---|---|
| Read | 8 |
| Bash | 8 |
| Edit | 4 |
| Agent | 2 |
| Glob | 1 |

Read:Grep ratio: 8 (target < 3 — high ratio signals full-file reads over targeted search)

## Agent & Skill Invocations

| Component | Args / Description | Outcome |
|---|---|---|
| Agent: issue-worker | Create GitHub issue and branch for split bill bugs | Correct — issue-worker is the right subagent for issue creation at session start |
| Agent: debug-orchestrator | Investigate split bill UI bugs | Correct type for debugging, but main agent still performed direct edits rather than fully delegating to debug-worker |

## Findings

### What went well
- Cache hit ratio of 95.5% is excellent, indicating strong prompt caching and cost efficiency per turn.
- Zero rejected tool calls — the agent executed without interruption or correction loops.
- Correct subagent types were chosen: `issue-worker` for issue creation and `debug-orchestrator` for investigation.
- `git add` used specific file paths (not `-A` or `.`), following project workflow rules.
- PR was created via `gh pr create` with a descriptive title and a fix branch was ultimately used.
- Average billed tokens per turn (~1,928) stayed below the 2K Good threshold despite a 17-minute session.

### Issues found
- **[D5]** Session recorded `git_branch: main` — the fix work (Edits, Reads, commits) began on the main branch. CLAUDE.md and workflow rules require fix work to happen on a dedicated branch from the start. The fix branch `fix/issue-093-split-bill-ui-bugs` was only used for the push/PR, not from the beginning of the session.
- **[D4]** `read_grep_ratio` of 8 exceeds the target of < 3. `SplitBillFormView.tsx` was read 5 times across the session. Targeted Grep calls for specific props, event handlers, or class names would have been far cheaper than repeated full-file reads of this component.
- **[D4]** `duplicate_reads` flagged `SplitBillFormView.tsx` — 5 reads of the same file indicates the agent lost context between tool calls and re-oriented by re-reading the whole file instead of using targeted lookups.
- **[D2]** The main agent performed 4 direct `Edit` calls to presentation files (`SplitBillFormView.tsx`, `page.tsx`) after the `debug-orchestrator` was spawned. The orchestrator should have spawned a `debug-worker` to handle the actual edits. Inline edits by the orchestrating agent after delegation bypass the worker isolation principle.
- **[D6]** Session started on `main` rather than creating the fix branch first. The `issue-worker` spawn creates the branch, but commits were made before the branch push, suggesting commits landed on main before being moved to the fix branch.

## Recommendations

1. **Highest impact fix — branch before first edit** — The issue-worker should create the branch and the agent should `git checkout` onto that branch before any Read, Edit, or Bash commands touch source files. Currently the workflow creates the issue/branch but doesn't switch to it before proceeding with edits. Add a `git checkout fix/issue-NNN-...` step immediately after `issue-worker` completes.
2. **Replace repeated full-file reads with Grep** — `SplitBillFormView.tsx` was read 5 times. After the first read to understand structure, use Grep with specific search terms (prop names, JSX element names, handler names) for subsequent lookups. This would cut Read calls from 8 to ~3-4 and bring the ratio below 3.
3. **Route edits through debug-worker** — The `debug-orchestrator` should spawn a `debug-worker` that performs the actual file edits. The orchestrating agent should only pass file paths and bug descriptions, not perform edits directly. This keeps the isolation boundary clean and avoids the main agent accumulating file state.

---

## Effort vs Billing

### Token cost breakdown

| Token type | Count | Unit price | Cost (USD) |
|---|---|---|---|
| Input | 65 | $3.00 / MTok | $0.00 |
| Cache creation | 60,778 | $3.75 / MTok | $0.23 |
| Cache reads | 1,281,690 | $0.30 / MTok | $0.38 |
| Output | 22,045 | $15.00 / MTok | $0.33 |
| **Total** | **82,888 billed-equiv** | | **~$0.94** |

Cache hit ratio of **95.5%** was the primary cost saver — without caching, the same 1,364,578 tokens at full input rates ($3.00/MTok) would have cost approximately **$4.09**, making the cache savings **~$3.15** (77% reduction).

### Where the tokens went

| Task | Estimated tokens | % of total | Productive? |
|---|---|---|---|
| Issue creation (issue-worker spawn) | ~8,000 | ~10% | ✅ |
| Debug investigation (debug-orchestrator spawn) | ~18,000 | ~22% | ✅ |
| SplitBillFormView.tsx repeated reads (5x) | ~20,000 | ~24% | ❌ |
| Inline edits to SplitBillFormView.tsx and page.tsx | ~15,000 | ~18% | ✅ |
| Git operations and PR creation | ~5,000 | ~6% | ✅ |
| Output generation (commits, PR body, reasoning) | ~16,888 | ~20% | ⚠️ |
| **Total** | **~82,888** | **100%** | |

**Productive work: ~56% (~46,000 tokens / ~$0.53)**
**Wasted on rework: ~24% (~20,000 tokens / ~$0.23)**

### Effort-to-value ratio

| Deliverable | Complexity | Tokens spent | Efficiency |
|---|---|---|---|
| GitHub issue #93 creation | Low | ~8,000 | Good — straightforward issue-worker invocation |
| Split bill UI bug investigation | Medium | ~18,000 | Good — debug-orchestrator correctly scoped the investigation |
| SplitBillFormView.tsx fix (Suspense/Select bugs) | Medium | ~35,000 | Fair — edits were correct but ~20K tokens wasted on 5x re-reads of the same file |
| page.tsx Suspense wrapper fix | Low | ~8,000 | Good — targeted and proportionate |
| PR creation and branch push | Low | ~13,888 | Good — correct workflow steps followed |

### Key insight
The single highest-cost inefficiency was the 5x repeated full read of `SplitBillFormView.tsx`, consuming an estimated 20,000 tokens (~$0.23, roughly 24% of the session). This file was re-read in full each time the agent needed to locate a specific prop or JSX element, rather than using Grep to target the exact lines of interest. For a component that was read once at the start, all subsequent lookups should have been targeted searches. This is a pure overhead cost that produced no additional understanding beyond the first read, and it is the primary reason the `read_grep_ratio` reached 8 — nearly three times the acceptable threshold. Bringing this to < 3 would have saved approximately 12,000–15,000 tokens and meaningfully reduced the already-low session cost.
