---
name: pres-create-viewmodel
description: Create a ViewModel hook for a feature. Called by presentation-worker.
user-invocable: false
tools: Read, Write, Glob
---

Create `src/presentation/features/[feature]/use[Feature]ViewModel.ts`.

**Preconditions:**
- File must NOT exist — fail fast if it does
- Use case(s) must exist in `src/domain/use-cases/[feature]/`
- Check `Glob: src/presentation/features/*/use*ViewModel.ts` — read one to match project style

**Rules:**
- `'use client'` at the top
- Receives use case(s) via typed `deps` parameter — never calls `useDI()` internally
- Returns only `readonly` state — never exposes raw `useState` setters
- No business logic — only state management

**Pattern selection:**
- External API + caching needed → TanStack Query (`useQuery` / `useMutation`)
- Full-stack DB + Server Actions → `useState` + `useCallback` + `useEffect`

**Pattern:** `reference/presentation.md` § 5.2

**Return:** created file path. Suggest next step: `pres-create-view`.
