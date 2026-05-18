# Navigation

Canonical, platform-agnostic definitions for navigation.
Platform syntax and patterns: `reference/code-architecture/navigation-impl.md` in each platform directory.

---

## Route Constants <!-- 14 -->

**Route Constants** are named, centralized identifiers for every navigation destination in the app.

**Invariants:**
- All destination identifiers defined in a single constants file per feature or app — never hard-coded at the call site
- String paths (web/Flutter) or typed class references (Android/iOS) — platform dictates the form, the principle is the same
- Parameterised routes expose a typed helper function/method — callers never construct path strings inline
- Route constants exported from the feature or navigation module — consumers import the constant, not a string literal

**When to create:** Before any screen that navigates to a destination. Constants file created once per feature; entries added as destinations are added.

---

## Navigator / Coordinator <!-- 16 -->

A **Navigator** (web/Flutter/Android) or **Coordinator** (iOS) is the single owner of navigation logic for a feature or flow.

**Invariants:**
- Defined as an interface/protocol — the Screen or Presenter holds only the interface, never the concrete type
- Implemented in a separate class that knows how to resolve the destination (push a controller, call `context.go`, start an Activity)
- The StateHolder (ViewModel/Bloc/Presenter) emits a navigation intent — the Navigator/Coordinator decides the implementation
- Knows route constants or destination types — the Screen does not
- One Navigator/Coordinator per feature flow — not per screen
- Injected into the StateHolder — never instantiated by the Screen or StateHolder directly

**When to create:** When a screen navigates to another screen. Created after the Screen that triggers navigation.

---

## Navigation Action (Side Effect) <!-- 14 -->

A **Navigation Action** is the signal emitted by a StateHolder to request navigation without the StateHolder knowing the destination implementation.

**Invariants:**
- Expressed as a typed value in the StateHolder's output (state field, Observable result, or action callback)
- Consumed by the UI layer (BlocListener, Coordinator subscribe, ViewModel hook) — never handled inside the StateHolder
- Cleared after consumption — the UI layer resets the navigation action field so it is not re-triggered on recomposition/re-render
- Carries only the data needed to resolve the destination (IDs, flags) — not the destination itself

**When to create:** Whenever a StateHolder needs to trigger navigation as a result of business logic (e.g., after a successful form submission or a delete confirmation).

---

## Auth Guard / Redirect <!-- 14 -->

An **Auth Guard** is a global or per-route check that redirects unauthenticated users before a destination is rendered.

**Invariants:**
- Evaluated before the destination screen renders — not inside the screen itself
- Reads auth state from a shared service or StateHolder — never from local component state
- Public routes (login, onboarding, forgot-password) explicitly excluded from the guard
- Redirect destination is a route constant — never a hard-coded path string

**When to create:** At router/coordinator setup time. Defined once per app or module root; individual screens do not implement auth checks.

---

## Deep Links <!-- 14 -->

**Deep Links** are external URLs or URIs that navigate directly to a specific in-app destination.

**Invariants:**
- URI schemes and host patterns declared in platform manifests/info.plist — not in application code
- Deep link paths match route constant definitions exactly — no separate deep-link-only paths
- Screen always has a fallback when extra/prefetched data is unavailable (e.g., fetch by ID from path parameter)
- Auth guard applies to deep-linked routes — unauthenticated deep links redirect to login first

**When to create:** When a feature destination must be reachable from a notification, email link, or external app. Added alongside the route constant for that destination.

---

## Nested Navigation <!-- 11 -->

**Nested Navigation** preserves a persistent shell (tab bar, side nav, bottom nav) while navigating between child destinations.

**Invariants:**
- Persistent shell defined at the router/coordinator level — not duplicated in each child screen
- Child screens within the shell navigate without destroying the shell (push within the shell, not replace the root)
- Tab selection state owned by the shell — child screens do not manage tab state
- Deep links into a nested route restore the shell correctly — not just the leaf screen

**When to create:** When the app has a persistent navigation structure (tabs, sidebar) with independent navigation stacks per tab.
