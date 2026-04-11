# Flutter Platform — Stub

This platform is not yet implemented.

## What belongs here

```
platforms/flutter/
  agents/
    domain-worker.md          # Dart entity + repository protocol + use case
    data-worker.md            # Repository impl + datasource (Dio/http)
    presentation-worker.md    # BLoC/Cubit: Event, State, Bloc class
    test-worker.md            # flutter_test + mocktail/mockito
    ui-worker.md              # Widget: BlocBuilder/BlocListener/BlocConsumer bindings
  skills/
    domain-create-entity/     # Dart class with freezed or plain
    domain-create-repository/ # Abstract class (repository protocol)
    domain-create-usecase/    # UseCase base class pattern
    data-create-datasource/   # Dio/http datasource
    data-create-repository-impl/
    pres-create-stateholder/  # BLoC or Cubit
    pres-create-screen/       # StatelessWidget + BlocProvider
    test-create-*/
  reference/
    domain.md
    data.md
    presentation.md           # BLoC pattern, State/Event design
    di.md                     # get_it or injectable
    testing.md
  CLAUDE-template.md
```

## Orchestration model

`pres-orchestrator` (core) applies here exactly as it does for iOS:
- `presentation-worker` creates the BLoC/Cubit with its Event and State types
- `ui-worker` creates the Widget with BlocBuilder/BlocListener wired to the exact event/state contract

`feature-orchestrator` (core) coordinates domain-worker → data-worker → presentation-worker
as the standard CLEAN feature build sequence.

## When to implement

Implement when onboarding the first Flutter project. Start with:
1. `reference/` — map the project's BLoC patterns and DI (get_it or injectable)
2. `agents/domain-worker.md` + `agents/data-worker.md` — Dart CLEAN patterns
3. `agents/presentation-worker.md` + `agents/ui-worker.md` — BLoC + Widget
4. Skills — one feature's templates extracted into reusable skill templates
