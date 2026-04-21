---
name: scaffold
description: Design and scaffold a new agentic component — skill, worker, orchestrator, or persona. Routes through arch-review-orchestrator which runs agent-scaffold-worker then verifies the new file with arch-review-worker.
user-invocable: true
tools: Agent
---

## Steps

Invoke `arch-review-orchestrator` with:

```
Intent: scaffold
```

The orchestrator delegates to agent-scaffold-worker which gathers all intent interactively.
