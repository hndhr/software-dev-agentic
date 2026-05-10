# Clean Architecture Layer Contracts

Platform-agnostic contracts for the four Clean Architecture layers used across web, iOS, and Flutter. Workers and planners read this as the single source of truth for what each layer owns, what it produces, and what rules it must never violate.

---

## Dependency Direction <!-- 10 -->

```
Domain  ←  Data  ←  Presentation  ←  UI
```

Each layer may only import from the layer to its left. No exceptions.

---

## Domain Layer <!-- 17 -->

Full artifact definitions, invariants, and creation order: `reference/builder/domain.md`

**Summary:**

| Artifact | Purpose |
|---|---|
| Entity | Pure data structure representing a business concept |
| Repository Interface | Contract for data operations — defines *what*, not *how* |
| Use Case | Single business operation — one class, one public method |
| Domain Service | Pure synchronous computation that spans multiple entities |

Creation order: `Entity → Repository Interface → Use Case(s) → Domain Service (if needed)`

---

## Data Layer <!-- 18 -->

Full artifact definitions, invariants, and creation order: `reference/builder/data.md`

**Summary:**

| Artifact | Purpose |
|---|---|
| DTO | Mirrors raw API/DB shape exactly — no domain logic |
| Mapper interface + impl | Converts between DTO and domain entity |
| DataSource interface | Contract for raw data access (remote or local) |
| DataSource implementation | Concrete HTTP/DB calls — injected, never instantiated directly |
| Repository implementation | Implements domain repository interface using datasource + mapper |

Creation order (remote): `DTO → Mapper → DataSource interface → DataSource impl → Repository impl`

---

## Presentation Layer (StateHolder) <!-- 17 -->

Full artifact definitions, invariants, and creation order: `reference/builder/presentation.md`

**Summary:**

| Artifact | Purpose |
|---|---|
| StateHolder | Single source of truth for UI state (platform name: ViewModel / BLoC / Presenter) |
| State | Immutable snapshot of what the UI should render (loading / data / error) |
| Event / Input | User intentions flowing in (button tapped, form submitted) |
| Action / Output | Side effects flowing out (navigate, show toast) |

Creation order: `Use Cases → StateHolder → StateHolder contract → Screen (builder-ui-worker)`

---

## UI Layer <!-- 17 -->

Full artifact definitions, invariants, and creation order: `reference/builder/ui.md`

**Summary:**

| Artifact | Purpose |
|---|---|
| Screen | Full view bound to a StateHolder — observes state, sends events |
| Component / Sub-view | Reusable UI element — stateless or bound to a scoped StateHolder |
| Navigator / Coordinator | Owns navigation logic — UI delegates destination decisions here |
| DI wiring | Registers StateHolder and dependencies in the container |

Creation order: `Screen → Navigator/Coordinator (if needed) → DI wiring (if needed)`

---

## Inter-Layer Dependency Summary <!-- 8 -->

| Consumer | May import from |
|---|---|
| Domain | nothing |
| Data | Domain only |
| Presentation | Domain only (use cases, entities) |
| UI | Presentation only (StateHolder contract) |
