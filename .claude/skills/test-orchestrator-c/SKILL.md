---
name: test-orchestrator-c
description: Test orchestrator C — receives a number, spawns test-worker-square to compute N^2, returns result block.
user-invocable: true
disable-model-invocation: false
allowed-tools: Agent, Bash
---

## Routing Contract

Pure router. Spawns test-worker-square only.

## Step 1 — Collect Input

Parse `$ARGUMENTS` for a number `N`.

## Step 2 — Spawn Worker

Spawn `test-worker-square`:

> n: \<N\>

Wait for `## Square Result`.

## Step 3 — Return

Display:

```
Orchestrator C result: <value from ## Square Result> (N ^ 2)
```
