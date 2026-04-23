---
name: plan-feature
description: Plan then build a feature — invokes feature-planner for reviewable planning, then hands off to feature-orchestrator for execution.
allowed-tools: Agent
---

1. Invoke the `feature-planner` agent. Pass no arguments — the agent gathers intent interactively.

2. After `feature-planner` completes, invoke the `feature-orchestrator` agent. Pass no arguments — it picks up the approved `plan.md` automatically in its pre-flight.
