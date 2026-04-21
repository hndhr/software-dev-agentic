---
name: audit
description: Audit structural integrity and convention compliance of a persona, agent, or skill. Routes through arch-review-orchestrator which runs agent-audit-worker and arch-review-worker in parallel.
user-invocable: true
tools: Agent
---

## Arguments

```
/audit [scope]
```

- `scope` — optional. A persona name (`builder`, `detective`), a file path, or `full`. If omitted, the orchestrator will ask.

## Steps

Invoke `arch-review-orchestrator` with:

```
Intent: audit <scope>
```

If no scope was provided, omit it — the orchestrator will ask.
