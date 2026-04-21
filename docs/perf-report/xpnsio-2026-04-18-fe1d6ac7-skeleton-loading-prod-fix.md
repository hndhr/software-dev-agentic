# Agentic Performance Report — Issue #95

> Date: 2026-04-18
> Session: fe1d6ac7-1b25-4f38-94d9-44162ddf52fd
> Branch: main
> Duration: ~121 min (2026-04-18T16:16:41.555Z → 2026-04-18T18:17:59.670Z)

## Summary Scores

| Dimension | Score | Rating | Key Signal |
|---|---|---|---|
| D1 · Orchestration Quality | 7/10 | Good | 3 sequential feature-orchestrator spawns for one bug rather than single coordinated session |
| D2 · Worker Invocation | 7/10 | Good | Correct worker types (debug-worker, presentation-worker) but orchestrator re-spawned 3× |
| D3 · Skill Execution | 8/10 | Good | N/A — bug fix session; no new artifacts; no skill calls expected |
| D4 · Token Efficiency | 7/10 | Good | Excellent cache ratio (96.2%) and read:grep (2.2), dragged by 3 duplicate reads and 3.7K billed/turn |
| D5 · Routing Accuracy | 4/10 | Poor | Work performed directly on `main` instead of a `fix/` branch; PR created then bypassed via direct push |
| D6 · Workflow Compliance | 4/10 | Poor | `main` branch violation + 2 git reverts signal workflow collapse; `git add` with specific files was correct |
| D7 · One-Shot Rate | 5/10 | Fair | 2 git reverts, 3 feature-orchestrator cycles, 3 duplicate reads — significant rework across iteration |
| **Overall** | **6.0/10** | **Fair** | |

## Token Breakdown

| Metric | Value |
|---|---|
| Input tokens | 1,065 |
| Cache creation | 352,210 |
| Cache reads | 8,868,143 |
| Output tokens | 222,436 |
| **Billed approx** | **575,711** |
| Cache hit ratio | 96.2% |
| Avg billed / turn | ~3,691 |

## Tool Usage

| Tool | Calls |
|---|---|
| Read | 24 |
| Bash | 15 |
| Agent | 11 |
| Grep | 11 |
| Glob | 8 |
| Edit | 2 |
| ToolSearch | 2 |
| SendMessage | 1 |
| Monitor | 1 |
| Write | 1 |

Read:Grep ratio: 2.2 (target < 3 — high ratio signals full-file reads over targeted search)

## Agent & Skill Invocations

| Component | Args / Description | Outcome |
|---|---|---|
| Agent: issue-worker | Create GitHub issue for skeleton loading bug | ✓ Issue created early in session — correct workflow start |
| Agent: debug-worker | Debug skeleton loading missing in prod | ✓ Correct use of debug-worker for investigation |
| Agent: feature-orchestrator | Fix skeleton loading in production | ✗ Fix attempt 1 — subsequently reverted (commit 0db8698) |
| Agent: feature-orchestrator | Fix isPending for [id] and trips/[id] routes | ✗ Fix attempt 2 — subsequently reverted (commit d70d622) |
| Agent: debug-worker | Debug why isPending fix didn't work in prod | ✓ Correct use of debug-worker after regression |
| Agent: feature-orchestrator | Fix skeleton sibling conditional and useAction-in-queryFn | ✓ Third attempt — appears to be the surviving fix |
| Agent: Explore | Compare working trips vs broken bills skeleton | ✓ Correct use of Explore for comparative analysis |
| Agent: feature-orchestrator | Add debug logs to bills viewmodel | ⚠ Orchestrator spawned just to add debug logs — presentation-worker would have been more appropriate |
| Agent: presentation-worker | Add debug logs to viewmodel | ✓ Correct layer worker for ViewModel mutation |
| Agent: presentation-worker | Revert useAction removal, keep isPending fix | ✓ Correct layer worker for targeted ViewModel revert |
| Agent: presentation-worker | Fix skeleton timing with useState loading latch | ✓ Correct layer worker for final fix |

## Findings

### What went well
- Cache hit ratio of 96.2% is excellent — prior session context was heavily reused, keeping cache read costs low.
- Read:Grep ratio of 2.2 is well under the target of 3, indicating Grep-first discipline was followed.
- `issue-worker` was spawned first before any fix work — correct workflow entry point.
- Worker type selection was accurate throughout: debug-worker for investigation, presentation-worker for ViewModel changes, Explore for comparison.
- `git add` used specific file paths rather than `-A` or `.` in all commit commands.

