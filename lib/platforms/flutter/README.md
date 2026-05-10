# Flutter Platform

Flutter · Clean Architecture + BLoC · get_it/injectable

## Structure

```
lib/platforms/flutter/
  skills/
    domain-create-entity/       # @freezed entity, no fromJson
    domain-create-repository/   # abstract class, Either returns
    domain-create-usecase/      # UseCase<T, P>, Params class
    domain-create-service/      # pure sync business logic
    data-create-mapper/         # Model (freezed+json) + BaseMapper impl
    data-create-datasource/     # abstract + Dio impl, throws AppException
    data-create-repository-impl/# catches AppException → Left(failure)
    pres-create-stateholder/    # BLoC: Event + State + BLoC class
    pres-create-screen/         # Screen (BlocProvider) + View (BlocBuilder)
    pres-create-component/      # reusable presentational Widget
    test-create-domain/         # UseCase + Service tests
    test-create-data/           # Mapper + RepositoryImpl tests
    test-create-presentation/   # BLoC tests with bloc_test
  reference/
    domain.md              # Entities, repository interfaces, use cases, services, Failure
    data.md                # Models, payloads, mappers, datasources, repository impls
    presentation.md        # BLoC pattern, ViewDataState, Events, States, widget bindings
    di.md                  # get_it + injectable setup and patterns
    testing.md             # bloc_test, mockito, test structure
    navigation.md          # go_router setup and patterns
    project.md             # Folder structure, naming conventions, code style
    error-handling.md      # Failure, AppException, error flow
  CLAUDE-template.md       # Drop into downstream project as CLAUDE.md content
```

## How It Fits Into the Core Orchestrator

The core workers (`lib/core/agents/builder/`) are platform-agnostic. When invoked on a Flutter project, they call the skills in this platform folder:

```
builder-feature-orchestrator
  └─ domain-worker           →  skills/domain-create-entity
                             →  skills/domain-create-repository
                             →  skills/domain-create-usecase
  └─ data-worker             →  skills/data-create-mapper
                             →  skills/data-create-datasource
                             →  skills/data-create-repository-impl
  └─ presentation-worker     →  skills/pres-create-stateholder
  └─ builder-ui-worker       →  skills/pres-create-screen
  └─ builder-test-worker     →  skills/test-create-domain
                             →  skills/test-create-data
                             →  skills/test-create-presentation
```

## Key Patterns

- **Entity** — `@freezed`, no `fromJson`, `.freezed.dart` only
- **Model** — `@freezed` + `@JsonKey`, has `fromJson`, both `.freezed.dart` + `.g.dart`
- **Payload** — separate write class, same parts as Model
- **UseCase** — `implements UseCase<T, Params>`, `@lazySingleton`, returns `Either<Failure, T>`
- **BLoC** — `@injectable`, `ViewDataState<T>` in state, always `result.fold()`
- **RepositoryImpl** — `on AppException catch → Left(failure)`, generic `catch → unknownFailure`

## Reference Philosophy

References are **project-agnostic**. They document patterns, not project-specific utilities.
Downstream projects extend via `.claude/agents.local/extensions/<worker>.md`.
