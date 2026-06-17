---
name: test-orchestrator-b
description: Test orchestrator B — receives a number, spawns test-worker-double to compute N*2, returns result block.
user-invocable: true
disable-model-invocation: true
allowed-tools: Agent, Bash
---

## Routing Contract

Pure router. Spawns test-worker-double only.

## Step 1 — Collect Input

Parse `$ARGUMENTS` for a number `N`.

## Step 2 — Spawn Worker

Spawn `test-worker-double`:

> n: \<N\>

Wait for `## Double Result`.

## Step 3 — Return

Display:

```
Orchestrator B result: <value from ## Double Result> (N * 2)
```
