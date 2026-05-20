---
name: builder-plan-feature
description: Plan then build a feature — optionally resolves external inputs (Jira, PRD, Figma, local .md), gathers intent via builder-feature-orchestrator, runs the convergence planning loop (spawning only the needed layer planners per round), shows an interactive approval prompt, then executes with builder-feature-worker on approval.
user-invocable: true
allowed-tools: Agent, AskUserQuestion, Bash, Read, WebFetch
---

## Preflight — Check Existing Runs

Before resolving any inputs, check for existing runs — both completed plans and partial-planning runs interrupted before synthesis:

```bash
find "$(git rev-parse --show-toplevel)/.claude/agentic-state/runs" -maxdepth 2 -name "plan.md" 2>/dev/null
find "$(git rev-parse --show-toplevel)/.claude/agentic-state/runs" -maxdepth 2 -name "figma-groups.json" 2>/dev/null
```

If neither found → proceed to Step 0.

**Partial-planning run detected** — if `figma-groups.json` exists in a run dir but no `plan.md` alongside it:
- Set `run_dir` to the parent directory of the found `figma-groups.json`
- Read `figma-groups.json` to restore `figma_groups`
- Read all `findings-round-*.json` files in that run dir (sorted by round number) to restore `all_findings` and determine last completed `round`
- Reconstruct `visited` from the union of all `findings-round-*.json` `visited` arrays
- Call `AskUserQuestion`:

```
question    : "A planning session was interrupted before the plan was written. Resume it?"
header      : "Resume Planning"
multiSelect : false
options     :
  - label: "Resume", description: "Restore figma groups and planner findings, re-enter the planning loop"
  - label: "Discard", description: "Delete the partial run and start fresh"
```

**Resume** → skip Steps 0–1.5b, set `round = <last completed round> + 1`, re-enter Step 2 with restored state.
**Discard** → `rm -rf "<run_dir>"`, proceed to Step 0.

If only `plan.md` found → call `AskUserQuestion`:

```
question    : "Existing plans found in runs/. What would you like to do?"
header      : "Resume or Start"
multiSelect : false
options     :
  - label: "Continue existing", description: "Pick an existing plan to review and resume"
  - label: "Start fresh",       description: "Plan and build a new feature from scratch"
```

**Start fresh** → proceed to Step 0.

**Continue existing** → read the `feature` name and `status` from the frontmatter of each found `plan.md`. Also read `state.json` alongside each plan to get `completed_artifacts` count. Call `AskUserQuestion` with one option per run (up to 4):

```
question    : "Which plan would you like to resume?"
header      : "Existing Plans"
multiSelect : false
options     : one per found plan — label: <feature>, description: "<completed count> artifacts done · status: <status>"
```

After the user selects a run:

1. Derive `run_dir` from the path of the selected `plan.md` — take its parent directory. Do not reconstruct from feature name.
2. Read `plan.md`, `context.md`, and `state.json` from `run_dir`.
3. Proceed to **Step P — Figma Input Repair**, then **Step R**, then Step 4.

## Step P — Figma Input Repair (Resume path only — runs before Step R)

Check for existing Figma artifacts in the selected run directory:

```bash
find "<run_dir>/inputs" -name "figma-*.md" 2>/dev/null | sort
```

**No files found** → no Figma resources available. Proceed to Step R.

**Files found** — Figma resources exist. Work through P1–P3 below.

### P1 — Backfill missing screenshots

For each `figma-*.md` file, read its `screenshot:` frontmatter value. If it starts with `http` (URL, not a local path) and no corresponding `.png` exists on disk:

```bash
curl -sL "<screenshot_url>" -o "<run_dir>/inputs/figma-<slug>-screenshot.png"
```

After download, update the `.md` frontmatter in-place:
- `screenshot:` → local `.png` path
- `screenshot_url:` → original URL (add if not present)

Report: `Backfilled N / M already local / K failed`.

### P2 — Reconstruct figma-groups.json (skip if already exists)

```bash
ls "<run_dir>/figma-groups.json" 2>/dev/null
```

If missing: read every `figma-*.md` frontmatter and group entries by `parent_frame`. Build and write `figma-groups.json`:

```json
[
  {
    "screen": "<parent_frame>",
    "states": [
      { "state": "<state>", "file": "<abs-path>", "layout_file": "<abs-path>", "screenshot": "<abs-path-or-null>" }
    ]
  }
]
```

Store result as `figma_groups` for use in P3.

### P3 — Offer re-run

Read `state.json`. Identify Screen and Component artifacts already in `completed_artifacts`.

Call `AskUserQuestion`:

