# Agentic Performance Report — split-bill-mvp

> Date: 2026-04-13
> Session: df36f072-612f-40d0-bf62-aa3794474dfd
> Branch: feat/issue-073-split-bill-mvp
> Duration: ~2 min (2026-04-13T10:43:01.767Z → 2026-04-13T10:45:33.837Z)

## Summary Scores

| Dimension | Score | Rating | Key Signal |
|---|---|---|---|
| D1 · Orchestration Quality | 4/10 | Poor | Feature work done inline — CLAUDE.md mandates feature-orchestrator delegation for all feature work |
| D2 · Worker Invocation | 2/10 | Critical | Zero workers spawned despite explicit CLAUDE.md rule requiring feature-orchestrator for any feature create/update |
| D3 · Skill Execution | 4/10 | Poor | No skills called — pickup-issue skipped at session start despite issue-073 referenced in branch name |
| D4 · Token Efficiency | 7/10 | Good | Cache hit ratio 81.6% (Fair band); read_grep_ratio 1 (Good); billed/turn ~7,079 slightly above 5K threshold |
| D5 · Routing Accuracy | 5/10 | Fair | Branch prefix feat/ is correct for feature work, but routing entirely bypassed required orchestration pipeline |
| D6 · Workflow Compliance | 2/10 | Critical | Direct inline Edit calls violated mandatory feature-orchestrator delegation; no issue pickup; no skills invoked |
| D7 · One-Shot Rate | 7/10 | Good | Zero rejected tools, zero duplicate reads, no rework signals on write paths |
| **Overall** | **4.4/10** | **Poor** | |

## Token Breakdown

| Metric | Value |
|---|---|
| Input tokens | 19 |
| Cache creation | 62,347 |
| Cache reads | 277,432 |
| Output tokens | 15,500 |
| **Billed approx** | **77,866** |
| Cache hit ratio | 81.6% |
| Avg billed / turn | ~7,079 |

## Tool Usage

| Tool | Calls |
|---|---|
| Edit | 2 |
| Read | 1 |
| Bash | 1 |

Read:Grep ratio: 1 (target < 3 — high ratio signals full-file reads over targeted search)

## Agent & Skill Invocations

| Component | Args / Description | Outcome |
|---|---|---|
| _(none)_ | — | No agents or skills were invoked this session |

## Findings

### What went well
- Zero rejected tool calls — the edits executed cleanly on the first attempt.
- No duplicate file reads — the single Read of SplitBillFormView.tsx was not re-read.
- Read:Grep ratio of 1 indicates targeted, efficient file access rather than broad scanning.
- Branch naming follows convention (feat/issue-073-split-bill-mvp) correctly identifying feature type and issue reference.
- user_turn_count/assistant_turns ratio of 0.64 is within acceptable range, indicating no excessive back-and-forth corrections.

### Issues found
- **[D1, D2, D6]** CLAUDE.md contains the explicit rule: "Feature work (create or update, any scope) → always delegate to feature-orchestrator, never inline." This session performed inline Edit operations on a presentation component without spawning a feature-orchestrator at any point. This is the highest-severity violation recorded.
- **[D3, D6]** No `pickup-issue` skill was called despite the branch referencing issue-073. Workflow requires skill-based issue pickup at session start to ensure proper context loading and traceability.
- **[D6]** The only Bash command executed was `extract-session.sh` (the perf extraction tool itself), confirming zero workflow tooling was used during the session.
- **[D4]** Average billed tokens per turn is ~7,079, exceeding the 5K/turn threshold. With only 11 assistant turns, the high cache creation cost (62,347) relative to the small amount of actual work (2 edits, 1 read) suggests context loading overhead that could be amortized better by workers.
- **[D5]** While the branch prefix is correct, no routing decision was made — the session operated as a direct prompt-response loop rather than using the documented agentic routing pipeline.

## Recommendations

1. **Always spawn feature-orchestrator for feature work** — The CLAUDE.md rule is unambiguous. Even for small, single-file UI edits within an existing feature directory, the session must begin by delegating to `feature-orchestrator`. This is the single highest-impact fix and would bring D1, D2, and D6 scores from Poor/Critical to Good or Excellent.
2. **Call pickup-issue at session start** — When a branch references an issue number (e.g., issue-073), `pickup-issue` must be invoked early to establish context, link work to the issue, and satisfy workflow compliance requirements.
3. **Reduce billed-per-turn cost** — The session's high billed/turn ratio (~7,079) on minimal work suggests context is being loaded redundantly. Delegating to a worker via feature-orchestrator would scope context more tightly and lower per-turn costs.
