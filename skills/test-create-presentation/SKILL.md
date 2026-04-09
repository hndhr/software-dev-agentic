---
name: test-create-presentation
description: Write tests for ViewModel hooks and View components. Called by test-worker.
user-invocable: false
tools: Read, Write, Glob
---

Write tests for a presentation layer file.

**Preconditions:**
- Read the target file: extract hook name, deps interface, or component props
- Check `__tests__/utils/queryClientWrapper.tsx` exists — it's required for hook tests
- Output location:
  - ViewModel hook → `__tests__/presentation/hooks/use[Feature]ViewModel.test.ts`
  - View component → `__tests__/presentation/[Feature]View.test.tsx`

**ViewModel hook test rules:**
- Use `renderHook` + `QueryClientWrapper` from `__tests__/utils/queryClientWrapper.tsx`
- Mock use case(s) via `test-create-mock`
- Cover state transitions: initial loading → loaded → error
- For mutations: cover success path + error path

**View component test rules:**
- Use React Testing Library (`render`, `screen`, `userEvent`)
- Mock the ViewModel hook (use `vi.mock`)
- Cover each render state: loading view, error view, data view
- Test user interactions that trigger ViewModel actions

**Pattern:** `reference/testing.md` § 10.3, § 10.4

**Return:** created test file path.
