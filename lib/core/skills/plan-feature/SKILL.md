---
name: plan-feature
description: Plan then build a feature — runs feature-planner, shows an interactive approval prompt, then executes with feature-orchestrator on approval.
allowed-tools: Agent, AskUserQuestion, Bash
---

## Step 1 — Plan

Spawn `feature-orchestrator` using the Agent tool with the following prompt:

> **Trigger: plan-first**
>
> Spawn `feature-planner`. Wait for it to complete and return — do not do anything else.

Wait for the orchestrator to return before proceeding.

## Step 2 — Approve

Call `AskUserQuestion` immediately after the planner returns — do NOT describe choices in prose:

```
question    : "What would you like to do with this plan?"
header      : "Plan"
multiSelect : false
options     :
  - label: "Approve",      description: "Execute this plan with feature-worker"
  - label: "Discuss more", description: "I have questions or changes before this plan is finalized"
  - label: "Discard",      description: "Cancel and delete this plan"
```

**Approve** → proceed to Step 3.

**Discuss more** → address the engineer's questions or requested changes inline, then call `AskUserQuestion` again with the same three options. If the plan itself needs rewriting, re-spawn `feature-planner`.

**Discard** → locate and delete the most recent run directory under `.claude/agentic-state/runs/` and stop.

## Step 3 — Execute

Spawn `feature-orchestrator` using the Agent tool with the following prompt:

> **Trigger: execute-approved-plan**
>
> The plan has been approved by the user. Locate the most recent `plan.md` in `.claude/agentic-state/runs/`, read it and its sibling `context.md`, update `status` to `approved` in `plan.md` frontmatter, then spawn `feature-worker` with both injected inline.
