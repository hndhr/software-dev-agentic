> Author: Puras Handharmahua · 2026-06-13
> Related: [kms-conventions.md](kms-conventions.md) · [kms-design-principles.md](kms-design-principles.md) · [kms-glossary.md](kms-glossary.md) · [../repo-structure.md](../repo-structure.md)

What is where inside `kms/` — the map. For path → metadata rules, chunk strategy, and retrieval protocol, see [kms-conventions.md](kms-conventions.md). For the Clean Architecture rationale behind `domain/`/`data/`/`application/`, see [kms-design-principles.md](kms-design-principles.md).

---

## `kms/` — Top Level

```
kms/
├── knowledge-sources/  → raw knowledge docs — the Knowledge Path Structure lives here (see below)
├── domain/             → KMS domain layer — schema, entities, repository interface, use cases
│   ├── schema.py       → single vocabulary contract (scope/platform/project/discipline values)
│   ├── entities.py     → KnowledgeNode and related entities
│   ├── repository.py   → abstract KnowledgeRepository interface
│   ├── sources/        → source adapters — markdown, directory, codebase, confluence
│   └── use_cases/      → fetch_knowledge, list_knowledge, query_knowledge, upsert_knowledge
├── data/               → ChromaKnowledgeRepository — ChromaDB implementation of the domain interface
├── application/        → MCP server (mcp_server.py) — exposes kms_list/kms_fetch/kms_query/kms_upsert
├── db/                 → local ChromaDB store (not committed)
├── scripts/            → seed_kms.py — seed runner driven by sources.yaml
├── dashboard/          → local browser UI for inspecting seeded knowledge (server.py + index.html)
├── docs/               → kms-knowledge-source-rules.md — authoring rules for knowledge-sources/
├── sources.yaml        → registered knowledge sources (seed targets)
└── README.md
```

**Dependency rule:** `application/` → `domain/` ← `data/`. Nothing in `domain/` imports ChromaDB directly — see [kms-design-principles.md — Architecture](kms-design-principles.md#architecture).

---

## `kms/knowledge-sources/` — Knowledge Path Structure

Three top-level buckets mirror the cascade tiers (`scope`); each then nests `{discipline}/{area}/{artifact}.md` (or `{platform}/{discipline}/{area}/{artifact}.md` under `platform/`):

```
kms/knowledge-sources/
├── universal/              → scope=universal — general principles, all platforms
│   ├── agile/
│   ├── architecture/
│   ├── design/
│   ├── devops/
│   ├── engineering/
│   ├── product/
│   ├── qa/
│   └── security/
│       └── {area}/{artifact}.md
├── platform/               → scope=platform — implemented for a specific platform
│   ├── android/
│   ├── flutter/
│   └── ios/
│       └── {discipline}/{area}/{artifact}.md
└── projects/               → scope=project — deviations for a specific project
    ├── flex-mobile/
    ├── mobile-talenta/
    ├── talenta-ios/
    └── talenta-mobile-android/
        └── {area}/{artifact}.md   (+ repo.yaml)
```

`{area}` is a fixed-vocabulary path segment between `discipline` (or the project dir, for `projects/`) and `artifact`:
- `core` — default for platform-/project-owned internal docs (conventions, standard-architecture, feature-inventory, api-endpoints, deviations, shared-components, third-party-integrations, etc.)
- `design-system` — design-system catalog artifacts; here `artifact` is the specific design system name (e.g. `mekari-pixel`), allowing multiple design systems per platform (e.g. a future `legacy-kit`) to coexist without collision

Each `{artifact}.md` is then chunked by heading: `#` → `topic`, `##` → `subtopic`, `###` → `pattern` (depth-aware — `##` is also `pattern` when it has no `###` children). See [kms-conventions.md — Path Conventions](kms-conventions.md#kmsknowledge-sources--path-conventions) and [Chunk Strategy](kms-conventions.md#chunk-strategy--heading-hierarchy) for the full rules, and [kms-glossary.md](kms-glossary.md) for term definitions (`scope`, `discipline`, `area`, `artifact`, `topic`, `subtopic`, `pattern`, Knowledge Path, Knowledge Path Structure).

---

## Changelog

See git history for this file.
