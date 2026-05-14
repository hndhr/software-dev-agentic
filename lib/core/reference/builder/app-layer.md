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

## Module Registration <!-- 15 -->

**Module Registration** is the act of plugging a feature module into the app's module manager so it participates in the app lifecycle (startup, teardown, deep link handling).

**When it applies:** Only on platforms that have an explicit module system (`BaseModule`, `AppModule`, etc.). Platforms that use implicit linking (e.g. file-based routing) skip this step.

**Invariants:**
- Module registration happens in one place — the app's module manager or root coordinator
- Each feature module is registered once — duplicates cause double initialization
- Module lifecycle hooks (`onStart`, `onStop`) must not duplicate logic already in use cases

**When to add:** Any time a new feature module is introduced. Required only on platforms with an explicit `ModuleManager` or equivalent.

---

## Analytics Constants <!-- 13 -->

**Analytics Constants** are feature-scoped files that declare the event names, screen names, or tracking identifiers reported to the analytics service.

**Invariants:**
- One constants file per feature — never share event names across features in a single file
- Constants are plain string literals — no logic, no SDK imports
- Analytics SDK calls are made in the Presentation layer (ViewModel/BLoC) — these files only declare the identifiers they reference

**When to create:** Any feature that instruments user interactions or screen views. Optional — skip if the feature has no analytics events.

---

## Feature Flag Registration <!-- 78 -->

**Feature Flag Registration** is the act of declaring a new feature-gating key in the app's centralized flag registry, enabling remote enable/disable without a new app release.

**Invariants:**
- Flag keys live in a centralized registry (enum, struct, or constants file) — never as inline string literals at call sites
- One key per feature toggle — never reuse an existing flag for a different purpose
- Default values are explicit — the flag's behavior when unset must be defined in the registry

**When to add:** Any feature that requires remote gating, gradual rollout, or a kill switch. Optional — skip for features that launch immediately to 100% of users.

---

## Push Notification Registration <!-- 92 -->

**Push Notification Registration** is the act of wiring the app to receive push notifications — fetching the device token, delivering it to the server, and removing it on logout.

**Invariants:**
- Registration is owned by the infrastructure layer — never by an individual feature
- The notification manager is wired once at the app shell, not inside feature modules
- Payload routing (which screen or flow a notification opens) is declared separately from payload receipt (receiving and decoding the notification)
- Notification display concerns — channels, builders, and visual configuration — are isolated from the message handler
- Silent push notifications must route through domain use cases — they must not trigger UI state directly

**When to add:** Once per app. The token lifecycle is tied to the auth flow — token registration occurs on login and token deletion occurs on logout.

---

## Deeplink Registration

**Deeplink Registration** is the act of mapping incoming URLs and notification taps to screens or flows within the app.

**Invariants:**
- Mappings live at the app shell — never inside individual feature modules
- Deeplink route identifiers are the same identifiers used for in-app navigation — no parallel routing system
- URL parsing is separated from routing — the parser produces a route identifier, the router acts on it
- Each feature declares its own deeplink paths; the app shell assembles the complete registry
- Deeplinks arriving while the app is backgrounded or unauthenticated must be queued and replayed after auth completes

**When to add:** Any feature reachable from a push notification tap, an external URL, or a cross-app link.
