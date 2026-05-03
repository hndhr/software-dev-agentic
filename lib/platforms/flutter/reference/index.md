# Flutter Reference Index

Platform-specific contract docs. Concepts live in `reference/builder/<layer>.md`; these files cover Flutter/Dart syntax and patterns only.

| File | Sections | Use when |
|---|---|---|
| `reference/contract/builder/domain.md` | Entities, Use Cases, Repository Interfaces, Domain Errors | Creating domain layer artifacts |
| `reference/contract/builder/data.md` | DTOs, Mappers, Data Sources, Repository Implementations | Creating data layer artifacts |
| `reference/contract/builder/presentation.md` | BLoC, Cubit, Events, States, Screen Structure, BlocListener | Creating BLoC/Cubit, screens, or widgets |
| `reference/contract/builder/di.md` | Annotations, Registration Order, Scope Rules | Wiring DI with `@injectable` / `get_it` |
| `reference/contract/builder/testing.md` | Unit Tests, BLoC Tests, Mock Setup, Test Naming | Writing tests for any layer |
| `reference/contract/builder/error-handling.md` | Failure Types, AppException, Error Flow | Mapping exceptions to domain Failures |

**Grep pattern:** `Grep "^## <Section>" reference/contract/builder/<file>.md` — returns heading + `<!-- N -->` line count for bounded Read.
