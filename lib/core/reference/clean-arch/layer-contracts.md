# Clean Architecture Layer Contracts

Platform-agnostic contracts for the four Clean Architecture layers used across web, iOS, and Flutter. Workers and planners read this as the single source of truth for what each layer owns, what it produces, and what rules it must never violate.

---

## Dependency Direction

```
Domain  ←  Data  ←  Presentation  ←  UI
```

Each layer may only import from the layer to its left. No exceptions.

---

## Domain Layer

### Artifacts

| Artifact | Purpose |
|---|---|
| Entity | Pure data structure representing a business concept |
| Repository Interface | Contract for data operations — defines *what*, not *how* |
| Use Case | Single business operation — one class, one public method |
| Domain Service | Pure synchronous computation that spans multiple entities |

### Creation Order

```
Entity → Repository Interface → Use Case(s) → Domain Service (if needed)
```

### Invariants

- Zero imports from data, presentation, or any framework
- Entities carry no business logic and no framework decorators
- Repository interfaces return domain entities — never DTOs or raw API types
- Use cases are single-responsibility — one business operation per class
- Domain services are pure and synchronous — no async, no I/O, no side effects

---

## Data Layer

### Artifacts

| Artifact | Purpose |
|---|---|
| DTO | Mirrors raw API/DB shape exactly — no domain logic |
| Mapper interface + impl | Converts between DTO and domain entity |
| DataSource interface | Contract for raw data access (remote or local) |
| DataSource implementation | Concrete HTTP/DB calls — injected, never instantiated directly |
| Repository implementation | Implements domain repository interface using datasource + mapper |

### Creation Order

**Remote API:**
```
DTO → Mapper → DataSource interface → DataSource impl → Repository impl
```

**Local DB:**
```
DB Record → DB DataSource interface → DB DataSource impl → DB Mapper → Repository impl
```

### Invariants

- Imports from domain layer only — never from presentation
- DTOs mirror the raw API/DB shape exactly — no computed fields, no domain logic
- Mappers are always interface + implementation — never plain utility functions
- Repository implementations wrap all calls with error handling — never let raw errors propagate
- DataSources are abstract interfaces — implementations are injected, never created directly

---

## Presentation Layer (StateHolder)

### Artifacts

| Artifact | Purpose |
|---|---|
| StateHolder | Single source of truth for UI state (platform name: ViewModel / BLoC / Presenter) |
| State | Immutable snapshot of what the UI should render (loading / data / error) |
| Event / Input | User intentions flowing in (button tapped, form submitted) |
| Action / Output | Side effects flowing out (navigate, show toast) |

The StateHolder contract (written to `.claude/agentic-state/runs/<feature>/stateholder-contract.md`) includes:
- StateHolder class/hook name and file path
- State fields
- Event and Action cases
- Navigator/coordinator protocol name and methods
- DI factory method or binding key

### Invariants

- StateHolder depends on domain use cases only — never on data layer implementations
- Use cases are injected via DI — never instantiated directly
- State is read-only from the UI's perspective — UI observes, never mutates
- StateHolder has no knowledge of the UI framework rendering it — no view imports

---

## UI Layer

### Artifacts

| Artifact | Purpose |
|---|---|
| Screen | Full view bound to a StateHolder — observes state, sends events |
| Component / Sub-view | Reusable UI element — stateless or bound to a scoped StateHolder |
| Navigator / Coordinator | Owns navigation logic — UI delegates destination decisions here |
| DI wiring | Registers StateHolder and dependencies in the container |

### Creation Order

```
Screen → Navigator/Coordinator (if needed) → DI wiring (if needed)
```

### Invariants

- UI observes state read-only — never mutates state directly
- UI sends events to the StateHolder — never calls use cases directly
- UI instantiates StateHolder via DI — never with direct init / `new`
- Navigation is delegated to a coordinator/router — UI never knows the destination implementation
- UI has no knowledge of the data layer

---

## Inter-Layer Dependency Summary

| Consumer | May import from |
|---|---|
| Domain | nothing |
| Data | Domain only |
| Presentation | Domain only (use cases, entities) |
| UI | Presentation only (StateHolder contract) |
