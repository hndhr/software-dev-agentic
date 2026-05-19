# UI Layer — Web

Platform-specific UI layer patterns. Canonical definitions: `reference/code-architecture/ui-theory.md`.

---

## Dependency Rule <!-- 9 -->

UI depends on Presentation only — never imports from Domain or Data directly.

Allowed imports: ViewModel hook return types, State/Action types, `react`, `next/navigation`, and UI library primitives (e.g. shadcn/ui, Tailwind classes).
Forbidden: use case interfaces, repository interfaces, DTOs, mappers, datasources, or direct fetch calls.

---

## Screen <!-- 15 -->

A **Screen** is a Next.js Page component (`app/**/page.tsx`) that composes a single View component bound to a ViewModel hook. It renders layout structure and delegates data/interaction to the View — it contains no business logic.

**Invariants:**
- Page component is thin — delegates all state and event handling to the View + ViewModel hook
- View component bound to exactly one ViewModel hook — hook resolved via DI context, never constructed inline
- Observes every state field returned by the ViewModel hook — no state field goes unhandled
- Calls ViewModel hook action functions for every user interaction — never mutates state directly
- Contains no business logic — ternary/conditionals only decide what to render

**When to create:** One Page file per route. Created after the ViewModel hook contract exists.

---

## Component / Sub-view <!-- 14 -->

A **Component** is a reusable React component (atomic design: atom, molecule, organism) smaller than a full screen view.

**Invariants:**
- Stateless by default — receives data via props and emits callbacks via `onX` props
- If stateful, binds to a scoped ViewModel hook or Zustand store slice — never manages business state inline
- No use case calls — all data passed in from the parent View or a scoped hook
- Reuse check required before creating — search `presentation/common/` and `components/` directories first

**When to create:** When a UI element appears in ≥2 screens, or when a View section is complex enough to isolate. Follow atomic design granularity.

---

## Navigator / Coordinator <!-- 14 -->

A **Navigator** is the `useAppRouter` hook wrapping `next/navigation`, plus the `ROUTES` constants object.

**Invariants:**
- The View delegates navigation intent to the ViewModel hook — it never calls `router.push()` directly in event handlers without going through the hook
- The ViewModel hook calls `useAppRouter()` methods (e.g. `goToEmployeeDetail`) — never constructs path strings inline
- Route constants defined in `ROUTES` object — View never constructs path strings
- One `useAppRouter` hook per app — page-specific navigation helpers live in the ViewModel hook

**When to create:** When a View navigates to another page. `ROUTES` entry and `useAppRouter` method added before the View that triggers navigation. See `navigation-impl.md` for full router pattern.

---

## DI Wiring <!-- 13 -->

**DI wiring** registers use cases and repositories in the `DIContext` provider, resolved by ViewModel hooks.

**Invariants:**
- Use cases registered in the DI container at the page/layout level via `DIProvider`
- ViewModel hook resolves dependencies via `useDI()` or equivalent context hook — never `new UseCase()` inline
- DI scope matches page or layout boundary — not global unless explicitly shared

**When to create:** After the Page and ViewModel hook exist. Required before the route is navigable.

---

## Creation Order <!-- 10 -->

```
Page component → View component + ViewModel hook → ROUTES entry + useAppRouter method (if navigation needed) → DI registration
```

The ViewModel hook contract must exist before any UI layer file is written.

---

## Layer Invariants <!-- 10 -->

- View never mutates state directly — reads from ViewModel hook return values only
- View never calls use cases directly — all interactions invoke ViewModel hook action functions
- Use cases resolved via DI context — never `new MyUseCase()` inside a component or hook
- Navigation delegated to `useAppRouter` via ViewModel hook — View emits intent, not path strings
- No data layer knowledge — no DTOs, no fetch calls, no HTTP types visible in component files

---

## Planner Search Patterns <!-- 10 -->

When exploring the UI layer, glob for:
- `**/app/**/(page|layout).tsx` — Next.js page and layout files
- `**/presentation/features/**/*View.tsx` — feature view components
- `**/presentation/common/**/*.tsx` — shared component files
- `**/presentation/navigation/routes.ts` — route constants

---

## Design System Bindings <!-- 3 -->

No design system is configured for this platform. UI artifacts use framework primitives directly. To adopt one, declare it in `.claude/dart-knowledge.yaml` with `kind: design_system`.
