# Flutter Qontak — Reference Index

Theory lives in `lib/core/reference/builder/`. This platform covers Flutter/Dart implementation patterns for modular (melos workspace) architecture.

| File | Sections | Use when |
|---|---|---|
| `reference/project.md` | Workspace layout, module types, dependency graph, package naming, DTO naming | Understanding overall structure or planning a new module |
| `reference/builder/domain-impl.md` | Entities, Repository Interfaces, Use Cases, Domain Services, Failure, Enums | Creating domain layer artifacts in any feature package |
| `reference/builder/data-impl.md` | Response/Request/Db models, Mappers, Data Sources, Repository Impl, AppException | Creating data layer artifacts |
| `reference/builder/presentation-impl.md` | ViewDataState, Events, States, BLoC, Screen Structure, BlocListener, Cubit | Creating BLoC/Cubit, screens, or widgets |
| `reference/builder/error-handling-impl.md` | Error flow, AppException, ErrorInterceptor, Validation errors, Error UI | Mapping exceptions to Failures, error display patterns |
| `reference/builder/app-layer-impl.md` | main.dart, Runner, DI aggregation, ModuleRegistrar, Route registration | Wiring a new module into the app, app-level setup |
| `reference/builder/navigation-impl.md` | Route constants, BaseModule routes, Cross-module Navigation API, Auth guard, Deep links | Navigation setup per module or cross-module navigation |
| `reference/builder/modular-structure-impl.md` | BaseModule contract, Feature/Shared module setup, ModuleRegistrar, Dependencies module | Creating a new feature package or shared module |
| `reference/builder/module-communication-impl.md` | Module API pattern, Navigation API pattern | Sharing data/behavior between feature modules |
| `reference/builder/di-impl.md` | Per-module @InjectableInit, aggregation, Module API registration, scoping rules | Wiring DI in a new module |
| `reference/builder/testing-impl.md` | Per-package test structure, melos test, BLoC/UseCase/Mapper/Module API tests | Writing tests in any feature package |
| `reference/builder/syntax-conventions-impl.md` | Null safety extensions, Unlocalized text, Code style, Import order, Naming | Cross-cutting coding standards |
| `reference/builder/utilities-impl.md` | Logger, HTTP client, StorageService, DateService, AuthInterceptor | Shared infrastructure in `[prefix]_core` |
| `reference/builder/localization-impl.md` | Per-feature .arb files, l10n.yaml, LocalizationsDelegate via BaseModule | Adding translations to a feature package |
| `reference/builder/flavor-impl.md` | Flavor config, bundle IDs per flavor, Envied, Firebase per flavor | Flavor setup or adding a new environment |
| `reference/builder/tech-stack-impl.md` | Recommended dependencies with rationale, pubspec.yaml patterns, linter | Choosing a library, setting up a new package |

**Grep pattern:** `Grep "^## <Section>" reference/builder/<topic>-impl.md` — returns heading + `<!-- N -->` line count for bounded Read.
