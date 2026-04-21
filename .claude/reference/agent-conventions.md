# Agent Conventions Reference

Internal reference for `.claude/agents/` tooling. Grep into this file by section heading — never read in full.

---

## Component Types

Decision tree — apply in order:

**Skill** — single focused procedure, no branching, under ~30 lines of instruction. No decision-making; the calling agent decides which skill to invoke.

**Worker** — specialist in one domain or CLEAN layer. Sequences skills, handles branching and edge cases, enforces preconditions. No coordination of other agents.

**Orchestrator** — coordinates multiple workers across phases. Never writes files directly — all writes go through workers. Has `agents:` frontmatter field.

**New Persona** — multiple related agents forming a coherent new workflow category not covered by existing personas (`builder`, `detective`, `tracker`, `auditor`, `installer`). Requires: new subdirectory + `.pkg` file + at least one worker or orchestrator.

---

## Skill Invocation Types

| Type | Config | Who triggers | Use for |
|---|---|---|---|
| **A — Regular** | `user-invocable: false` | Worker (agent) only | Standard build/update procedures |
| **B — Destructive** | `disable-model-invocation: true` | User only | Pure bash, destructive or side-effect operations |
| **T — Trigger** | `user-invocable: true` + uses `Agent` tool | User only | Entry point that spawns an agent workflow |
| **U — Utility** | `user-invocable: true`, no `Agent` tool | User only | Self-contained interactive tool, runs with model |

---

## Skill Scopes

| Scope | Location | Ships downstream? |
|---|---|---|
| **Toolkit** | `lib/core/skills/` | Yes — all platforms |
| **Platform-contract** | `lib/platforms/<platform>/skills/contract/` | Yes — matching platform |
| **Platform-only** | `lib/platforms/<platform>/skills/` (flat) | Yes — matching platform only |
| **Repo** | `.claude/skills/` | No — internal tooling only |

---

## Valid Type × Scope Combinations

| Scope | A — Regular | B — Destructive | T — Trigger | U — Utility |
|---|---|---|---|---|
| Toolkit | — | — | ✓ | ✓ |
| Platform-contract | ✓ | — | — | — |
| Platform-only | ✓ | ✓ | — | — |
| Repo | ✓ | — | ✓ | ✓ |

---

## Agent Scopes

| Scope | Location | Ships downstream? |
|---|---|---|
| **Persona agent** | `lib/core/agents/<persona>/` | Yes — all platforms |
| **Platform agent** | `lib/platforms/<platform>/agents/` | Yes — matching platform only |
| **Repo agent** | `.claude/agents/` | No — internal tooling only |

---

## Frontmatter — Required Fields

**All agents:** `name`, `description`, `model`, `tools`

**Workers additionally:** `user-invocable: true|false`

**Orchestrators additionally:** `agents:` listing only the workers actually spawned

**Skills:** `name`, `description`, `user-invocable: false` (or omit only for user-facing skills)

---

## Model Selection

| Role | Model | When |
|---|---|---|
| Orchestrator | `sonnet` | Always |
| Worker | `sonnet` | Default — any reasoning, decision-making, or architectural judgment |
| Worker | `haiku` | Only for truly mechanical leaf tasks with no architectural judgment |

---

## Worker Required Sections

All workers must have these sections in their body:

| Section | Purpose |
|---|---|
| `## Search Rules` | Grep-before-Read decision gate table |
| `## Extension Point` | Hook at end: check `agents.local/extensions/<name>.md` |

Workers must also:
- Validate preconditions before writing (`create-*` → target must NOT exist; `update-*` → target MUST exist)
- Glob + Grep verify each output file before listing paths in the report

---

## Orchestrator Required Sections

| Section | Purpose |
|---|---|
| Phase sections (`## Phase N`) | One per coordination phase |
| State file write | After each phase: `.claude/agentic-state/runs/<feature>/state.json` |
| Output validation | Glob each worker output path — STOP if missing |
| `## Extension Point` | Hook at end |

Orchestrators never use Edit, Write, or file-writing Bash — zero inline work.

---

## Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Worker | `<domain>-worker.md` | `agent-scaffold-worker.md` |
| Orchestrator | `<domain>-orchestrator.md` | `arch-review-orchestrator.md` |
| Skill directory | `<layer>-<action>-<target>` | `domain-create-entity` |

---

## Platform-Agnosticism Rules

Applies to all files under `lib/core/agents/`. Critical violation if the body contains:

- Hardcoded platform paths: `src/domain/`, `src/data/`, `Talenta/Module/`, `lib/`, `app/`
- Framework references as rules: `React`, `Next.js`, `RxSwift`, `UIKit`, `BLoC`, `axios`
- Language-specific syntax as rules: `'use client'`, `readonly` (TypeScript), `BehaviorRelay`

Platform knowledge must be delegated to a skill in `related_skills` — never embedded inline.

Does not apply to files under `.claude/agents/`.

---

## Extension Point — Standard Hook

Every agent body must end with:

```
## Extension Point

After completing, check for `agents.local/extensions/<name>.md` — if it exists, read and follow its additional instructions.
```

For repo agents (`.claude/agents/`), the path is `.claude/agents.local/extensions/<name>.md`.
