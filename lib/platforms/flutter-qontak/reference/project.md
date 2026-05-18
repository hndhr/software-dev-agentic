# Flutter Modular — Project Structure & Conventions

---

## Workspace Layout <!-- 40 -->

Managed by `melos`. The codebase is split into three module types:

```
/ (workspace root = Application module)
├── lib/
│   ├── main.dart
│   ├── gen/                     ← generated assets (l10n, routing, images)
│   ├── configs/
│   │   ├── constants/
│   │   ├── env/
│   │   ├── di/                  ← global DI root (registers all modules)
│   │   └── routing/
│   ├── data/                    ← app-level data (splash, onboarding only)
│   ├── domain/                  ← app-level domain (rarely used)
│   └── presentation/
│       ├── screens/             ← splash, onboarding, main entry screens
│       └── widgets/
├── features/                    ← Feature modules (Flutter packages)
│   ├── [prefix]_auth/
│   ├── [prefix]_home/
│   └── ...
├── shared/                      ← Shared modules (Flutter packages)
│   ├── [prefix]_core/           ← cross-cutting: networking, utils, base classes
│   └── [prefix]_dependencies/   ← single source of truth for all pub dependencies
├── android/
├── ios/
├── melos.yaml
└── pubspec.yaml
```

**Rules:**
- Application module owns only entry-point screens (splash, onboarding, main nav shell).
  All feature code lives in feature packages.
- `features/` and `shared/` directories contain only Flutter packages (own `pubspec.yaml`).
- `[prefix]` = project name prefix (e.g., `chat_`, `talenta_`). Apply to every package name.

---

## Module Types <!-- 11 -->

| Type | What it contains | Depends on |
|---|---|---|
| **Application module** | `main.dart`, configs, DI root, routing, entry-point screens | All feature modules + core |
| **Feature module** | Complete feature (data + domain + presentation) | `[prefix]_core`, `[prefix]_dependencies` |
| **Core module** (`[prefix]_core`) | Networking, logging, base classes, Module API abstractions | `[prefix]_dependencies` |
| **Dependencies module** (`[prefix]_dependencies`) | All shared pub dependencies re-exported | Nothing (leaf node) |

---

## Dependency Graph <!-- 16 -->

```
Application module
  └─ feature_auth
  └─ feature_home
  └─ ...
       └─ [prefix]_core
              └─ [prefix]_dependencies
```

**Rule:** Feature modules must NOT depend on other feature modules. Cross-feature
communication goes through `[prefix]_core` Module API abstractions.

---

## Feature Module Folder Structure <!-- 39 -->

Each feature module mirrors the single-package clean architecture layout but inside a Flutter package:

```
features/[prefix]_auth/
├── lib/
│   ├── [prefix]_auth.dart          ← package entry point (barrel/public API)
│   ├── src/
│   │   ├── configs/
│   │   │   ├── auth_module.dart    ← BaseModule implementation
│   │   │   └── auth_di.dart        ← @module DI class
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── mappers/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── screens/
│   │       └── widgets/
├── assets/
│   └── l10n/
│       └── auth_en.arb             ← feature-scoped translations
├── test/
└── pubspec.yaml
```

**Rules:**
- `lib/[prefix]_auth.dart` is the only public API surface. Export selectively.
- `src/` contains all private implementation — never import `src/` from outside.
- Assets and translations are scoped to the feature package.

---

## Shared Module — Core Folder Structure <!-- 18 -->

```
shared/[prefix]_core/
├── lib/
│   ├── [prefix]_core.dart          ← public API barrel
│   └── src/
│       ├── network/                ← HTTP client, interceptors
│       ├── logging/
│       ├── utils/
│       ├── base/                   ← base classes (UseCase, BaseModule, etc.)
│       └── module_api/             ← Module API abstractions (one per feature)
│           └── auth_module_api.dart
└── pubspec.yaml
```

---

## Package Naming Conventions <!-- 13 -->

| What | Pattern | Example (prefix = `chat`) |
|---|---|---|
| Feature package | `[prefix]_[domain]` | `chat_auth`, `chat_inbox` |
| Core shared | `[prefix]_core` | `chat_core` |
| Dependencies | `[prefix]_dependencies` | `chat_dependencies` |
| Module API abstract class | `[Domain]ModuleApi` | `AuthModuleApi` |
| Module API impl class | `[Domain]ModuleApiImpl` | `AuthModuleApiImpl` |
| BaseModule impl | `[Domain]Module` | `AuthModule` |

---

## Model Naming (Data Layer) <!-- 13 -->

Extends the `flutter` platform conventions with explicit DTO suffixes:

| Type | Suffix | Example |
|---|---|---|
| API response model | `Response` | `LoginResponse` |
| API request body | `Request` | `LoginRequest` |
| Database entity (DTO) | `Db` | `UserDb` |
| Domain entity | _(none)_ | `User` |

---

## Mapper Convention <!-- 13 -->

Mapper is a non-instantiable class with static methods named `from{Source}To{Destination}`:

```dart
class UserMapper {
  const UserMapper._();

  static User fromResponseToEntity(UserResponse response) => ...;
  static UserDb fromEntityToDb(User entity) => ...;
  static User fromDbToEntity(UserDb db) => ...;
}
```
