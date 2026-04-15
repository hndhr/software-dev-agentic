# Agentic Performance Report — split-bill-trip-features

> Date: 2026-04-14
> Session: 2330492f-d051-4143-b83a-aa8b002aef13
> Branch: main
> Duration: ~1323 min (2026-04-14T18:28:18.231Z → 2026-04-15T16:31:33.053Z)

## Summary Scores

| Dimension | Score | Rating | Key Signal |
|---|---|---|---|
| D1 · Orchestration Quality | 8/10 | Good | Two feature-orchestrators coordinated correctly; Explore used for discovery; minimal direct file reads at root level |
| D2 · Worker Invocation | 7/10 | Good | Orchestrators and issue-worker matched task types; no cross-layer ordering violations visible; session started on main rather than a feature branch |
| D3 · Skill Execution | 7/10 | Good | N/A at root level (skills run inside orchestrators); no root-level skill calls recorded — cannot confirm skill alignment without inner-agent visibility |
| D4 · Token Efficiency | 7/10 | Good | Cache hit ratio 90.5% (Excellent); read_grep_ratio 5 (Fair); avg 4,074 billed tokens/turn (Fair); zero duplicate reads |
| D5 · Routing Accuracy | 6/10 | Fair | Feature work correctly delegated to feature-orchestrator; however git_branch shows session started on main instead of a feat/ branch |
| D6 · Workflow Compliance | 7/10 | Good | Specific file staging paths used; no --no-verify; issue-worker used for PR; session branch starts on main which conflicts with CLAUDE.md branch discipline |
| D7 · One-Shot Rate | 8/10 | Good | Zero rejected tool calls; zero duplicate reads; user/assistant turn ratio 0.74 — slightly high but no clear rework signals |
| **Overall** | **7.1/10** | **Good** | |

## Token Breakdown

| Metric | Value |
|---|---|
| Input tokens | 163 |
| Cache creation | 301,964 |
| Cache reads | 2,891,240 |
| Output tokens | 31,986 |
| **Billed approx** | **334,113** |
| Cache hit ratio | 90.5% |
| Avg billed / turn | ~4,074 |

## Tool Usage

| Tool | Calls |
|---|---|
| Bash | 14 |
| Read | 5 |
| Agent | 4 |
| SendMessage | 3 |
| Glob | 3 |
| Edit | 3 |
| ToolSearch | 1 |

Read:Grep ratio: 5 (target < 3 — high ratio signals full-file reads over targeted search; no Grep calls recorded, all lookup done via Read or Glob)

## Agent & Skill Invocations

| Component | Args / Description | Outcome |
|---|---|---|
| Agent: Explore | Explore split bill feature | Correct — discovery before delegation |
| Agent: feature-orchestrator | Feature: creator as optional participant in split bill | Correct — feature delegation per CLAUDE.md |
| Agent: issue-worker | Create issue, commit chunks, push and create PR | Correct — PR lifecycle handled by issue-worker |
| Agent: feature-orchestrator | Trip feature for split bill grouping | Correct — second feature correctly delegated |

No skill calls recorded at root level. Skills are expected to have been executed inside the two feature-orchestrator spawns; the extracted JSON does not capture inner-agent skill calls.

## Findings

### What went well
- The Explore → feature-orchestrator → issue-worker invocation sequence is correct and follows the documented workflow pattern.
- Two distinct features (creator-as-participant and trip grouping) were each delegated to separate feature-orchestrator instances, preserving clean isolation.
- Zero rejected tool calls and zero duplicate reads indicate the session was clean with no wasted retries.
- Cache hit ratio of 90.5% is excellent and kept billing low across a multi-hour session.
- `git add` commands used explicit file paths throughout, avoiding accidental staging of unrelated or sensitive files.
- No `--no-verify` flags were used, respecting hook enforcement.

### Issues found
- **[D5/D6]** Session `git_branch` is `main`. CLAUDE.md requires feature work to be done on a dedicated feature branch. The bash log does show `git push origin feat/split-bill-creator-participant` for the first feature, suggesting branching was at least partially practiced, but the session metadata records `main` as the active branch — indicating that the second trip feature was either committed or the session itself continued on main after merging.
- **[D4]** `read_grep_ratio` of 5 — with 5 Read calls and 0 Grep calls. No targeted content searches were performed at the root orchestration level. Files like `BillAmountCalculationService.ts` and `SplitBillListView.tsx` were read in full when a Grep for specific symbols might have been sufficient for exploration context.
- **[D3]** No skill calls are visible at the root level. Since feature work touched presentation layer files (`SplitBillListView.tsx`, `TripListView.tsx`) and likely domain/data artifacts (schema changes committed via `git add src/lib/schema.ts`), the absence of any skill trace is a data gap. If inner feature-orchestrator agents did not use the canonical skills (`domain-create-entity`, `pres-update-stateholder`, etc.), this would be a significant anti-pattern. This cannot be confirmed from the current extraction scope.
- **[D7]** `user_turn_count / assistant_turns` = 61/82 = 0.74 is approaching the 0.8 threshold. For a session spanning ~22 hours wall time, this is likely partly explained by async human review cycles, but still warrants attention.

