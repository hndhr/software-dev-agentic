---
name: pres-create-view
description: Create a View component and (if new route) the App Router page. Called by presentation-worker.
user-invocable: false
tools: Read, Write, Edit, Glob
---

Create `src/presentation/features/[feature]/[Feature]View.tsx`.
If a new route is needed, also create `src/app/[route]/page.tsx` and add to `routes.ts`.

**Preconditions:**
- `use[Feature]ViewModel.ts` must exist — run `pres-create-viewmodel` first if missing
- Check `Glob: src/presentation/features/*/[A-Z]*View.tsx` — read one to match project style

**View rules:**
- `'use client'`
- Calls `useDI()` to get injected use cases
- Passes use cases to ViewModel hook via deps
- Renders three states: loading, error, data
- No business logic — only render logic

**Page rules (if new route):**
- Server Component (no `'use client'`)
- Imports and renders `[Feature]View` only
- Add route constant to `src/presentation/navigation/routes.ts`

**Atomic Design:**
- Atoms/molecules → `src/presentation/common/atoms|molecules/` — primitive props only
- Organisms → `src/presentation/features/[feature]/organisms/` — accept entities as props, never call `useDI()`
- Only Views call `useDI()`

**Pattern:** `reference/presentation.md` § 5.1, `reference/navigation.md` § 6.2

**Return:** created file paths.
