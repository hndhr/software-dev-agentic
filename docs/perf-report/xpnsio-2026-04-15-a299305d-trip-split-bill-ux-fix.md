# Agentic Performance Report — Issue #77 78

> Date: 2026-04-15
> Session: a299305d-d204-4b90-912e-c2ba24646508
> Branch: main (work executed on fix/issue-077-ux-improvements-trip-split-bill and fix/issue-078-tailwind-prod-css-scanning)
> Duration: ~776 min (2026-04-15T03:30:42.472Z → 2026-04-15T16:26:15.983Z)

## Summary Scores

| Dimension | Score | Rating | Key Signal |
|---|---|---|---|
| D1 · Orchestration Quality | 8/10 | Good | Explore agents used correctly for read-only discovery; feature-orchestrator delegated to for #77 |
| D2 · Worker Invocation | 5/10 | Fair | Issue #78 CSS fix was worked inline without spawning feature-orchestrator — violates CLAUDE.md rule |
| D3 · Skill Execution | 7/10 | Good | `release` skill correctly invoked post-merge; no domain/data artifact skills needed for CSS/UI scope |
| D4 · Token Efficiency | 5/10 | Fair | read_grep_ratio of 16 (target <3); 3 duplicate read paths — SplitBillFormView.tsx read 6×, globals.css read 6× |
| D5 · Routing Accuracy | 7/10 | Good | fix/ branch prefixes match bug-fix task type; Explore agents used for exploration appropriately |
| D6 · Workflow Compliance | 6/10 | Fair | issue-worker + feature-orchestrator used for #77; #78 handled inline violating "always delegate" rule |
| D7 · One-Shot Rate | 6/10 | Fair | 0 rejected tools; heavy duplicate reads and 5+ repeated build runs indicate exploratory churn |
| **Overall** | **6.3/10** | **Fair** | |

## Token Breakdown

| Metric | Value |
|---|---|
| Input tokens | 187 |
| Cache creation | 296,691 |
| Cache reads | 11,513,424 |
| Output tokens | 127,426 |
| **Billed approx** | **424,304** |
| Cache hit ratio | 97.5% |
| Avg billed / turn | ~2,686 / turn |

## Tool Usage

| Tool | Calls |
|---|---|
| Bash | 62 |
| Read | 16 |
| Agent | 4 |
| Edit | 4 |
| Skill | 1 |

Read:Grep ratio: 16 (target < 3 — high ratio signals full-file reads over targeted search)

## Agent & Skill Invocations

| Component | Args / Description | Outcome |
|---|---|---|
| Agent: Explore | Explore split bill and trip features | Correct — read-only discovery before #77 work |
| Agent: issue-worker | Pick up issue #77 and start work | Correct — proper workflow entry point |
| Agent: feature-orchestrator | Implement issue #77 UX improvements | Correct — delegated as required by CLAUDE.md |
| Agent: Explore | Find dynamic Tailwind class names in UI components | Correct — targeted read-only investigation |
| Skill: release | (no args) | Correct — invoked after both PRs merged to main |

## Findings

### What went well
- Cache efficiency was outstanding at 97.5%, keeping actual billed cost well below the no-cache equivalent.
- Issue #77 followed the correct workflow precisely: issue-worker pickup → feature-orchestrator delegation.
- `git add` commands throughout the session used specific file paths, not `-A` or `.`.
- Separate fix branches were created for #77 and #78 rather than committing to main.
- Zero rejected tool calls across the entire session.
- The `release` skill was invoked after merging both PRs — correct workflow closure.
- PR creation used `--base main` with proper branch refs for both issues.

### Issues found
- **[D2/D6]** Issue #78 (Tailwind v4 PostCSS CSS scanning) was implemented entirely inline — a `git checkout -b fix/issue-078-tailwind-prod-css-scanning` was created and the fix committed without ever spawning `feature-orchestrator`. CLAUDE.md states "Feature work (create or update, any scope) → always delegate to feature-orchestrator, never inline." Even a single-file CSS fix falls within scope.
- **[D4]** `read_grep_ratio` of 16 — `SplitBillFormView.tsx` and `src/app/globals.css` were each read 6 full times. These repeated full reads indicate the agent lost context between sub-tasks and re-loaded rather than using targeted `Grep` to find specific class names or CSS rules.
- **[D4]** `globals.css` is listed in both `duplicate_reads` and `write_paths` — the file was read 6× before a single edit, suggesting uncertainty about the correct insertion point rather than a plan-first approach.
- **[D7]** `npm run build` was invoked at least 5 times in sequence (lines 108, 117, 124, 128, 137 in bash_commands) with multiple `.next` cache wipes, indicating significant trial-and-error to verify the CSS fix rather than confidence in the change.
- **[D5]** The session started on `main` branch. While fix branches were eventually created, the initial exploration and issue creation happened on `main` rather than on a dedicated branch from the start.

