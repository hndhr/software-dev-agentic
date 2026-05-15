# Flutter — Hybrid Embedding (Guest Side)

> Canonical terms and communication model: `reference/builder/app-layer.md` — `## Hybrid Embedding` section.
> This file covers the Flutter guest side — how the Dart module receives host context and calls back to native.

---

## Key Files <!-- 15 -->

| File | Role |
|------|------|
| `talenta/lib/src/brick/brick_module.dart` | `TalentaModule` — `BrickModule` impl, declares routes and DI bindings |
| `talenta/lib/src/brick/brick_router.dart` | `TalentaModuleRouter` — resolves a `brick://` URI to a `BrickWidget` |
| `talenta/lib/src/brick/brick_executor.dart` | `TalentaModuleExecutor` — headless execution path, returns `ExecutorResponse` |
| `talenta/lib/src/brick/brick_constants.dart` | Module host constant (`moduleHost`) — must match the host's engine config |
| `talenta/lib/src/brick/brick_app.dart` | `BrickApp` — root widget wrapping all guest content |
| `talenta/lib/src/shared/core/module/module_manager.dart` | `TalentaModuleManager` — maps base routes to sub-module handlers |

The `brick_way` package (external dependency) provides `BrickModule`, `BrickRouter`, `BrickExecutor`, `BrickWidget`, `Bricks`, and MethodChannel plumbing — the guest never calls `MethodChannel` directly.

---

## Guest → Host: Response / Action <!-- 23 -->

The guest never calls `MethodChannel` directly. All calls go through `brick_way`:

```dart
// Return data to host after a navigation flow completes
BricksChannel.sendResponse(data: {...});

// Return an error to host
BricksChannel.sendResponse(error: {...});

// Request a native action (e.g., open a native screen)
BricksChannel.sendActionRequest(
  actionName: 'openPage',
  actionData: {'page': {'ios': 'NativeClassName', 'android': 'co.talenta.NativeActivity'}},
);
```

The host `BricksChannelDelegate` (iOS) / `BrickChannelDelegate` (Android) receives these via `setMethodCallHandler`.
On Android, `sendActionRequest` is routed to the registered `BrickActionListener`. On iOS, it is handled inline in `BricksChannelDelegate`.

---

## Receiving HostParams <!-- 37 -->

HostParams arrive as the `hostParam` query argument in the URI. `BrickRouter.getTarget()` and `BrickExecutor.execute()` both parse them via:

```dart
final argument = getArgument(uri)['hostParam'] ?? '';
final Map<String, dynamic> hostJson = json.decode(argument); // synchronous — not a Future

// Standard keys (all platforms)
final authJson    = hostJson[Constants.authenticationJson]; // token, refreshToken, locale, isUseKong
final userJson    = hostJson[Constants.userJson];           // user profile
final toggleJson  = hostJson[Constants.toggleJson];         // feature toggles
final flagJson    = hostJson[Constants.featureFlagJson];    // remote config flags

// Android-only top-level config keys (passed via Bricks.initialize() global config, not hostParam)
// app_version, build_number    — from BrickHelper.getFlutterAppProperty()
// device_id, device_model,
// os_version, device_fingerprint — from BrickHelper.getFlutterDeviceProperty()
```

After decoding, call `ExternalDataSourceHelper.initializeConfig()` to seed the decoded blobs into in-memory config — this is required before rendering any feature screen:

```dart
await ExternalDataSourceHelper.initializeConfig(
  externalDataSource: ...,
  prefHelper: ...,
  userJson: userJson,
  toggleJson: toggleJson,
  authenticationJson: authJson,
  featureFlagJson: flagJson,
  hostType: hostType,
  mekariLogManager: ...,
);
```

---

## Adding a New Guest Module <!-- 11 -->

1. **Create a sub-module** under the relevant module directory with its own routes, BLoC, and DI
2. **Register routes** in the module manager's route resolver (`getResolvingModule(baseRoute)`) — map the base route string to the sub-module handler
3. **Add DI init** in the module manager's initialization method (`initializeModuleDependencies()`) if the sub-module has its own DI
4. **Declare routes** in `TalentaModule.routes` getter — this is consumed by the guest's `BrickRouter` to determine which URIs this module handles; it is **not** read by the host
5. **Seed HostParams** — ensure both `BrickRouter.getTarget()` and `BrickExecutor.execute()` call `ExternalDataSourceHelper.initializeConfig()` (or equivalent) before invoking the sub-module
6. **Coordinate with host team** — agree on the `moduleHost` value in `brick_constants.dart` and the engine slot ID string; these must match the host's `<Name>Config.engineId` / `ENGINE_ID` exactly

---

## MethodChannel Constants (Flutter / brick_way) <!-- 10 -->

```
Channel name:      com.mekari.module
open               host → guest: render URI as full-screen page
execute            host → guest: run URI headlessly
sendResponse       guest → host: return data or error (routed to ResponseHandler)
sendActionRequest  guest → host: request native action (routed to ActionListener on Android, inline on iOS)
is24HourFormat     guest → host: query device locale format (sync reply)
```
