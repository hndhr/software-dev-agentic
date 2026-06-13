> Author: Puras Handharmahua · 2026-06-13
> Related: [kms-design-principles.md](kms-design-principles.md) · [kms-conventions.md](kms-conventions.md) · [../glossary.md](../glossary.md)

## What This Doc Covers

A quick-reference list of KMS vocabulary terms with one-line definitions — for when you just need a reminder of what a term means, not the full path/metadata mapping. For the complete Rosetta Stone (storage paths, DB metadata fields, vocabulary sources, worked examples), see [kms-conventions.md](kms-conventions.md).

---

## Glossary

| Term | Definition |
|---|---|
| **KMS** | Knowledge Management System — the ChromaDB-backed knowledge store, queried via the `cp8` MCP server (`kms_list`/`kms_fetch`/`kms_query`/`kms_upsert`). |
| **Scope** | The cascade tier of a knowledge node — how general vs. specific it is: `universal`, `platform`, or `project`. |
| **Platform** | Which client platform a knowledge node applies to — `flutter`, `ios`, `android`, or `web`. |
| **Project** | Which specific downstream codebase a knowledge node is a deviation/inventory for — the folder name under `projects/`. |
| **Discipline** | The role / work-area a knowledge artifact serves — `engineering`, `design`, `qa`, `devops`, `security`, `code_review`, `product`, `architecture`, `agile`. |
| **Artifact** | The named body of knowledge within a discipline — an open-ended kebab-case folder name, e.g. `conventions`, `standard-architecture`, `feature-inventory`. |
| **Topic** | A `#` heading inside an artifact file — a thematic grouping of related concepts. |
| **Pattern** (aka **Subtopic**) | A `##` heading inside an artifact file — one self-contained, retrievable concept, and the canonical name used for that concept across all platforms. |
| **Knowledge Path** | The ordered tuple of Rosetta Stone terms (`scope` → `platform`/`project` → `discipline` → `artifact` → optionally `topic` → optionally `pattern`) that addresses a knowledge node — same shape as a `kms_list`/`kms_fetch` filter set. E.g. `# Domain` in `platform/ios/engineering/standard-architecture/standard-architecture.md` → `scope=platform, platform=ios, discipline=engineering, artifact=standard-architecture, topic=domain`. |
| **Knowledge Path Structure** | The overall directory + heading convention that every Knowledge Path is an instance of: `{scope}/[{platform}\|{project}]/{discipline}/{artifact}/{file}.md`, then `#`→`topic`/`##`→`pattern` inside the file. Defined in [kms-conventions.md](kms-conventions.md#kmsknowledge-sources--path-conventions). |
| **Rosetta Stone** | The term-to-storage-path-to-metadata-field mapping table in [kms-conventions.md](kms-conventions.md) — the canonical reference when a term's meaning is unclear. |
| **Cascade resolution** | The fallback order KMS uses when fetching a node: `project → platform → universal` — most specific match wins. |
| **Scoping funnel** | The narrowing order for `kms_list` calls: `platform`/`project` → `discipline` → `artifact` → `topic` → `pattern` (output, never a filter). |
| **Retrieval Protocol** | The decision table for which KMS MCP tool (`kms_list`/`kms_fetch`/`kms_query`) to use for a given retrieval need. Defined in [kms-conventions.md](kms-conventions.md#retrieval-protocol). |
| **kms_list** | MCP tool — returns a TOC (metadata only) for a given filter combination; narrows one term at a time. |
| **kms_fetch** | MCP tool — exact, cascade-resolved retrieval once `discipline`/`artifact`/`topic`/`pattern` are known. |
| **kms_query** | MCP tool — semantic search bypass when the exact `pattern` isn't known yet; ranks by similarity. |
| **kms_upsert** | MCP tool — manually seed a knowledge node by supplying `discipline`/`artifact`/`topic`/`pattern` directly. |

---

## Changelog

See git history for this file.
