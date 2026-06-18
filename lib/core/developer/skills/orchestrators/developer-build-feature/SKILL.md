---
name: developer-build-feature
description: Universal feature executor — accepts a run_dir, plan.md, or any design/spec document. If the input already has a batches frontmatter (produced by /developer-plan-feature), executes directly. Otherwise routes through /developer-plan-feature first to produce the structured plan, then executes. Entry point for post-brainstorming execution and all /developer-plan-* outputs.
user-invocable: true
disable-model-invocation: true
allowed-tools: Agent, AskUserQuestion, Bash, Read, Skill
---

## Routing Contract

This skill is a pure router. Its only permitted direct operations:
- `Bash` — resolving and validating the input path
- `Read` — reading plan.md before each worker spawn
- `AskUserQuestion` — unit test prompt in Step 3

Never read source files, search the codebase, or write code. All planning is delegated to `/developer-plan-feature`; all implementation to worker agents.

## Step 1 — Resolve Plan

`$ARGUMENTS` is a path to one of: a **run directory**, a **`plan.md` file**, or any **design/spec document** (e.g. a brainstorming output).

If `$ARGUMENTS` is empty, stop:
> No plan provided. Pass a run_dir, plan.md, or spec path. Run `/developer-plan-feature` to create a plan first.

```bash
if [ -d "$ARGUMENTS" ]; then
  grep "^batches:" "$ARGUMENTS/plan.md" 2>/dev/null | head -1
elif [ -f "$ARGUMENTS" ]; then
  grep "^batches:" "$ARGUMENTS" 2>/dev/null | head -1
fi
```

**If `batches` is present** → derive `run_dir`:
- Directory → `run_dir = $ARGUMENTS`
- File → `run_dir = dirname($ARGUMENTS)`

Proceed to Step 2.

**If `batches` is absent** (design doc, spec, or bare idea) → invoke `/developer-plan-feature` via the Skill tool, passing `$ARGUMENTS` verbatim.

Wait for it to complete. Read the `## Plan Output` block — extract `run_dir`.

If no `## Plan Output` is present (plan was discarded or canceled), stop.

Proceed to Step 2 with the `run_dir` from `## Plan Output`.

## Step 2 — Execute

`plan.md` is the single source of truth for execution state — update batch statuses live as work progresses.

Read `batches` from `<run_dir>/plan.md` frontmatter. Process each batch in `id` order where `status != complete`.

**For each batch:**

**2a — Mark in progress.** Set the batch's `status` to `in_progress` in `plan.md` frontmatter.

**2b — Determine worker by `layer`:**
- `layer: ui` → `developer-ui-worker`
- all others (`domain`, `data`, `pres`, `app`) → `developer-feature-worker`

**2c — Spawn the worker:**

> run_dir: \<run_dir\>
> batch: \<batch_id\>

**2d — Checkpoint loop.** If the worker returns `## Context Checkpoint`, re-spawn immediately with the same prompt.

Repeat until the worker returns `## Layers Complete` (feature-worker) or `## Feature Complete` (ui-worker).

**2e — Mark complete.** Set the batch's `status` to `complete` in `plan.md` frontmatter.

Proceed to Step 3 after all batches are complete.

## Step 3 — Unit Tests

Read `## Steps` from plan.md. Extract artifact names for all steps with `layer: domain`, `layer: data`, or `layer: pres` — these are the unit-testable artifacts. Skip `ui` and `app`.

If no steps are present (plan not produced by `developer-plan-feature`), skip this step.

Call `AskUserQuestion` immediately — do NOT describe choices in prose:

```
question    : "Run unit tests for created artifacts?"
header      : "Unit Tests"
multiSelect : false
options     :
  - label: "Yes",  description: "Generate unit tests for all created artifacts via developer-test-worker"
  - label: "Skip", description: "I'll run tests manually later"
```

**Yes** → spawn `developer-test-worker`:

> target: <comma-separated artifact names from testable steps>
> platform: <platform from plan.md frontmatter>

**Skip** → surface the artifacts as a reminder:

> Tests not generated. Run when ready:
> `/developer-test-worker` — targets: <artifact names>
