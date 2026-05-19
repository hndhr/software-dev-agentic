---
name: builder-pres-resolve-design
description: Resolve UI element descriptions against the project's design system RAG collection. Returns a Design System Bindings table mapping UI elements to design system symbols. Called by builder-feature-worker before pres-create-screen and pres-create-component. Soft-fails with an empty table if no design system collection is configured.
user-invocable: false
---

## Input

| Parameter | Description |
|---|---|
| `artifact_name` | Name of the Screen or Component artifact from plan.md |
| `ui_description` | Free-text description of UI elements in this artifact (from plan.md artifact notes or description) |

## Steps

### 1 — Locate design system collection

```bash
cat "$(git rev-parse --show-toplevel)/.claude/dart-knowledge.yaml" 2>/dev/null
```

Find the entry with `kind: design_system` and extract its `name` field as `<collection>`.

**Soft fail** (return empty output block) if:
- File does not exist
- No entry has `kind: design_system`

### 2 — Parse UI elements

Split `ui_description` into individual keyword phrases (e.g. `"primary button, avatar with label, list tile"` → `["primary button", "avatar with label", "list tile"]`).

### 3 — Query each element

For each keyword:

```bash
cd "$(git rev-parse --show-toplevel)/.claude/skills/dart-repo-knowledge"
./venv/bin/python3 query.py <collection> --query "<keyword> --n=1 --kind=class" 2>/dev/null
```

Collect the top result's class name and package import path. **Soft fail** the whole step (return empty table) if the venv or collection is not found.

### 4 — Output

Return exactly this block:

```
## Design System Bindings

| UI element | Symbol | Import |
|---|---|---|
| <keyword> | <ClassName> | package:<pkg>/... |
```

Omit rows where no match was found. If the table has no rows, add a single note row:

```
| — | no matches found | verify collection in .claude/dart-knowledge.yaml |
```