```
question    : "Figma resources found in inputs/ (<N> frames, <M> screenshots ready).
               <X> UI artifacts were built without Figma reference. Re-run them now with full Figma layout + screenshots?"
header      : "Figma Reference"
multiSelect : false
options     :
  - label: "Re-run UI with Figma", description: "Reset Screen/Component artifacts and rebuild using Figma layout + screenshots"
  - label: "Skip",                 description: "Proceed to review without re-running UI artifacts"
```

**Skip** → proceed to Step R.

**Re-run UI with Figma:**
1. Remove all Screen and Component artifact names from `completed_artifacts` in `state.json`. Reset their `Progress` cells in `plan.md` to `pending`.
2. Spawn `builder-pres-planner` with `figma_groups` from P2 to produce an updated `### Figma Alignment` table.
3. Update the `## Figma Alignment` section in `context.md` with the planner's output (replace existing section or append if absent).
4. Skip Step R — proceed directly to Step 5 (Execute).

## Step R — Review and Adjust (Resume path only)

Spawn `builder-feature-orchestrator` with mode `review-resume`:

> **Mode: review-resume**
>
> **plan.md**
> \<content\>
>
> **context.md**
> \<content\>
>
> **Completed artifacts:** \<comma-separated list from state.json completed_artifacts, or "none"\>

Wait for the orchestrator's decision block:

- **`Decision: resume-as-is`** → proceed to Step 4 using the existing plan.md and context.md.
- **`Decision: resume-updated`** → archive the current files before writing the updated content:

  ```bash
  # Determine next version number
  N=$(ls "<run_dir>/plan-v"*.md 2>/dev/null | wc -l | tr -d ' ')
  N=$((N + 1))
  mv "<run_dir>/plan.md"    "<run_dir>/plan-v${N}.md"
  mv "<run_dir>/context.md" "<run_dir>/context-v${N}.md"
  ```

  Then write the updated `plan.md` and `context.md` from the orchestrator's response. The worker always reads `plan.md` as the active plan; prior versions are preserved as `plan-v1.md`, `plan-v2.md`, etc. Proceed to Step 4.

## Step 0 — Classify Inputs

Parse all arguments passed to this skill. Classify each by pattern:

| Pattern | Type | Action |
|---|---|---|
| URL containing `jira` or `atlassian`, or bare ticket ID (e.g. `PROJ-123`) | Jira ticket | Fetch inline via Atlassian MCP |
| URL containing `figma.com` | Figma design | Store in `pending_figma_urls` — fetch in Step 1.5 |
| Any other URL | PRD / doc | Fetch inline via `WebFetch` |
| Path ending in `.md` | Local file | Read inline via `Read` |

If no arguments are provided, skip this step — proceed to Step 1 with `resolved_inputs = []` and `pending_figma_urls = []`.

Fetch all non-Figma inputs inline now. Collect:
- `resolved_inputs` — successfully fetched non-Figma items: `{ type, source, content }`
- `pending_figma_urls` — Figma URLs deferred until feature name is known after Step 1
- `failed_inputs` — non-Figma items that could not be fetched: `{ type, source, reason }`

If `failed_inputs` is non-empty, call `AskUserQuestion`:

```
question    : "Some inputs couldn't be fetched: <list each with reason>. What would you like to do?"
header      : "Input Fetch"
multiSelect : false
options     :
  - label: "Continue",         description: "Proceed with the inputs that were successfully resolved"
  - label: "Provide manually", description: "Paste or describe the missing content before continuing"
  - label: "Cancel",           description: "Stop and retry after fixing the inputs"
```

**Continue** → proceed with `resolved_inputs` as-is.

**Provide manually** → for each item in `failed_inputs`, ask the user to paste or describe the content. Append each to `resolved_inputs`. Then proceed.

**Cancel** → stop.

## Step 1 — Gather Intent

Spawn `builder-feature-orchestrator` with mode `gather-intent`:

> **Mode: gather-intent**
>
> <if resolved_inputs or pending_figma_urls is non-empty, include the following block — otherwise omit>
> **Resolved Inputs:**
> <for each non-Figma item: "### <type> — <source>\n<content>">
> <if pending_figma_urls is non-empty: "### Figma designs (pending fetch)\n<list each URL — will be fetched after feature name is confirmed>">
>
> Ask the user for feature intent. Return a `Decision: spawn-planners` block when done.

Wait for the orchestrator to return. Extract the `Decision: spawn-planners` block. Note the `feature` name from the orchestrator output.

Initialize:
- `visited` = [] (empty set of explored layers)
- `all_findings` = [] (accumulated planner findings across all rounds)
- `round` = 1

