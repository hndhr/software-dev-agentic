# Flutter — App Layer

> Concepts and invariants: `reference/builder/app-layer.md`. This file covers Dart/get_it patterns for Flutter.

## Dependency Registration <!-- 44 -->

Flutter uses **get_it** as the service locator with **injectable** code generation per feature.

**Step 1 — Create the feature DI file:**

```dart
// talenta/lib/src/features/{feature}/configs/di/{feature}_dependencies.dart

import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';

@module
abstract class {Feature}Dependencies {
  @lazySingleton
  {Feature}Repository get{Feature}Repository(
    {Feature}RemoteDataSource remoteDataSource,
  ) =>
      {Feature}RepositoryImpl(remoteDataSource: remoteDataSource);

  @lazySingleton
  {Feature}RemoteDataSource get{Feature}RemoteDataSource(
    ApiClient apiClient,
  ) =>
      {Feature}RemoteDataSourceImpl(apiClient: apiClient);

  @lazySingleton
  Get{Feature}ListUseCase get{Feature}ListUseCase(
    {Feature}Repository repository,
  ) =>
      Get{Feature}ListUseCase(repository: repository);
}
```

**Step 2 — Register the DI module in `talenta_dependencies.dart`:**

```dart
// lib/src/configs/di/talenta_dependencies.dart

// Add the import:
import 'package:talenta/src/features/{feature}/configs/di/{feature}_dependencies.dart';

// The @module class is picked up automatically by build_runner — no manual registration needed.
// Run:
// flutter pub run build_runner build --delete-conflicting-outputs
```

**Rules:**
- ✅ One `@module` abstract class per feature under `configs/di/`
- ✅ Use `@lazySingleton` for repositories, data sources, and use cases
- ✅ Use `@injectable` on BLoC classes (BLoCs are never singletons — new instance per page)
- ✅ Run `build_runner` after any DI change to regenerate `*.g.dart` files
- ❌ Never call `GetIt.instance.registerSingleton(...)` manually — always use annotations

---

## Route Registration <!-- 44 -->

Flutter features declare routes via a **route constants file** and a **route factory class**.

**Step 1 — Create the route constants:**

```dart
// talenta/lib/src/features/{feature}/utils/navigation/{feature}_route.dart

abstract class {Feature}Route {
  static const String root = '/{feature}';
  static const String detail = '/{feature}/detail';
}
```

**Step 2 — Create the route factory:**

```dart
// talenta/lib/src/features/{feature}/utils/navigation/{feature}_route_factory.dart

import 'package:flutter/widgets.dart';

class {Feature}RouteFactory {
  static Widget? getPageByName(String name, {Map<String, dynamic>? args}) {
    switch (name) {
      case {Feature}Route.root:
        return {Feature}Page();
      case {Feature}Route.detail:
        return {Feature}DetailPage(id: args?['id'] as String? ?? '');
      default:
        return null;
    }
  }

  static List<RouteProvider>? getListProviderByName(String name) {
    switch (name) {
      case {Feature}Route.root:
        return [{Feature}BlocProvider()];
      default:
        return null;
    }
  }
}
```

**Step 3 — Register the factory in the module (handled in Module Registration below).**

**Rules:**
- ✅ Route constants are plain `abstract class` with `static const String` — no logic
- ✅ `getPageByName` returns `null` for unknown routes — caller falls through to next factory
- ✅ `getListProviderByName` returns BLoC providers needed by the page
- ❌ No `Navigator.push` calls inside route factories — factories are page builders only

---

## Module Registration <!-- 36 -->

Flutter uses **BaseModule** + **TalentaModuleManager** for explicit feature module registration.

**Step 1 — Create the feature module:**

```dart
// talenta/lib/src/features/{feature}/{feature}.dart

import 'package:talenta_core/talenta_core.dart';

class {Feature}Module extends BaseModule {
  @override
  String get name => '{feature}';

  @override
  Widget? getPageByName(String name, {Map<String, dynamic>? args}) =>
      {Feature}RouteFactory.getPageByName(name, args: args);

  @override
  List<RouteProvider>? getListProviderByName(String name) =>
      {Feature}RouteFactory.getListProviderByName(name);
}
```

**Step 2 — Register in TalentaModuleManager:**

```dart
// talenta/lib/src/shared/core/module/module_manager.dart

import 'package:talenta/src/features/{feature}/{feature}.dart';

class TalentaModuleManager {
  static final List<BaseModule> _modules = [
    // ... existing modules
    {Feature}Module(),  // ← add here
  ];

  // existing registration logic...
}
```

**Rules:**
- ✅ One `BaseModule` subclass per feature
- ✅ `name` must be unique across all modules — use the feature's snake_case identifier
- ✅ Module delegates all routing to `{Feature}RouteFactory` — no inline page construction
- ✅ Register in `TalentaModuleManager._modules` list — never elsewhere
- ❌ No lifecycle logic in the module — `onStart`/`onStop` hooks are not used in Talenta's BaseModule
