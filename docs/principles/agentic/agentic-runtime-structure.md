> Author: Puras Handharmahua · 2026-06-14
> Related: [agentic-directory-structure.md](agentic-directory-structure.md) · [agentic-glossary.md](agentic-glossary.md) · [agentic-design-principles.md](agentic-design-principles.md)

What lands on disk in a **downstream project** when a persona runs. Nothing here is part of this repo — these paths are created at runtime inside the consuming project's `.claude/` directory. For the source layout of this repo, see [agentic-directory-structure.md](agentic-directory-structure.md).

---

## Root — `.claude/agentic-state/`

```
.claude/agentic-state/
├── .session-id                         → written by the require-feature-strategist hook; identifies the active session
├── developer/
│   ├── runs/
│   │   └── <feature>/                 → one run directory per feature (see Run Directory below)
│   ├── figma/
│   │   └── <timestamp>/               → one figma fetch directory per fetch session (see Figma Fetch Directory below)
│   ├── sysdesign/
│   │   ├── screens/                   → screen system design docs (see Sysdesign Output below)
│   │   └── flows/                     → flow system design docs (see Sysdesign Output below)
│   └── rfc/                           → RFC and breakdown docs (see RFC Output below)
└── saturn-jaygarcia/
    └── <slug>/                        → one run directory per task slug
```

Typically gitignored in downstream projects. Never shipped or read by this repo's source files.

---

## Run Directory — `.claude/agentic-state/developer/feature-plans/<feature>/`

The run directory is created by the entry skill (Type O) before any agents are spawned. Its path is resolved once and passed as `run_dir` to every agent in the run.

```
<run_dir>/
├── plan.md                 → per-artifact instructions; status field tracks approved/pending
├── context.md              → key symbols, conventions, and Figma alignment for the feature
├── state.json              → phase-completion pointer (see State File below)
├── figma-fetch-dir.txt     → pointer to the figma fetch directory; written by entry skill so strategist can locate frame files on resume
├── stateholder-contract.md → written by developer-pres-create-stateholder; path recorded in state.json
├── findings/
│   └── <layer>-findings.md → one file per planner, written by the planner itself
└── (update_mode archives)
    ├── plan-v1.md          → archived plan before re-synthesis
    └── context-v1.md       → archived context before re-synthesis
```

### State File — `state.json`

Written (and updated) by `developer-feature-worker` after each artifact completes. The calling skill reads it to locate the next pending artifact and to pass the stateholder contract path to `developer-ui-worker`.

```json
{
  "feature": "<feature name>",
  "platform": "<platform>",
  "next_artifact": "<next artifact name or null>",
  "completed_artifacts": ["<name>", "..."],
  "stateholder_contract": "<abs path or null>",
  "domain": { "<ArtifactName>": "<abs path>" },
  "data":   { "<ArtifactName>": "<abs path>" },
  "presentation": { "<ArtifactName>": "<abs path>" },
  "ui":     { "<ArtifactName>": "<abs path>" },
  "app":    { "<ArtifactName>": "<abs path>" }
}
```

---

## Figma Fetch Directory — `.claude/agentic-state/developer/figma/<timestamp>/`

Created by `developer-fetch-figma` or `developer-plan-build-feature` before spawning `developer-figma-worker` instances. Named by timestamp only (`YYYYMMDD-HHMMSS`) — no feature association. Not tied to any single run — reusable by passing the path as an argument to `developer-plan-build-feature`. When picked up by a run, its path is written to `<run_dir>/figma-fetch-dir.txt`.

```
<figma_fetch_dir>/
├── frame_<sanitized-node-id>/          → one directory per fetched Figma node (node-id: 123:456 → frame_123-456)
│   ├── figma-<slug>.md                 → compact semantic reference (components, state, interactions, tokens)
│   ├── figma-<slug>-layout.jsx         → full JSX from Figma MCP, verbatim, never truncated
│   └── figma-<slug>-screenshot.png     → downloaded screenshot (or .png.failed if download failed)
├── ui-stacks/
│   └── figma-uistack-<screen-slug>.md  → merged UI Stack per visual cluster; present after group-frames runs
└── figma-groups.json                   → user-confirmed screen → states grouping; present after grouping step completes
```

---

## Sysdesign Output — `.claude/agentic-state/developer/sysdesign/`

Written by `developer-sysdesign-extract-worker` and `developer-sysdesign-consolidate-worker`, orchestrated by `/developer-extract-sysdesign`.

```
developer/sysdesign/
├── screens/
│   └── <screen-name-kebab>-system-design.md   → one per extracted screen entry point
└── flows/
    └── <flow-name-kebab>-flow-system-design.md → consolidated multi-screen flow design
```

---

## RFC Output — `.claude/agentic-state/developer/rfc/`

Written by `developer-rfc-writer`, orchestrated by `/developer-rfc`.

```
developer/rfc/
├── <epic-slug>-rfc.md          → full RFC document
└── <epic-slug>-breakdown.md    → ticket breakdown derived from the plan
```

---

## Inter-Run Conventions

| Convention | Detail |
|---|---|
| **Disk-First handoff** | Agents communicate via files (`plan.md`, `context.md`, `state.json`) — the calling skill relays paths, not inline content, between rounds. |
| **Findings isolation** | Each planner writes its own `<layer>-findings.md` to `findings/` — the skill never aggregates content, only passes the directory path. |
| **Update-mode archiving** | Before re-synthesis, the skill archives `plan.md` → `plan-vN.md` and `context.md` → `context-vN.md`. Planners treat `completed_artifacts` as locked. |
| **Checkpoint resume** | If a worker exceeds its context window, it emits `## Context Checkpoint` with `next_artifact`. The skill re-spawns a fresh worker, passing the updated plan and state. |

---

## Changelog

See git history for this file.
