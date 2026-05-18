# Flutter Qontak — Presentation Layer

> Concepts and invariants: `lib/core/reference/code-architecture/presentation-theory.md`. This file covers Dart syntax and patterns.

BLoC pattern. Widgets are dumb — they react to state and dispatch events. Business logic lives in BLoCs via use cases.

---

## Dependency Rule <!-- 8 -->

Presentation depends on Domain only — no Data layer imports. BLoC and Screen widgets may only import domain use case interfaces, domain entities, and Dart/Flutter primitives.

Forbidden: any `RepositoryImpl`, `DataSourceImpl`, `DTO`, mapper, `http`/`dio` import, or database type inside the Presentation layer.

---

## StateHolder <!-- 12 -->

In Flutter Qontak, the StateHolder is implemented as a **BLoC** (for event-driven flows) or **Cubit** (for simpler state). See `## BLoC` and `## Cubit (Simple State)` below for full implementation patterns.

Invariants:
- Receives use cases via constructor injection — annotated `@injectable`, created fresh per screen via `GetIt.instance`
- Emits immutable `State` objects — never mutates state in place; use `emit(state.copyWith(...))`
- Handles navigation as a side effect via `BlocListener` — not as a direct `Navigator.push` inside the BLoC
- One BLoC/Cubit per screen — scoped to the screen's `BlocProvider`

---

## State <!-- 11 -->

In Flutter Qontak, **State** is an immutable `@freezed` class with a `ViewDataState<T>` field per async operation (from `[prefix]_core`). See `## States` below for the full pattern.

Invariants:
- Immutable — produced by the BLoC via `emit`; widgets observe, never mutate
- One `ViewDataState<T>` per distinct async operation — no raw `isLoading` booleans
- No widget types — no `Color`, `Widget`, `BuildContext` in state classes

---

## Events / Input <!-- 11 -->

In Flutter Qontak (BLoC), Events are `@freezed sealed class` cases dispatched by the widget via `context.read<XBloc>().add(XEvent.loadX())`. In Cubit, they are direct method calls. See `## Events` below.

Invariants:
- Named after user actions using verb + noun — `loadInbox`, `markAsRead`, not `buttonTapped`
- Carry only the data needed — no `BuildContext`, no raw widget references
- Processed by the BLoC's `on<Event>` handler — widgets never act on events directly

---

## Actions / Output <!-- 11 -->

In Flutter Qontak, Actions/Output are navigation and one-time side effects handled via `BlocListener`. See `## BlocListener (Side Effects)` below.

Invariants:
- One-shot — triggered by a state transition (e.g. `markReadState.hasError`), consumed once in `BlocListener`
- Named after the outcome — navigate, show snackbar, close dialog
- Navigation targets are abstract — the BLoC transitions state; the `BlocListener` in the widget decides *how* to navigate

---

## StateHolder Contract <!-- 11 -->

Before `builder-ui-worker` writes the Screen, `builder-feature-worker` produces `.claude/runs/<feature>/stateholder-contract.md` containing:
- BLoC/Cubit class name and file path
- `State` fields (name, type, purpose)
- `Event` cases or Cubit method signatures (name, payload if any)
- Navigation side-effect triggers (which state transition causes navigation)
- DI factory (`@injectable` or `@lazySingleton`)

---

## Creation Order <!-- 10 -->

```
Use Cases → BLoC/Cubit (StateHolder) → StateHolder contract → Screen (builder-ui-worker)
```

Never write the Screen before the StateHolder contract exists.

---

## Layer Invariants <!-- 10 -->

- BLoC/Cubit never imports from the data layer — no DTOs, no `RepositoryImpl`, no `DataSource`
- Use cases injected via constructor — never `GetInbox()` inside a BLoC body
- State is read-only from widgets' perspective — widgets observe via `BlocBuilder`, never mutate
- Navigation side effects are one-shot — triggered via `BlocListener`, not stored in persistent state
- Navigation decisions belong to the widget layer — BLoC transitions state; the listener navigates

---

## ViewDataState (shared in `[prefix]_core`) <!-- 46 -->

```dart
// shared/[prefix]_core/lib/src/presentation/view_data_state.dart
import 'package:equatable/equatable.dart';
import '../domain/failure.dart';

enum ViewState { initial, loading, loaded, error, empty }

class ViewDataState<T> extends Equatable {
  const ViewDataState._({
    required this.status,
    this.data,
    this.message,
    this.failure,
  });

  final ViewState status;
  final T? data;
  final String? message;
  final Failure? failure;

  factory ViewDataState.initial() =>
      const ViewDataState._(status: ViewState.initial);
  factory ViewDataState.loading({String? message}) =>
      ViewDataState._(status: ViewState.loading, message: message);
  factory ViewDataState.loaded({T? data}) =>
      ViewDataState._(status: ViewState.loaded, data: data);
  factory ViewDataState.error({required String message, Failure? failure, T? data}) =>
      ViewDataState._(status: ViewState.error, message: message, failure: failure, data: data);
  factory ViewDataState.empty({String? message}) =>
      ViewDataState._(status: ViewState.empty, message: message);

  bool get isInitial => status == ViewState.initial;
  bool get isLoading => status == ViewState.loading;
  bool get isLoaded => status == ViewState.loaded;
  bool get hasError => status == ViewState.error;
  bool get isEmpty => status == ViewState.empty;

  @override
  List<Object?> get props => [status, data, message, failure];
}
```

