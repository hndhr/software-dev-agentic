---
name: migrate
description: Migrate an existing agent or skill file to comply with software-dev-agentic conventions. Routes through arch-review-orchestrator which runs agent-migrate-worker then verifies the fix with arch-review-worker.
user-invocable: true
tools: Agent
---

## Arguments

```
/migrate [file]
```

- `file` — optional. Path to the agent or skill file to migrate. If omitted, the orchestrator will ask.

## Steps

Invoke `arch-review-orchestrator` with:

```
Intent: migrate <file>
```

If no file was provided, omit it — the orchestrator will pass through to agent-migrate-worker which will ask interactively.
