> Author: Puras Handharmahua · 2026-04-08
> Related: [agentic-design-principles.md](agentic-design-principles.md) · [agentic-taxonomy.md](agentic-taxonomy.md)

Naming conventions, authoring rules, and decision rules for contributing agents, skills, and reference docs.

---

## Agent Naming Convention

Format: `<persona>-[descriptive]-<role>.md`

Every agent that belongs to a persona must be prefixed with the persona name. The role always comes last — it is a label for clarity, not a constraint. An optional freeform descriptive segment goes in the middle when the role alone is ambiguous within the persona.

| Segment | Rule | Example |
|---|---|---|
| `<persona>` | Required — persona name prefix | `developer`, `debugger` |
| `[descriptive]` | Optional — freeform, added when the role alone doesn't distinguish agents | `feature`, `rfc`, `domain` |
| `<role>` | Required — always last; describes the agent's function | `strategist`, `worker`, `writer` |

A persona can introduce any role label that clearly describes the agent's function.

| Pattern | Example | When to use |
|---|---|---|
| `<persona>-<descriptive>-<role>` | `developer-feature-strategist`, `developer-rfc-writer` | Agent inside a persona folder with multiple agents sharing the same role |
| `<persona>-<role>` | `debugger-worker`, `auditor-worker` | Agent inside a persona folder where the role alone is unambiguous |
| `<descriptive>-<role>` | `perf-worker`, `prompt-debug-worker` | Flat agent with no persona yet — persona prefix added when assigned |

> The filename tells you the persona and the agent's function at a glance — no need to open the file.

---

## Skill Naming Convention

**Procedure skills:** `<layer>-<action>-<target>`. Platform-contract skills use `create-*` for new artifact creation only — there are no `update-*` skills.

**Orchestrator skill naming — persona prefix rule:**

Every Type O skill that is the entry point for a persona must be prefixed with the persona name: `<persona>-<action>`. This makes the relationship between skill and persona explicit at a glance and prevents naming collisions as the persona roster grows.

| Pattern | Example | When to use |
|---|---|---|
| `<persona>-<action>` | `developer-build-feature`, `debugger-debug`, `auditor-arch-review` | Type O orchestrator skill that enters a persona workflow |
| `<persona>-<layer>-<action>-<target>` | `developer-domain-create-entity`, `developer-data-create-mapper` | Type P procedure skill called by a worker |

> Exception: standalone utility skills with no persona owner (e.g. `release`, `agentic-perf-review`) are named descriptively without a prefix until a persona is assigned.

---

## Building an Orchestrator Skill

**Runtime environment:**

The Orchestrator skill runs in the main session context window — the same window the engineer is in. This is what gives it authority over routing, looping, and approval gates. It is also its primary constraint:

- Every spawned agent returns its result to the main context. Each round adds history.
- When context fills, Claude compacts it. Compaction is lossy — subsequent rounds reason on a summary of earlier decisions, not the full history.
- Pro context is 200K tokens. Design for minimal rounds: write findings to disk, pass paths not content.

Two capabilities the Orchestrator skill has that agents do not:

| Capability | What it means |
|---|---|
| **Parallel spawning** | Spawn N agents in one step — all run in isolated contexts simultaneously, same wall-clock time as one |
| **Convergence loop** | Own the loop state — spawn → collect Decision block → spawn again — until the strategist signals converged |

**Design checklist:**

Before writing a single instruction, answer four questions in this order:

1. **What's the goal?** → defines **Output**. Declare the structured result the skill expects back from agents — Decision blocks, findings format, verified paths. Routing logic depends on it; declare it first.
2. **What does it need?** → defines **Input**. Every required parameter, declared explicitly. Missing input = `MISSING INPUT: <param>` immediately — no guessing, no defaults.
3. **How does it run? Who's involved?** → defines **Agents + Loop**. Do you need a convergence loop? Which agents reason about what? Define modes, knowledge scope per agent, and how they communicate: Decision blocks in, findings files on disk out. Never pass content inline between rounds.
4. **Will 200K hold?** → **context budget check**. Estimate rounds × agent output size. If the workflow needs many rounds or large results, split into a second Orchestrator. One skill's structured output becomes the next one's input.

The order matters: Output → Input → Process → Budget. Designing output first prevents the skill from becoming a black box that returns whatever the agent feels like.

---

## Preloading Skills

Agents load their procedure skills at startup via the `skills` field — full skill content is injected at startup. This gives agents full procedural knowledge without embedding it in their body. Same procedures are reusable across multiple agents. One definition, updated once.

**Token budget guideline:**
- Preload skills the agent needs in >50% of its invocations
- Load on demand (via `Read`) skills needed rarely or only in edge cases
- Monitor total preloaded size — if it exceeds ~500 lines, split the agent or move low-frequency skills to on-demand

---

## Reference Authoring Rules

**Three-tier structure:**

| Tier | Location | What goes here |
|---|---|---|
| 1 | `CLAUDE.md` | Universal rules applying to every task — naming, principles, build command. ~1 page max |
| 2 | Agent body | Decision logic for that agent only — what to do, when to do it |
| 3 | `kms/knowledge-sources/` | Shared pattern knowledge — theory, definitions, code patterns. Loaded via `kms_list` → `kms_query`. |

> Folder structure for reference docs: see [agentic-repo-structure.md](agentic-repo-structure.md).

**Reference vocabulary — Topic and Term:**