---

## Events <!-- 21 -->

```dart
// [prefix]_inbox/lib/src/presentation/blocs/inbox_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_event.freezed.dart';

@freezed
sealed class InboxEvent with _$InboxEvent {
  const factory InboxEvent.loadInbox() = LoadInbox;
  const factory InboxEvent.refreshInbox() = RefreshInbox;
  const factory InboxEvent.markAsRead({required String conversationId}) = MarkAsRead;
  const factory InboxEvent.searchInbox({required String query}) = SearchInbox;
}
```

**Event naming:** `loadXxx` (initial fetch) · `refreshXxx` (user pull-to-refresh) · `submitXxx` / `updateXxx` / `deleteXxx` (mutations) · `selectXxx` / `searchXxx` (UI-only state).

---

## States <!-- 28 -->

```dart
// [prefix]_inbox/lib/src/presentation/blocs/inbox_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:[prefix]_core/[prefix]_core.dart';
import '../../domain/entities/conversation.dart';

part 'inbox_state.freezed.dart';

@freezed
class InboxState with _$InboxState {
  const factory InboxState({
    required ViewDataState<List<Conversation>> inboxState,
    required ViewDataState<void> markReadState,
  }) = _InboxState;

  factory InboxState.initial() => InboxState(
        inboxState: ViewDataState.initial(),
        markReadState: ViewDataState.initial(),
      );
}
```

One `ViewDataState<T>` per distinct async operation. No raw `isLoading` booleans.

---

## BLoC <!-- 50 -->

```dart
// [prefix]_inbox/lib/src/presentation/blocs/inbox_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:[prefix]_core/[prefix]_core.dart';
import '../../domain/usecases/get_inbox.dart';
import 'inbox_event.dart';
import 'inbox_state.dart';

@injectable
class InboxBloc extends Bloc<InboxEvent, InboxState> {
  InboxBloc(this._getInbox) : super(InboxState.initial()) {
    on<LoadInbox>(_onLoadInbox);
    on<RefreshInbox>(_onLoadInbox);
  }

  final GetInbox _getInbox;

  Future<void> _onLoadInbox(
    InboxEvent event,
    Emitter<InboxState> emit,
  ) async {
    emit(state.copyWith(inboxState: ViewDataState.loading()));

    final result = await _getInbox(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        inboxState: ViewDataState.error(message: failure.message, failure: failure),
      )),
      (conversations) => emit(state.copyWith(
        inboxState: conversations.isEmpty
            ? ViewDataState.empty()
            : ViewDataState.loaded(data: conversations),
      )),
    );
  }
}
```

**BLoC rules:**
- `@injectable` — fresh instance per screen
- Each handler emits loading first, then result
- Always `result.fold()` — never `result.getOrElse()` alone
- Use `Emitter<State>` — never call `emit()` after `await` on a closed BLoC

---

## Screen Structure <!-- 54 -->

```dart
// [prefix]_inbox/lib/src/presentation/screens/inbox_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../blocs/inbox_bloc.dart';
import '../blocs/inbox_event.dart';
import '../blocs/inbox_state.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<InboxBloc>()
        ..add(const InboxEvent.loadInbox()),
      child: const _InboxView(),
    );
  }
}

class _InboxView extends StatelessWidget {
  const _InboxView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: BlocBuilder<InboxBloc, InboxState>(
        buildWhen: (prev, curr) => prev.inboxState != curr.inboxState,
        builder: (context, state) {
          final s = state.inboxState;
          if (s.isLoading || s.isInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(child: Text(s.message ?? 'Error'));
          }
          if (s.isEmpty) {
            return const Center(child: Text('No conversations'));
          }
          return ConversationList(conversations: s.data!);
        },
      ),
    );
  }
}
```

---

## BlocListener (Side Effects) <!-- 24 -->

```dart
BlocListener<InboxBloc, InboxState>(
  listenWhen: (prev, curr) => prev.markReadState != curr.markReadState,
  listener: (context, state) {
    if (state.markReadState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.markReadState.message ?? 'Failed')),
      );
    }
  },
  child: ...,
)
```

| Use | When |
|---|---|
| `BlocBuilder` | Rebuild widgets |
| `BlocListener` | Side effects: navigate, toast, analytics |
| `BlocConsumer` | Both in the same tree |

---

## Cubit (Simple State) <!-- 14 -->

```dart
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);
  void toggle() => emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
}
```

Use Cubit when there are no events — only direct method calls, no payloads.

---

## Shared Component Paths <!-- 8 -->

| Scope | Path |
|---|---|
| Cross-feature widgets | `shared/[prefix]_core/lib/src/widgets/` |
| Feature-local widgets | `features/[prefix]_xxx/lib/src/presentation/widgets/` |

Search `[prefix]_core` widgets first before creating a new one.
