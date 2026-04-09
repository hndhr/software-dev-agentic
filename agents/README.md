# Agents

Subagents following the Core Design Principles — orchestrators coordinate workers, workers execute procedures.

Copy to `.claude/agents/` in the actual project (or symlink via submodule).

## Orchestrators

Coordinate multiple workers for multi-layer tasks. Gather intent, read context, delegate in order. Never write code directly.

| Agent | When to invoke |
|-------|---------------|
| `feature-orchestrator` | Build a complete feature end-to-end — domain, data, and presentation layers |
| `backend-orchestrator` | Scaffold a full-stack backend feature — DB DataSource, Repository, Use Case, Server Action |

## Workers

Domain specialists. Validate preconditions, pick the right skill, execute. Can be invoked directly for single-layer tasks or spawned by an orchestrator.

| Agent | Layer | When to invoke |
|-------|-------|---------------|
| `domain-worker` | Domain | Create/update entities, repository interfaces, use cases, domain services |
| `data-worker` | Data | Create/update DTOs, mappers, data sources (remote or DB), repository impls |
| `presentation-worker` | Presentation | Create/update ViewModel hooks, Views, Server Actions, routes, DI wiring |
| `test-worker` | Testing | Write tests for any layer — auto-selects test type by layer |
| `arch-review-worker` | Cross-layer | Audit code for Clean Architecture violations |
| `debug-worker` | Cross-layer | Trace runtime errors through the layers to root cause |

## Natural Language Routing

Describe intent — Claude routes to the right agent automatically.

> "Create the leave request feature" → `feature-orchestrator`
> "Add an entity for Employee" → `domain-worker`
> "Write tests for LeaveRepositoryImpl" → `test-worker`
> "Why is my form submission failing silently?" → `debug-worker`

## Extension

Add project-specific logic without touching shared files:
- Create `.claude/agents.local/extensions/{agent-name}.md` (delta only)
- Each agent ends with an extension hook that reads this file if present