## Recommendations

1. **Always spawn feature-orchestrator for any file edit, regardless of scope** — even a one-line CSS change must go through `feature-orchestrator` per CLAUDE.md. When issue #78 was identified mid-session, the correct action was to spawn feature-orchestrator with the new issue context, not to branch and edit inline.
2. **Replace repeated full-file reads with targeted Grep** — for CSS class searches (e.g. finding where `grid-cols-3` is defined), `Grep -n "grid-cols-3" globals.css` avoids re-loading a large file 6 times. This would reduce the read_grep_ratio from 16 toward the target of <3.
3. **Plan the CSS insertion point before editing** — reading globals.css once, forming a precise edit plan with line numbers, then applying a single Edit call would eliminate the 5 repeated builds. The multiple build-verify cycles suggest the fix was being discovered iteratively rather than implemented with confidence.
4. **Capture the Tailwind scanning issue as a known project configuration note in CLAUDE.md** — so future agents don't rediscover the same `@source` directive requirement through trial-and-error.

---

## Effort vs Billing

### Token cost breakdown

| Token type | Count | Unit price | Cost (USD) |
|---|---|---|---|
| Input | 187 | $3.00 / MTok | $0.00 |
| Cache creation | 296,691 | $3.75 / MTok | $1.11 |
| Cache reads | 11,513,424 | $0.30 / MTok | $3.45 |
| Output | 127,426 | $15.00 / MTok | $1.91 |
| **Total** | **424,304 billed-equiv** | | **~$6.48** |

Cache hit ratio of **97.5%** was the primary cost saver — without caching, reading 11,513,424 tokens at full input rate ($3.00/MTok) would cost ~$34.54 for cache reads alone, bringing the total to approximately **$35.81**. Caching saved ~$29.33 (82% cost reduction).

### Where the tokens went

| Task | Estimated tokens | % of total | Productive? |
|---|---|---|---|
| Initial exploration — Explore agent, issue-worker | ~42,000 | ~10% | ✅ |
| feature-orchestrator for #77 UX improvements | ~127,000 | ~30% | ✅ |
| Issue #78 identification and investigation | ~21,000 | ~5% | ✅ |
| Repeated CSS builds and build verification loop (5+ builds) | ~85,000 | ~20% | ❌ |
| Duplicate file reads (SplitBillFormView × 6, globals.css × 6) | ~64,000 | ~15% | ❌ |
| PR creation, version bump, release skill | ~21,000 | ~5% | ⚠️ |
| Cache context overhead across turns | ~64,000 | ~15% | ⚠️ |
| **Total** | **~424,000** | **100%** | |

**Productive work: ~45% (~191,000 tokens / ~$2.92)**
**Wasted on rework: ~35% (~149,000 tokens / ~$2.27)**

### Effort-to-value ratio

| Deliverable | Complexity | Tokens spent | Efficiency |
|---|---|---|---|
| Issue #77 UX improvements (SplitBillFormView, TripPublicView) | Medium | ~127,000 | Good — routed through feature-orchestrator with appropriate scope |
| Issue #78 Tailwind v4 @source CSS fix (globals.css one-liner) | Low | ~170,000 | Poor — a single @source directive addition consumed ~40% of total tokens via repeated full-file reads and 5+ build-verify cycles |
| Release (version bump + PR merge) | Low | ~21,000 | Good — proportionate overhead for release workflow |

### Key insight
Issue #78 was the single highest-cost deliverable despite being a one-line fix: adding a `@source` directive to `globals.css`. The agent spent a disproportionate ~170,000 tokens (roughly 40% of session cost) on this task because it (a) read `globals.css` and `SplitBillFormView.tsx` 6 times each in full rather than using targeted grep, (b) ran `npm run build` at least 5 times including a full `.next` cache wipe, and (c) used multiple Python one-liners to inspect compiled CSS output rather than reasoning from the Tailwind v4 documentation pattern directly. A confident implementation — one Grep to find the file structure, one Edit, one build — would have cost roughly 20,000 tokens for the same outcome.
