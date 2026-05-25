# Feature Doc Principles

Canonical reference for Feature Docs in the Knowledge Management System (KMS).
Read by `librarian-audit-worker` before every write. Reference for engineers writing Feature Docs manually.

Source of truth: `docs/initiatives/knowledge-management-initiative.md`.

---

## What is a Feature Doc

A Feature Doc is a structured Markdown file describing a single sub-feature — its API contracts, data model, architecture, data flow, per-platform artifacts, and known constraints. Feature Docs live in the downstream project repo at `.claude/reference/feature-docs/` and are git-versioned.

They are consumed by:
- `librarian-audit-worker` — validates on every write
- `builder-plan-feature` — reads as `knowledge` type (existing architecture context)
- Engineers — canonical reference per feature

---

## Naming Conventions

| Case | Path |
|---|---|
| Standalone sub-feature | `.claude/reference/feature-docs/<feature-name>.md` |
| Sub-feature within a group | `.claude/reference/feature-docs/<group>/<sub-feature>.md` |
| Feature group article | `.claude/reference/feature-docs/<group>/_group.md` |
| Shared screen or component | `.claude/reference/feature-docs/_shared/<name>.md` |
| Archived original after merge | `.claude/reference/feature-docs/_archived/<name>.md` |

Filenames use kebab-case. Match the Jira epic/story title where possible (e.g. `time-off.md`, `clock-in-out.md`).

---

## Scoping Model

Three tiers:

```
Feature Group     → HLD only, no implementation detail
  Sub-feature     → full Feature Doc (default unit)
    _shared/      → shared screens/components referenced by multiple sub-features
```

**Default unit:** one Feature Doc per screen or sub-feature. Create small, merge later.

**Merge signals** — two articles are worth merging when:
- Always referenced together in the same context
- Data models have inheritance (one entity extends another)
- The HLD of one is incomplete without the other
- The architectural handoff (bridge, engine, deeplink) is the key story

**Merge vs separate examples:**

| Feature | Scope | Why |
|---|---|---|
| TimeOff List + Detail | Merged | Native → Flutter bridge is the story; data model shared |
| Overtime Request + Detail | Merged | Same pattern |
| LiveAttendance: ClockIn/Out | Separate | Own state machine, own result screen variants |
| LiveAttendance: Async | Separate | Own offline behavior, independent complexity |
| LiveAttendance (group) | Group article | HLD only, links to all sub-features |

---

## Schema

```
Feature: <name>
Summary: <1-2 sentences, non-technical>

References
  - PRD:    <Confluence link>
  - Figma:  <Figma file/frame link>
  - Jira:   <ticket ID + link>          ← minimum required
  - BE Contract: <Confluence or Postman link>
  - Other:  <analytics spec, A/B test doc, etc.>

API Contracts
  - Endpoint, method, request/response shape
  - Link to BE contract doc (or inline if none exists)
  - Use "none" if feature has no API calls

Data Model
  - Entity name, fields, types (platform-agnostic)
  - At least one entity with fields and types

High Level Design (optional — omit if not available)
  - Layer map: Network | Data | Domain | Presentation columns with vertical dividers
  - Dependency direction noted (arrows show direction of call)
  - For hybrid-in-native: show Native Shell → FlutterEngine → FlutterModule boundary
  - Diagram: <Figma or image link, if exists>

Data Flow
  - Numbered steps, end-to-end
  - Optionally followed by an ASCII diagram
  - Every class name in the diagram must appear in the numbered steps, and vice versa

Artifacts (per platform)
  - Flat table: Layer column + one column per platform
  - List only components that actually exist in the codebase
  - Use [pending-scan] for platforms not yet scanned (not blank, not omitted)
  - Example:
      | Layer     | iOS Native        | Android Native       | Flutter Module     |
      | Screen    | TimeOffListVC     | TimeOffListFragment  | TimeOffDetailPage  |
      | Use case  | —                 | GetTimeOffListUseCase| GetTimeOffDetailUC |

Platform Variants
  - Every entry must carry [pre-Clean] or [Clean] tag
  - Cover all platforms present in the Artifacts table
  - Describe structural pattern (screen count, navigation, architectural pattern, why platforms diverged)
  - Omit section entirely only if all platforms are structurally identical
  - Example:
      - iOS: [pre-Clean] MVC — ViewController → Service → direct API call
      - Android: [Clean] Fragment → ViewModel → UseCase → Repository
      - Flutter: [Clean] BLoC → UseCase → Repository

Gotchas / Known Constraints
  - 1-3 bullets covering platform quirks, workarounds, or performance traps
  - Mandatory — this is where tribal knowledge lives
```

