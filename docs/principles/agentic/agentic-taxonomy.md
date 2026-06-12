> Author: Puras Handharmahua · 2026-04-08
> Related: [agentic-design-principles.md](agentic-design-principles.md) · [agentic-conventions.md](agentic-conventions.md)

Classification system for all agentic components — what each type is, where it lives, and what scope it has.

---

## Persona

A named group of related agents serving a coherent workflow.

Requirements:
- Lives in `lib/core/agents/<persona>/`
- Has at least one worker or strategist
- Agents within the group relate to and can depend on each other
- Requires a `.pkg` file for selective installation

Shipped to all downstream projects via plugin. Current personas: `developer`, `debugger`, `tracker`, `auditor`.

**Persona → SDLC role mapping:**

Each persona maps to a real-world role and the SDLC phase that role owns. The Orchestrator skills within a persona are the agentic equivalents of that role's actual workflows.

| SDLC Phase | Role | Persona | Status |
|---|---|---|---|
| Implementation | Software Engineer | `developer` | Live |
| Testing | QA Engineer | `qa` | Live |
| Other phases (Requirement, Design, Delivery) | — | — | Research |

A persona's Orchestrator skills directly mirror the role's day-to-day workflows. Adding a new phase means identifying its role, mapping its workflows, and building one Orchestrator skill per workflow — using the same 4 design questions.

> A persona is not just a folder. It represents a coherent workflow. Do not group unrelated agents into a persona subdirectory.

---

## Agents

### By Role

Agent roles are descriptive, not prescriptive. A persona defines whatever agent structure fits its workflow — there is no required set of roles. The following are common patterns seen in existing personas, documented here as reference.

**Strategist — reasoning agent (developer persona pattern):**

A strategist is a pure reasoning agent. It decides what to do and returns structured Decision blocks — it never spawns agents or writes source files directly. Tool set: `Read`, `Glob`, `Grep` only.

- Accepts modes from the calling skill: `gather-intent`, `gather-intent-prefilled`, `process-findings`, `synthesize`, `execute-approved-plan`, `resume`
- Returns `Decision: spawn-planners` (which layers, why), `Decision: converged`, `Decision: spawn-worker`, or `Decision: blocked`
- In `synthesize` mode: writes `plan.md` and `context.md` to the runs directory — the only files a strategist may write
- The calling skill owns all agent spawning, the convergence loop, and user interaction

**Planner — read-only explorer (developer persona pattern):**

A planner explores one CLEAN layer and returns structured findings. It is always read-only with respect to source code.

- Restricted to read-only tools (`Glob`, `Grep`, `Read`)
- Scoped to its own layer's directories and artifact types
- Returns findings including `### Impact Recommendations` — which other layers are affected and why
- Spawned by the entry skill (not the strategist) based on the strategist's Decision block

Sub-planners are all leaf agents: they explore, report, and return. No further spawning.

> Strategists may spawn other strategists when the inner strategist represents a fully bounded sub-workflow. The outer strategist owns the top-level state file and final report.

### By Scope

| Scope | Location | Ships downstream? |
|---|---|---|
| **Persona agent** | `lib/core/agents/<persona>/` | Yes — all platforms |
| **Platform agent** | `lib/platforms/<platform>/agents/` | Yes — matching platform only |
| **Project agent** | `.claude/agents.local/` | No — project-owned, not in this repo |

> Persona agents must be platform-agnostic — no platform paths, framework references, or language syntax in the body (Critical per P6).

---

## Skills

### By Invocation Type

| Type | Config | Who triggers | Use for |
|---|---|---|---|
| **P — Procedure** | `user-invocable: false` | Worker (agent) only | Thin create-only procedures |
| **O — Orchestrator** | `user-invocable: true` | User only | User entry point — owns and runs the workflow. Simple workflows do their own work; complex ones delegate to agents. |

> For automated bash execution without model involvement, use hooks in `settings.json` — not a skill.

**Why no default skill type (invocable by both user and agent):** Every default skill's description loads into the main session context on every turn. Types P and O eliminate this overhead.

### By Scope

| Scope | Location | Ships downstream? |
|---|---|---|
| **Toolkit skill** | `lib/core/skills/` | Yes — all platforms. Platform-agnostic, intended for use in downstream projects. |
| **Platform-contract skill** | `lib/platforms/<platform>/skills/contract/` | Yes — matching platform. Same name across all platforms; each implements for its syntax — called by persona workers. Bundled flat as `<name>/SKILL.md` in the plugin. |
| **Platform-only skill** | `lib/platforms/<platform>/skills/` (flat) | Yes — matching platform only. Called by platform agents. |
| **Project skill** | `.claude/skills.local/` | No — project-owned, not in this repo. |
| **Repo skill** | `.claude/skills/` | No — internal tooling only. Used by this repo's internal agents; never bundled into downstream plugins. |

