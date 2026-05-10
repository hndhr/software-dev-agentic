---
name: builder-build-feature
description: Build or update a feature across Clean Architecture layers. Routes through builder-feature-orchestrator agent — resumes an existing run or starts a new one.
user-invocable: true
allowed-tools: Bash, Read, AskUserQuestion, Agent
---

## Arguments

`$ARGUMENTS` — optional feature description.

## Steps

1. Find existing runs:
   ```bash
   find "$(git rev-parse --show-toplevel)/.claude/agentic-state/runs" -name "state.json" 2>/dev/null
   ```

2. **If runs exist:** call `AskUserQuestion`:
   ```
   question    : "Which feature would you like to work on?"
   header      : "Feature"
   multiSelect : false
   options     :
     (one entry per found run, values from state.json)
     - label: "Resume: <feature>", description: "Next artifact: <next_artifact>"
     (always include)
     - label: "Start new feature", description: "Begin a fresh feature from scratch"
   ```
   - If user picks **Resume** → read `plan.md`, `context.md`, and `state.json` for that run → go to step 3
   - If user picks **Start new feature** → go to step 4

   **If no runs exist** → go to step 4

3. **Resume — spawn `builder-feature-orchestrator` using the Agent tool with pre-loaded context** (substitute actual file contents):

   > **Trigger: resume**
   > Feature: <feature name from state.json>
   >
   > Pre-loaded context — do not re-read plan.md, context.md, or state.json:
   >
   > **plan.md**
   > <content>
   >
   > **context.md**
   > <content>
   >
   > **state.json**
   > <content>
   >
   > Spawn `builder-feature-worker` directly with this context. Skip Phase 0 and planning.

4. **New** — call `AskUserQuestion`:
   ```
   question    : "How would you like to proceed?"
   header      : "Feature"
   multiSelect : false
   options     :
     - label: "Plan first",     description: "Run builder-feature-planner for a reviewable plan before building"
     - label: "Build directly", description: "Skip planning — gather intent inline and go straight to building"
   ```

   - **Plan first** → spawn `builder-feature-orchestrator` agent:
     > **Trigger: plan-first**
     > Feature: <$ARGUMENTS, or empty if not provided>
     >
     > Spawn `builder-feature-planner`. Wait for it to complete and return — do not do anything else.

     After the agent returns, call `AskUserQuestion`:
     ```
     question    : "What would you like to do with this plan?"
     header      : "Plan"
     multiSelect : false
     options     :
       - label: "Approve",      description: "Execute this plan with builder-feature-worker"
       - label: "Discuss more", description: "I have questions or changes before this plan is finalized"
       - label: "Discard",      description: "Cancel and delete this plan"
     ```
     - **Approve** → spawn `builder-feature-orchestrator` agent with `Trigger: execute-approved-plan`
     - **Discuss more** → discuss inline, re-spawn `builder-feature-planner` if needed, repeat approval question
     - **Discard** → locate and delete the most recent run directory under `.claude/agentic-state/runs/` and stop

   - **Build directly** → spawn `builder-feature-orchestrator` agent:
     > **Trigger: build-directly**
     > Feature: <$ARGUMENTS, or empty if not provided>
     >
     > No existing run. If no feature description was given, ask the user for it. Then proceed directly to Phase 0.