## Step 1.5 — Fetch Figma Inputs (skip if `pending_figma_urls` is empty)

Now that `feature` is known, resolve the run directory:

```bash
echo "$(git rev-parse --show-toplevel)/.claude/agentic-state/runs/<feature>"
```

Spawn one `builder-figma-worker` per URL in `pending_figma_urls` — pass `figma_url`, `feature`, and `run_dir`. **Spawn all workers in parallel** (single Agent tool call).

Collect results from all workers:
- `figma_resolved` — workers that returned `## Figma Worker Output` blocks
- `figma_sections` — workers that returned `## Figma Section Detected` blocks
- `figma_failed` — failed fetches: `{ source, reason }`

**If `figma_sections` is non-empty** — expand each section into individual frame workers. For each section, spawn one `builder-figma-worker` per child frame **in parallel** (single Agent call across all children of all sections) — pass `figma_url` constructed as `https://www.figma.com/design/<fileKey>?node-id=<child_id>`, same `feature` and `run_dir`. Collect results and merge into `figma_resolved` and `figma_failed`.

If `figma_failed` is non-empty, call `AskUserQuestion`:

```
question    : "Some Figma frames couldn't be fetched: <list each with reason>. What would you like to do?"
header      : "Figma Fetch"
multiSelect : false
options     :
  - label: "Continue",  description: "Proceed with the frames that were successfully fetched"
  - label: "Cancel",    description: "Stop and retry after fixing the Figma inputs"
```

### Step 1.5b — Verify Figma Grouping (skip if `figma_resolved` is empty)

Group `figma_resolved` outputs by `parent_frame`:

```
<parent_frame A> → [{ state, file, layout_file, screenshot }, ...]
<parent_frame B> → [{ state, file, layout_file, screenshot }, ...]
```

Call `AskUserQuestion`:

```
question    : "Figma frames fetched. We grouped them into screens based on their parent frame in Figma.
               Does this look correct?

               <for each group:>
               • <parent_frame> — states: <comma-separated state names>
               "
header      : "Figma Screens"
multiSelect : false
options     :
  - label: "Correct",  description: "Grouping looks right — proceed to planning"
  - label: "Adjust",   description: "The grouping needs changes before we continue"
```

**Correct** → store as `figma_groups` and proceed.

**Adjust** → ask the user to describe corrections (which frames belong to which screen, any renames). Apply to `figma_groups`. Then proceed.

`figma_groups` structure carried forward:
```
[
  {
    screen: "<parent_frame>",
    states: [
      { state: "<state>", file: "<abs-path-to-.md>", layout_file: "<abs-path-to--layout.jsx>", screenshot: "<url>" },
      ...
    ]
  },
  ...
]
```

**Persist figma_groups to disk** — write immediately after grouping is confirmed:

```bash
cat > "<run_dir>/figma-groups.json" << 'EOF'
<figma_groups as JSON>
EOF
```

Initialize:
- `visited` = [] (empty set of explored layers)
- `all_findings` = [] (accumulated planner findings across all rounds)
- `round` = 1

## Step 2 — Planning Convergence Loop

Repeat until the orchestrator returns `Decision: converged` or `Decision: blocked`.

### 2a — Spawn planners for this round

From the current `Decision: spawn-planners` block, read the `spawn:` list. Spawn each listed planner **in parallel** (single Agent tool call with all planners in that round):

- `builder-domain-planner` — if `domain` is in the spawn list
- `builder-data-planner` — if `data` is in the spawn list
- `builder-pres-planner` — if `pres` is in the spawn list
- `builder-app-planner` — if `app` is in the spawn list

