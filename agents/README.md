# Agents

Subagents following the Core Design Principles — orchestrators coordinate workers, workers execute procedures.

Agents are split by scope:
- `core/agents/` — platform-agnostic (orchestrators, utility workers)
- `platforms/<platform>/agents/` — platform worker implementations + platform-exclusive agents

## Core Agents (platform-agnostic)

### Orchestrators

Coordinate workers for multi-layer tasks. Gather intent, delegate in order, never write code directly.

| Agent | When to invoke |
|-------|----------------|
| `feature-orchestrator` | Build a complete feature end-to-end — domain → data → presentation |
| `backend-orchestrator` | Scaffold a backend feature — domain → data layer only |
| `pres-orchestrator` | Build presentation layer when domain is done — StateHolder → UI (mobile platforms) |

### Utility Workers

| Agent | When to invoke |
|-------|----------------|
| `issue-worker` | Create or pick up a GitHub Issue — opens issue, creates branch, updates backlog |
| `perf-worker` | Analyse agentic session performance from Claude Code transcript |
| `debug-worker` | Trace runtime errors through the layers to root cause |
| `arch-review-worker` | Audit code for Clean Architecture violations |

## Platform Workers

Each platform implements this standard worker set:

| Worker | Layer | Responsibility |
|--------|-------|----------------|
| `domain-worker` | Domain | Entities, repository interfaces, use cases, domain services |
| `data-worker` | Data | DTOs/Responses, mappers, data sources, repository impls |
| `presentation-worker` | Presentation | StateHolder (ViewModel/BLoC) — or full UI for web |
| `test-worker` | Testing | Unit + integration tests for any layer |
| `ui-worker` | UI | UI layer bound to StateHolder contract (mobile platforms only) |

Platform-exclusive agents live alongside — e.g. iOS adds `pres-orchestrator` override, `test-orchestrator`, `ui-worker`, `pr-review-worker`.

## Orchestration Model

```
feature-orchestrator (core)
  → domain-worker    (platform implementation)
  → data-worker      (platform implementation)
  → presentation-worker (platform implementation)
     — or for mobile —
  pres-orchestrator (core)
    → presentation-worker  (StateHolder)
    → ui-worker            (UI binding)
```

Workers are resolved by name at runtime from `.claude/agents/`. The correct platform implementation
is wired by `setup-symlinks.sh --platform=<p>` at project setup time.

## Extension

Add project-specific logic without touching shared files:
- Create `.claude/agents.local/extensions/{agent-name}.md` (delta only)
- Each agent ends with an extension hook that reads this file if present