> "Core-dependency skill" refers to platform-contract skills — skills all platforms must implement under the same name (`developer-domain-create-entity`, `developer-data-create-mapper`, etc.).

### Valid Type × Scope Combinations

Not all combinations are meaningful. Use this as the decision gate when adding a new skill:

| Scope | P — Procedure | O — Orchestrator |
|---|---|---|
| Toolkit | — | ✓ |
| Platform-contract | ✓ | — |
| Platform-only | ✓ | ✓ |
| Project | ✓ | ✓ |
| Repo | ✓ | ✓ |

> Toolkit skills are always user-facing (Type O) — agents don't call them, workers call platform-contract skills instead. Platform-contract skills are always Type P — they're called by workers programmatically, never by users directly.

---

## Reference Docs

### By Scope

| Scope | Location | Ships downstream? |
|---|---|---|
| **Platform-base knowledge** | `kms/knowledge-sources/engineering/{platform}-*.md` | Yes — via pre-seeded ChromaDB bundled in plugin. Theory + definition + code pattern per node. Shared across all projects on that platform. |
| **Project knowledge** | `kms/knowledge-sources/projects/{name}/` | Yes — via pre-seeded ChromaDB. Project-specific deviations only — created only when real divergence exists. |
| **Core catalog** | `lib/core/reference/<topic>/` | Yes — all platforms. Contains `<name>-catalog.md` — queryable symbol/component inventory. Agents `symbol-query` these; never load in full. |
| **Project reference** | `.claude/reference.local/` | No — project-owned, not in this repo. Overrides for project-specific conventions not in KMS. |

---

## Anatomy of a Persona

A persona is composed of layered components that connect user intent to executed code. Each layer has a defined role, authority boundary, and handoff contract.

```
User
 │
 ▼
Orchestrator Skill (Type O) — routes (resume vs new), pre-loads context, builds spawn prompt, owns convergence loop, spawns agents, approval
 │
 ▼  (gather-intent / decision round)
Strategist               — brain only; returns Decision blocks; never spawns agents or writes files
 │
 │  Decision: spawn-planners
 ▼
Trigger Skill              — spawns planners in parallel per round; accumulates findings
 │
 ▼  (sends findings back each round)
Strategist               — reads impact recommendations; decides: more rounds or converged?
 │
 │  Decision: converged → Trigger Skill synthesizes plan → user approval
 │  Decision: spawn-worker
 ▼
Trigger Skill              — spawns Worker with plan + context injected inline
 │
 ▼
Worker                     — reads plan, calls skills, writes source files, validates output
 │
 ▼
Skill(s)                   — concrete platform implementation (one per artifact type)
```

Not every persona uses all layers. A simple persona may have only a trigger skill + worker. A complex one adds a strategist, planners, and multiple workers. The anatomy is the same regardless of how many layers are present.

**Handoff contracts — what each layer passes to the next:**

| From → To | What is passed | What is never passed |
|---|---|---|
| Trigger Skill → Strategist | Intent / mode + accumulated findings (per round) | Raw file reads from the main session |
| Strategist → Trigger Skill | Structured Decision block (`spawn-planners`, `converged`, `spawn-worker`, `blocked`) | Agent spawns or file writes |
| Trigger Skill → Planner | Feature name, platform, module-path + mode instruction | Strategist's internal reasoning |
| Planner → Trigger Skill | Structured findings block including `### Impact Recommendations` | Source file paths or contents |
| Trigger Skill → Worker | `plan.md` + `context.md` injected inline | File paths only (contents always inlined) |
| Worker → Skill | Artifact name, target path, reference doc path | Cross-layer context |
| Worker → Trigger Skill | `## Output` section with Glob+Grep-verified paths | Partial or unverified paths |

**State files — written and read across the lifecycle:**

| File | Written by | Read by | Purpose |
|---|---|---|---|
| `state.json` | Strategist (after each phase) | Trigger skill (resume routing) | Phase completion + `next_phase` pointer |
| `plan.md` | Planner | Worker | Per-artifact execution instructions |
| `context.md` | Planner | Trigger skill (context relay) | Key symbols, conventions, existing artifacts |

> A persona without a trigger skill is incomplete. The trigger skill is the only supported entry path — it owns routing, context relay, and spawn prompt construction.

---

## Changelog

See git history for this file.