Pass to each planner: feature name, platform, module-path (from orchestrator's gather-intent output).

For `builder-pres-planner` specifically — if `figma_groups` was established in Step 1.5b or P2, also pass:
- The full `figma_groups` structure (screen → states + file paths) — do NOT inline file contents

Wait for all planners in this round to complete.

Add each spawned layer to `visited`. Append each planner's full findings block to `all_findings`.

**Persist findings to disk** — write after every round completes:

```bash
cat > "<run_dir>/findings-round-<N>.json" << 'EOF'
{
  "round": <N>,
  "visited": [<visited list>],
  "findings": "<all_findings for this round, escaped>"
}
EOF
```

### 2b — Send findings to orchestrator

Spawn `builder-feature-orchestrator` with mode `process-findings`:

> **Mode: process-findings**
>
> Round: <N>
> Visited layers: <comma-separated list from visited set>
>
> **Accumulated Findings:**
> <paste full all_findings content>

Wait for the orchestrator's decision block.

- **`Decision: spawn-planners`** → increment `round`, go back to 2a
- **`Decision: converged`** → proceed to Step 3
- **`Decision: blocked`** → present the orchestrator's question to the user via `AskUserQuestion`, send the answer back to orchestrator as a follow-up `process-findings` call, then re-evaluate

**Max rounds guard:** If `round` reaches 4 without convergence, stop the loop and surface to the user:
> "Planning could not converge after 3 rounds. Open questions: <list from last blocked decision>. Please clarify before retrying."

## Step 3 — Synthesize Plan

Spawn `builder-feature-orchestrator` with mode `synthesize`:

> **Mode: synthesize**
>
> **All Accumulated Findings:**
> <paste full all_findings content>

Wait for the orchestrator to return the plan summary and write plan.md + context.md.

## Step 4 — Approve

Call `AskUserQuestion` immediately after synthesis — do NOT describe choices in prose:

```
question    : "What would you like to do with this plan?"
header      : "Plan"
multiSelect : false
options     :
  - label: "Approve",      description: "Execute this plan with builder-feature-worker"
  - label: "Discuss more", description: "I have questions or changes before this plan is finalized"
  - label: "Discard",      description: "Cancel and delete this plan"
```

**Approve** → proceed to Step 5.

**Discuss more** → address the engineer's questions inline. If the plan itself needs revision, re-run Step 3 (re-synthesize) with the updated requirements added to the findings context. Then call `AskUserQuestion` again with the same three options.

**Discard** → delete the most recent run directory:

```bash
rm -rf "$(git rev-parse --show-toplevel)/.claude/agentic-state/runs/<feature>"
```

Stop.

## Step 5 — Execute

Update `status` in `plan.md` frontmatter from `pending` to `approved`.

Read `plan.md` and `context.md` from the run directory. Spawn `builder-feature-worker`:

> Approved plan ready. Pre-loaded context below — do not re-read plan.md, context.md, or state.json.
>
> **plan.md**
> \<content\>
>
> **context.md**
> \<content\>
>
> \<if ## Figma Alignment section is present in context.md, include — otherwise omit\>
> **Figma Instruction:** For every Screen and Component artifact, before writing any code:
> 1. Look up the artifact in the `## Figma Alignment` table in context.md above to get its Figma Files list
> 2. `Read` each `.md` file — extract components, states, interactions, tokens, annotations
> 3. `Read` each `layout_file` JSX — full file, no truncation
> 4. `Read` each `screenshot` `.png` — this is mandatory, not optional; the Read tool renders images and visual inspection is required before implementing
>
> Proceed directly to the first pending artifact.

**Checkpoint loop:** if the worker returns `## Context Checkpoint` instead of `## Feature Complete`, immediately re-spawn a fresh `builder-feature-worker` without user interaction:

> Resuming from context checkpoint. Pre-loaded context below — do not re-read plan.md, context.md, or state.json.
>
> **plan.md**
> \<content — re-read from disk\>
>
> **context.md**
> \<content — re-read from disk\>
>
> **Resume from:** \<next_artifact from checkpoint block\>
> **State file:** \<state_file from checkpoint block\>
>
> \<if ## Figma Alignment section is present in context.md, include — otherwise omit\>
> **Figma Instruction:** For every Screen and Component artifact, before writing any code:
> 1. Look up the artifact in the `## Figma Alignment` table in context.md above to get its Figma Files list
> 2. `Read` each `.md` file — extract components, states, interactions, tokens, annotations
> 3. `Read` each `layout_file` JSX — full file, no truncation
> 4. `Read` each `screenshot` `.png` — mandatory, not optional; visual inspection required before implementing
>
> Read state.json, skip completed artifacts, proceed directly to next_artifact.

Repeat until the worker returns `## Feature Complete`.

## Step 6 — Unit Tests

Read `state.json` from the run directory. Extract all paths under `domain`, `data`, and `presentation` keys — these are the unit-testable artifacts. Skip `ui` and `app`.

Call `AskUserQuestion` immediately — do NOT describe choices in prose:

```
question    : "Run unit tests for created artifacts?"
header      : "Unit Tests"
multiSelect : false
options     :
  - label: "Yes",  description: "Generate unit tests for all created artifacts via builder-test-worker"
  - label: "Skip", description: "I'll run tests manually later"
```

**Yes** → spawn `builder-test-worker`:

> target: <comma-separated artifact paths from state.json>
> platform: <platform from plan.md frontmatter>

**Skip** → surface the paths as a reminder:

> Tests not generated. Run when ready:
> `/builder-test-worker` — targets: <paths>
