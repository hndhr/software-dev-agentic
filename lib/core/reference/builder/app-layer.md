# App Layer

Canonical, platform-agnostic definitions for App Layer wiring.
Platform syntax and patterns: `reference/contract/builder/app-layer.md` in each platform directory.

---

## Dependency Registration <!-- 22 -->

**Dependency Registration** is the act of binding concrete implementations to their interfaces in the app's DI container so that the runtime can inject them into use cases, repositories, and state holders.

**Invariants:**
- Bindings live at the app shell — never inside a CLEAN layer
- Each feature owns its own registration unit (component, module, or file) — one file per feature
- Use cases and repositories are registered, not constructed inline at call sites
- Registration order follows the dependency graph: data sources → repositories → use cases

**When to add:** Any time a new use case, repository implementation, or data source is introduced. Skipping registration causes runtime crashes — this step is mandatory, not optional.

---

## Route Registration <!-- 20 -->

**Route Registration** is the act of declaring how the app navigates to a feature's screen — mapping a route identifier (string key, enum case, or coordinator type) to a screen factory.

**Invariants:**
- Routes live at the app shell or navigation coordinator — never inside a CLEAN layer
- Each feature owns one route declaration unit (route file, coordinator class, or destination enum)
- Route identifiers are stable string keys or typed values — not view instances
- Deep link destinations must be registered in the same place as regular routes

**When to add:** Any time a new screen is introduced. An unregistered route is a silent navigation failure.

---

## Module Registration <!-- 17 -->

**Module Registration** is the act of plugging a feature module into the app's module manager so it participates in the app lifecycle (startup, teardown, deep link handling).

**When it applies:** Only on platforms that have an explicit module system (`BaseModule`, `AppModule`, etc.). Platforms that use implicit linking (e.g. file-based routing) skip this step.

**Invariants:**
- Module registration happens in one place — the app's module manager or root coordinator
- Each feature module is registered once — duplicates cause double initialization
- Module lifecycle hooks (`onStart`, `onStop`) must not duplicate logic already in use cases

**When to add:** Any time a new feature module is introduced. Required only on platforms with an explicit `ModuleManager` or equivalent.