## Recommendations

1. **Highest impact fix — enforce feature branch creation before spawning feature-orchestrator.** The root orchestrator or the parent agent should create and checkout a `feat/` branch as the first step, before any `feature-orchestrator` spawn. This prevents the session from drifting back to main after PR merge.
2. **Add Grep calls for symbol discovery** — when exploring existing code to understand a feature (e.g., how `BillAmountCalculationService` works), prefer a targeted `Grep` for the class or function name rather than reading the entire file. This would bring `read_grep_ratio` below 3.
3. **Capture inner-agent skill calls in session extraction** — the `skill_calls` array is empty because skill invocations inside spawned agents are not propagated to the parent session JSON. Extending `extract-session.sh` to aggregate child-agent skill calls would give the performance analyst full visibility into whether domain, data, and presentation skills were correctly sequenced.
4. **Reduce the user/assistant turn ratio** by ensuring feature-orchestrator spawns include sufficient context upfront (file paths, intent, layer boundaries) so human clarification mid-spawn is minimized.

---

## Effort vs Billing

### Token cost breakdown

| Token type | Count | Unit price | Cost (USD) |
|---|---|---|---|
| Input | 163 | $3.00 / MTok | $0.00 |
| Cache creation | 301,964 | $3.75 / MTok | $1.13 |
| Cache reads | 2,891,240 | $0.30 / MTok | $0.87 |
| Output | 31,986 | $15.00 / MTok | $0.48 |
| **Total** | **334,113 billed-equiv** | | **~$2.48** |

Cache hit ratio of **90.5%** was the primary cost saver. Without caching, the 2,891,240 cache-read tokens would have been billed as input at $3.00/MTok — adding approximately $8.67 in input costs. The full uncached cost would have been approximately **~$9.96** vs the actual **~$2.48**, representing a **~75% cost reduction** from cache hits alone.

### Where the tokens went

| Task | Estimated tokens | % of total | Productive? |
|---|---|---|---|
| Explore: split bill feature discovery | ~25,000 | ~7% | ✅ Productive |
| feature-orchestrator: creator-as-optional-participant | ~130,000 | ~39% | ✅ Productive |
| issue-worker: commit chunks, push, PR creation | ~30,000 | ~9% | ✅ Productive |
| feature-orchestrator: trip feature for split bill grouping | ~130,000 | ~39% | ✅ Productive |
| Root coordination (bash, reads, globs) | ~19,113 | ~6% | ⚠️ Overhead |
| **Total** | **~334,113** | **100%** | |

**Productive work: ~94% (~314,000 tokens / ~$2.33)**
**Wasted on rework: ~0% (~0 tokens / ~$0.00)**
**Overhead: ~6% (~20,000 tokens / ~$0.15)**

### Effort-to-value ratio

| Deliverable | Complexity | Tokens spent | Efficiency |
|---|---|---|---|
| Creator-as-optional-participant in split bill | Medium | ~130,000 | Good — touches presentation and domain layers; token spend proportionate |
| Trip feature for split bill grouping | High | ~130,000 | Good — new feature module with domain, data, and presentation layers; token spend proportionate to scope |
| PR lifecycle (commit + push + PR) | Low | ~30,000 | Fair — slightly high for a lifecycle task; likely includes context priming for issue-worker |
| Feature exploration (Explore agent) | Low | ~25,000 | Good — Explore agents are expected to read broadly; contained spend |

### Key insight

The two `feature-orchestrator` invocations each consumed approximately 130,000 tokens, which is symmetric and proportionate given that both features (creator-as-optional-participant and trip grouping) appear to be medium-to-high complexity and cross multiple Clean Architecture layers. The session has no rework overhead at all — zero rejected tool calls, zero duplicate reads — which is the primary efficiency driver. The only mild inefficiency is the `issue-worker` consuming ~30,000 tokens for PR lifecycle work, which is slightly elevated for what is largely a mechanical commit-and-push operation; this may be explained by the worker needing to re-read commit context and write a structured PR body. Overall, this session is well-distributed and cost-effective for the scope delivered.