- **Topic** — the subject area a knowledge directory covers. Not engineering-specific: `domain` covers domain layer patterns; `components` covers design components; `unit_testing` covers QA patterns.
- **Pattern** — one concrete concept within a topic. Each pattern is a self-contained `.md` file with `## Theory`, `## Definition`, `## Code Pattern` sections. The filename is the pattern key.

| Level | Example | Location |
|---|---|---|
| Platform-base | `engineering/flutter-standard-architecture.md` | `kms/knowledge-sources/engineering/` — shared across all projects on that platform |
| Project-specific | `projects/flutter-mobile-talenta/deviations.md` | `kms/knowledge-sources/projects/{name}/` — deviations only |
| Pattern node | `use_case` under `topic=domain` | Stored in ChromaDB with `discipline`, `topic`, `pattern` metadata |
| Catalog file | queryable symbol/component inventory | `lib/core/reference/<topic>/<name>-catalog.md` |

**Agent knowledge loading — canonical flow (always both):**
1. `kms_list(platform, discipline)` → scoped TOC, metadata only — agent reasons over what topics exist
2. `kms_query(text, platform, discipline, n_results)` → theory, definitions, and documented patterns with full content
3. Codebase explore — `Grep` for existing implementations of the relevant pattern (e.g., `class.*UseCase`, `class.*RepositoryImpl`) excluding `test/` paths → read the most complete match as live code reference

KMS provides theory and documented convention. Codebase provides the live ground truth. Both are loaded before any artifact decision.

**Placement decision rule — reference vs agent body:**

| Put it in reference if… | Keep it in the agent body if… |
|---|---|
| It is a fact true regardless of who reads it | It is an instruction specific to this agent's workflow |
| It is an invariant, contract, or architectural principle | It is a decision: when to run, what to check, what to do on failure |
| Multiple agents need the same knowledge | Only this agent needs it |
| Removing it from the agent would lose shared truth | Removing it from the agent would lose execution behavior |

> One-line test: can you state it as a rule without saying "you"? If yes — reference. If it only makes sense addressed to the agent — agent body.

**Search Protocol (decision gate):**

| What you need | Tool |
|---|---|
| Implementation patterns (theory, code) | `kms_list` → `kms_query` (theory) + `Grep` codebase for most complete existing implementation (code) |
| A specific class, function, or type in source | `Grep` for the name |
| The full file structure (style-matching a new file) | `Read` — justified |
| Whether a file exists | `Glob` |

**`symbol-query` — canonical source lookup:**

| Flavor | Target | Mechanic |
|---|---|---|
| `symbol-query` | A class, function, or type in source | `Grep <SymbolName>` → `Read(offset=line-5, limit=60)` — expand only if the body exceeds the window |

**Canonical pattern names (ubiquitous language):**

KMS `pattern` values are **Terms** — the canonical name for one concept within a topic. The same concept must use the same `pattern` key across all platforms.

```
discipline=engineering, topic=domain, pattern=use_case, platform=flutter
discipline=engineering, topic=domain, pattern=use_case, platform=ios
discipline=engineering, topic=domain, pattern=use_case, platform=web
```

One concept = one pattern key, everywhere. When adding a new node to the KMS, check whether the same concept exists for other platforms first. If it does, use that `pattern` key exactly. If it's net-new, choose a platform-agnostic term and apply it to all platforms that need it.

---

## Decision Rules

| Situation | Where it goes |
|---|---|
| New CLEAN-layer behaviour, same on all platforms | Core worker |
| New orchestration flow, same on all platforms | Core strategist |
| New code generation pattern for one platform | Platform-contract skill (same name, platform implements) → `lib/platforms/<platform>/skills/contract/` |
| Workflow too platform-specific for any core agent | Platform agent + platform skill → `lib/platforms/<platform>/skills/` (flat) |
| Architecture pattern knowledge (any topic) | `kms/knowledge-sources/engineering/{platform}-*.md` — theory + definition + code pattern per `##` section, seeded as KMS nodes. Project-specific deviations in `kms/knowledge-sources/projects/{name}/` |
| Queryable symbol/component inventory | `lib/core/reference/<topic>/<name>-catalog.md` — `### Symbol` entries; agents `symbol-query` by name directly |

**Planner vs Worker — when to use which:**

| Work profile | Recommended path |
|---|---|
| Contained, well-understood (1–3 artifacts, clear scope, single layer) | Worker directly — overhead of planning exceeds the benefit |
| Cross-layer feature build, multiple artifact types, or uncertain existing state | Planner first → worker — exploration cost is front-loaded, execution is zero-rework |
| Modification to an existing artifact (targeted edit) | Worker directly with context.md Key Symbols if available |
| Large-scale change across many modules or unknown conventions | Planner first — sub-planners explore in parallel, findings aggregated before a single line is written |

> The rule of thumb: if a worker would spend significant time exploring before it can execute, a planner is the better investment. If the scope is clear and bounded, skip the planner and go straight to the worker.

> **Build-directly is a deliberate opt-out, not a default.** It skips all layer isolation guarantees — `feature-worker` makes layer assignment decisions inline with no plan, no human gate, and no tool restriction. The resume routing gate limits the risk: build-directly is only reachable for brand-new features with no prior run. Any feature that was previously planned always resumes against its existing `plan.md` — the worker never re-makes layer decisions that were already validated.

---

## Changelog

See git history for this file.
