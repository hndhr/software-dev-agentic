---
name: test-orchestrator-a
description: Test orchestrator — spawns test-orchestrator-b and test-orchestrator-c in parallel, collects their results, and shows a summary.
user-invocable: true
disable-model-invocation: true
allowed-tools: Agent, AskUserQuestion, Bash, test-orchestrator-b, test-orchestrator-c
---

## Routing Contract

Pure router. Permitted direct operations:
- `Bash` — read input number from arguments
- `AskUserQuestion` — collect input if not provided
- `Agent` — spawn test-orchestrator-b and test-orchestrator-c

## Step 1 — Collect Input

Parse `$ARGUMENTS` for a number `N`.

If not provided, call `AskUserQuestion`:

```
question    : "Provide a number to process."
header      : "Input"
multiSelect : false
options     :
  - label: "7",   description: "Use 7"
  - label: "12",  description: "Use 12"
  - label: "42",  description: "Use 42"
```

## Step 2 — Execute B and C

Execute both skills using the Skill tool:

- `test-orchestrator-b` with args: `n: <N>`
- `test-orchestrator-c` with args: `n: <N>`

Wait for both to return `## Orchestrator B Result` and `## Orchestrator C Result`.

## Step 3 — Show Summary

Display:

```
Input: <N>

Orchestrator B (double): <result from B>
Orchestrator C (square): <result from C>
```