---

## Rules

### Mandatory sections

| Section | Requirement |
|---|---|
| Feature name | Present |
| Summary | 1-2 sentences, non-technical (no class names, file names, or layer terminology) |
| References | At minimum: Jira ticket ID + link |
| API Contracts | At least one entry, or explicit "none" |
| Data Model | At least one entity with fields and types |
| Artifacts | Table present with at least one platform column |
| Platform Variants | Every entry must carry `[pre-Clean]` or `[Clean]` |
| Gotchas | At least 1 bullet |

### Quality rules

- **Summary** must not contain class names, file names, or layer terminology
- **Artifacts** must only list components that actually exist in the codebase — no aspirational Clean layers on pre-Clean platforms
- **Platform Variants** must cover all platforms present in the Artifacts table
- **`[pending-scan]`** must be used for missing platforms — not blank, not omitted
- **Data flow consistency** — every class name in the diagram must appear in the numbered steps, and vice versa
- **HLD** — if present, the component diagram must use lane-based format: `Network | Data | Domain | Presentation` columns with vertical dividers; dependency direction must be explicit

### Structural rules

- One Feature Doc covers one sub-feature (unit of work matching a Jira epic/story)
- Shared screens or components must live in a `_shared/` article, not duplicated across Feature Docs
- Feature group articles (`_group.md`) contain HLD only — no API contracts, data flow, or artifacts

---

## Audit Criteria

`librarian-audit-worker` uses these to classify findings. Violations block publish. Warnings surface to the reviewer but do not block.

### Violations (block publish)

| Check | Condition |
|---|---|
| Missing mandatory section | Any section from the Mandatory sections table is absent |
| Summary quality | Summary contains class names, file names, or layer terminology |
| Artifacts completeness | Artifacts table is absent or has zero platform columns |
| Platform Variants missing marker | Any Platform Variants entry lacks `[pre-Clean]` or `[Clean]` |
| Platform Variants coverage gap | A platform appears in Artifacts but is absent from Platform Variants |
| Gotchas absent | Gotchas section missing or empty |
| References incomplete | No Jira ticket ID present |

### Warnings (surface to reviewer)

| Check | Condition |
|---|---|
| API Contracts placeholder | Entry present but link is `<placeholder>` |
| Data flow / diagram mismatch | Class name appears in diagram but not in numbered steps (or vice versa) |
| HLD format | HLD present but does not use lane-based column format |
| Pending-scan platforms | Any `[pending-scan]` entries remain — flag for follow-up |
| Gotchas thin | Only 1 bullet — reviewer should confirm tribal knowledge is captured |
| Feature group has implementation detail | `_group.md` contains API Contracts, Data Flow, or Artifacts |

---

## Design Decisions

**Artifacts as a flat table** — one row per architectural layer, one column per platform. Platform-agnostic concept in column 1, platform-specific class names across. Enables diff when native and Flutter diverge.

**`[pre-Clean]` / `[Clean]` markers** — mark platforms that haven't adopted Clean Architecture yet. A Confluence (or grep) search for `[pre-Clean]` produces a prioritized migration backlog per feature per platform. When a platform is migrated, update the article and the marker drops.

**`[pending-scan]` pattern** — missing platforms are marked explicitly, not silently omitted. Next session: skill reads the doc, detects `[pending-scan]`, spawns only the needed platform worker. Doc grows incrementally without re-scanning covered platforms.

**Gotchas is mandatory** — without it the KMS becomes reference-only and engineers still ask the original author.

**Document what exists, mark the gap** — do not invent Clean layers that aren't there. List only artifacts that actually exist in the codebase.

**HLD is optional** — include it only when the integration boundary (bridge, engine, deeplink) is the key complexity. The HLD for a hybrid feature must explicitly show the `Native Shell → FlutterEngine → FlutterModule` boundary — this is where integration bugs concentrate.

**Platform Variants vs Artifacts** — Artifacts captures names (class, file). Platform Variants captures structure — screen count, navigation pattern, architectural pattern, why platforms diverged. Omit Platform Variants only when all platforms are structurally identical.