### Issues found
- **[D5]** Work was performed directly on `main` — the session ran `git checkout main && git pull` and committed fixes there rather than creating a `fix/` branch. All bug fix work should be on a `fix/issue-095-skeleton-loading` branch with a PR merge into main.
- **[D6]** Two `git revert` calls (`git revert --no-edit 0db8698` and `git revert --no-edit d70d622`) indicate the first two fix attempts were pushed to production and then rolled back — a workflow collapse. A fix/ branch with a PR would have contained this to a review environment.
- **[D6]** A PR was created (`gh pr create`) during the session but the session continued committing directly to main afterward, suggesting the PR-based flow was abandoned mid-session.
- **[D1/D2]** Three separate `feature-orchestrator` spawns were issued for the same logical bug. Each orchestration cycle should have been able to carry forward debug context rather than starting fresh.
- **[D7]** The `useSplitBillListViewModel.ts` file was read 4 times and `useTripListViewModel.ts` 3 times — these duplicate reads across orchestrator boundaries suggest context was not passed efficiently between agents.
- **[D2]** One `feature-orchestrator` spawn ("Add debug logs to bills viewmodel") was used purely to add debug instrumentation — `presentation-worker` (which was spawned immediately after) was the correct direct choice; the orchestrator layer added unnecessary overhead.

## Recommendations

1. **Always create a fix/ branch before touching a bug** — run `git checkout -b fix/issue-095-skeleton-loading` before any agent work begins. This eliminates the risk of pushing broken code directly to main and needing git reverts.
2. **Carry debug-worker output as structured path lists into the next feature-orchestrator** — the 3 duplicate ViewModel reads happened because each new orchestrator rediscovered files already identified by the prior debug cycle. Pass `{ suspected_files: ["path/a.ts", "path/b.ts"], hypothesis: "..." }` as explicit agent input.
3. **Skip the orchestrator when the target file is already known** — once debug-worker identifies a single ViewModel file to patch, spawn `presentation-worker` directly rather than routing through `feature-orchestrator`. Reserve `feature-orchestrator` for multi-layer work.
4. **Do not push to remote until a fix is verified locally** — the two reverts were caused by pushing unverified fixes to main. Use the PR review + Vercel preview deploy cycle to validate before merging.

---

## Effort vs Billing

### Token cost breakdown

| Token type | Count | Unit price | Cost (USD) |
|---|---|---|---|
| Input | 1,065 | $3.00 / MTok | $0.003 |
| Cache creation | 352,210 | $3.75 / MTok | $1.321 |
| Cache reads | 8,868,143 | $0.30 / MTok | $2.660 |
| Output | 222,436 | $15.00 / MTok | $3.337 |
| **Total** | **575,711 billed-equiv** | | **~$7.32** |

Cache hit ratio of **96.2%** was the primary cost saver — without caching, the same 9,443,854 total tokens at full input rates ($3.00/MTok) would have cost ~$28.33, making the cache responsible for saving approximately **$21.01 (74% cost reduction)**.

### Where the tokens went

| Task | Estimated tokens | % of total | Productive? |
|---|---|---|---|
| Issue creation + initial triage | ~25,000 | 4% | ✅ |
| Debug-worker pass 1 (root cause investigation) | ~80,000 | 14% | ✅ |
| Feature-orchestrator pass 1 + commit (reverted) | ~90,000 | 16% | ❌ |
| Feature-orchestrator pass 2 + commit (reverted) | ~85,000 | 15% | ❌ |
| Debug-worker pass 2 (why isPending fix failed) | ~55,000 | 10% | ✅ |
| Explore agent (trips vs bills comparison) | ~30,000 | 5% | ✅ |
| Feature-orchestrator pass 3 + debug instrumentation | ~120,000 | 21% | ✅ |
| Final presentation-worker fix + revert cleanup | ~75,000 | 13% | ✅ |
| Git/PR overhead and session extraction | ~15,711 | 2% | ⚠️ |
| **Total** | **~575,711** | **100%** | |

**Productive work: ~69% (~397,000 tokens / ~$5.05)**
**Wasted on rework: ~31% (~175,000 tokens / ~$2.27)**

### Effort-to-value ratio

| Deliverable | Complexity | Tokens spent | Efficiency |
|---|---|---|---|
| GitHub issue created for skeleton loading bug | Low | ~25,000 | Good — proportionate for issue creation |
| Root cause identification (skeleton/isPending in prod) | Medium | ~165,000 | Fair — two debug passes needed due to incomplete hypothesis in first pass |
| `useSplitBillManageViewModel.ts` isPending fix | Low | ~90,000 | Poor — single ViewModel patch consumed high tokens due to two failed attempts and reverts |
| `useTripDetailViewModel.ts` isPending fix | Low | ~85,000 | Poor — same fix pattern, same rework overhead |
| Final `useState` loading latch fix (surviving fix) | Medium | ~120,000 | Fair — complexity was higher but still elevated by prior rework context |

### Key insight

The single highest-cost item was the two failed fix attempts for `useSplitBillManageViewModel.ts` and `useTripDetailViewModel.ts`, which together consumed approximately 175,000 tokens (~$2.27) and produced no lasting value — both commits were reverted. The root cause was premature confidence: the first debug-worker pass produced a plausible but incorrect hypothesis (isPending from `useRouter` navigation), which the orchestrator acted on without a local verification step. Introducing a mandatory "verify fix locally before push" gate — either a `npm run build` Bash call or a Vercel preview deploy check — before any `git push` would have caught both failures cheaply at the orchestrator level and avoided the entire revert-and-retry cycle.
