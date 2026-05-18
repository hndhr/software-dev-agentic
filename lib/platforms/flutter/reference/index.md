# Flutter Reference Index

Platform implementation docs. Theory (what/why) lives in `reference/builder/<layer>-theory.md`; these impl files cover Flutter/Dart syntax and patterns only.

| File | Sections | Use when |
|---|---|---|
| `reference/builder/domain-impl.md` | Entities, Use Cases, Repository Interfaces, Domain Errors | Creating domain layer artifacts |
| `reference/builder/data-impl.md` | DTOs, Mappers, Data Sources, Repository Implementations | Creating data layer artifacts |
| `reference/builder/presentation-impl.md` | BLoC, Cubit, Events, States, Screen Structure, BlocListener | Creating BLoC/Cubit, screens, or widgets |
| `reference/builder/di-impl.md` | Annotations, Registration Order, Scope Rules | Wiring DI with `@injectable` / `get_it` |
| `reference/builder/testing-impl.md` | Unit Tests, Presenter Tests, Mock Setup, Test Naming | Writing tests for any layer |
| `reference/builder/error-handling-impl.md` | Failure Types, AppException, Error Flow | Mapping exceptions to domain Failures |

**Grep pattern:** `Grep "^## <Section>" reference/builder/<topic>-impl.md` — returns heading + `<!-- N -->` line count for bounded Read.
