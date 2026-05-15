# Android — Hybrid Embedding (Host Side)

> Canonical terms and communication model: `reference/builder/app-layer.md` — `## Hybrid Embedding` section.
> This file covers Android-specific patterns using bricks-talenta + BrickHelper.

---

## Key Files <!-- 17 -->

| File | Role |
|------|------|
| `bricks-talenta/.../Bricks.kt` | Singleton entry point — engine init (`FlutterEngineGroup`), module factory, `preWarmEngine()` |
| `bricks-talenta/.../system/utils/BricksEngineManager.kt` | Engine lifecycle, MethodChannel wiring, `buildEngine()`, `listen()`, `invokeMethod()` |
| `bricks-talenta/.../system/models/BrickModule.kt` | Abstract base — declares `engine`, `host`, `open()`, `execute()`, `createExecutorEngineId()` |
| `bricks-talenta/.../system/activity/BrickActivity.kt` | `FlutterActivity` subclass — hosts the guest UI, wires `BrickChannelDelegate` in `configureFlutterEngine()` |
| `bricks-talenta/.../system/navigator/BrickChannelDelegate.kt` | Handles inbound MethodChannel calls from guest (`sendResponse`, `sendActionRequest`, `is24HourFormat`) |
| `bricks-talenta/.../system/navigator/BrickNavigator.kt` | Builds the `Intent` for `BrickActivity` and starts it |
| `bricks-talenta/.../system/executor/BrickExecutor.kt` | Headless execution — invokes guest and awaits typed `ExecutorCallback<T>` |
| `bricks-talenta/.../system/configs/BrickChannelConfig.kt` | Channel name and all method name / key constants |
| `app/.../helper/brickhelper/BrickHelper.kt` | HostParams Assembler — builds `hostParam` JSON, handles standard action callbacks (download, redirection, token update, locale change) |
| `bricks-talenta/.../module/talenta/TalentaModule.kt` | Concrete module — wraps all feature routes as typed `openXxx()` / `executeXxx()` methods |

---

## Host → Guest: Navigation Launch <!-- 31 -->

```kotlin
// 1. Obtain the module
val module = Bricks.getModule<TalentaModule>(context)

// 2. Build hostParam JSON via BrickHelper (HostParams Assembler)
val hostParamJson = BrickHelper.getDefaultJsonObject(
    sessionPreference, remoteConfigFlagProvider
).apply {
    put("moduleJson", JSONObject().apply { /* module-specific params */ }.toString())
}.toString()

val params = MainParams(hostParam = hostParamJson)   // LaunchParam on Android

// 3. Call the typed module API — BrickModule.open() → BrickNavigator → BrickActivity Intent
module.openPayslipIndex(
    context = context,
    params = params,
    launcher = activityResultLauncher,   // optional — to receive back-navigation result
    actionListener = brickActionListener // optional ActionListener for guest→host action callbacks
)
```

Under the hood:
- `TalentaModule.openPage()` calls `BricksEngineManager.buildEngine(context, engineId)` to create/reuse the `FlutterEngine`
- `BrickNavigator.launch()` starts `BrickActivity` with the encoded `brick://` URI as an Intent extra
- `BrickActivity.onCreate()` calls `BrickChannelDelegate.startChannel()` → `MethodChannel.invokeMethod("open", {uri: ...})`

---

## Host → Guest: Headless Execution <!-- 19 -->

```kotlin
module.executeTmClearDatabase(
    context = context,
    params = params,
    callBack = object : ExecutorCallback<TmClearDatabaseResponse> {
        override fun onLoading() { ... }
        override fun onSuccess(response: TmClearDatabaseResponse?) { ... }
        override fun onError(code: Int, message: String) { ... }
    }
)
```

- `createExecutorEngineId(baseEngineId)` creates a UUID-suffixed engine ID — isolated from the navigation engine to avoid lifecycle conflicts
- `BricksEngineManager.listen()` registers the `MethodChannel.setMethodCallHandler` before invoking — handles `sendResponse` reply from guest

---

## BrickHelper — HostParams Assembly <!-- 29 -->

`BrickHelper` is the HostParams Assembler on Android. `getDefaultJsonObject()` builds the standard JSON blob passed as `hostParam`:

```kotlin
JSONObject().apply {
    put("authenticationJson", JSONObject().apply {
        put("token", ...)
        put("refreshToken", ...)
        put("locale", ...)          // resolved via LocaleHelper
        put("isUseKong", ...)
        put("useLegacyEndpoint", ...)
    }.toString())
    put("userJson", getSafeJson(userResponse))    // URL-safe encoded user profile
    put("toggleJson", Gson().toJson(toggleResponse))
    put("featureFlagJson", Gson().toJson(featureFlagResponse))
}
```

Module-specific keys (e.g., `KEY_PAYSLIP_JSON`, `KEY_INBOX_JSON`) are appended before converting to `MainParams(hostParam = json.toString())`.

Device and app properties are passed as **top-level global config keys** (not inside `hostParam`):
- `BrickHelper.getFlutterAppProperty()` → `app_version`, `build_number`
- `BrickHelper.getFlutterDeviceProperty()` → `device_id`, `device_model`, `os_version`, `device_fingerprint`

These are not currently passed on iOS. If a guest feature reads these fields, coordinate with the iOS team to add them to `ModuleFactory`.

---

## Guest → Host: Action Callbacks (ActionListener) <!-- 18 -->

Android uses an explicit `BrickActionListener` interface (the ActionListener canonical term). `BrickHelper.getDefaultBrickActionListener()` provides a standard implementation covering:

| Action name constant | Effect |
|---------------------|--------|
| `ACTION_UPDATE_TOKEN` | Updates cached `MsiAuthData` in `SessionPreference` |
| `BRICK_CONSTANTS_ACTION_DOWNLOAD` | Downloads file via `FileDownloadManager` |
| `BRICK_CONSTANTS_ACTION_REDIRECTION` | Opens deeplink / internal / external URL |
| `BRICK_CONSTANTS_ACTION_EXIT_APPLICATION` | Calls `finishAffinity` + `exitProcess(0)` |
| `BRICK_CONSTANTS_ACTION_CHANGE_LOCALE` | Updates locale via `LocaleHelper` + `SessionPreference` |

Custom actions are handled via the `onListen` lambda parameter.

**iOS difference:** iOS has no separate `ActionListener` interface. The same action events are handled inline inside `BricksChannelDelegate.setupMethodHandler()`.

---

## Adding a New Module (Android) <!-- 11 -->

1. **Module class** — create `bricks-talenta/.../module/<name>/<Name>Module.kt` extending `BrickModule`; add typed `openXxx()` methods calling `openPage()`
2. **Config** — add `<Name>Config.kt` with `ENGINE_ID` (the engine cache slot key, must match `brick_constants.dart` on Flutter side) and `HOST` constants; add `<Name>Routes.kt` for route string constants
3. **Register in Bricks factory** — add a branch in both `Bricks.getModule<T>()` and `Bricks.preWarmEngine()` switch expressions
4. **ResponseHandler** — create `<Name>ResponseHandler.kt`; register in `BrickActivity.configureFlutterEngine()` by adding a branch to the `when (cachedEngineId?.split("@")?.first())` switch — `cachedEngineId` is the `ENGINE_ID` string from `<Name>Config.kt`
5. **HostParams** — define `<Name>Params` data class; add module-specific JSON keys as constants in `BrickHelper`
6. **Coordinate** `moduleHost` constant (`brick_constants.dart`) and `ENGINE_ID` with the guest (Flutter) team — these must match exactly

---

## MethodChannel Constants (Android) <!-- 14 -->

```kotlin
// BrickChannelConfig.kt
const val METHOD_CHANNEL           = "com.mekari.module"    // channel name
const val SEND_METHOD_OPEN         = "open"                  // host → guest: navigate
const val SEND_METHOD_EXECUTE      = "execute"               // host → guest: headless
const val RECEIVE_RESPONSE_METHOD  = "sendResponse"          // guest → host: result → ResponseHandler
const val RECEIVE_ACTION_METHOD    = "sendActionRequest"     // guest → host: action → BrickActionListener
const val IS_24_HOUR_FORMAT_METHOD = "is24HourFormat"        // guest → host: query (sync)
```

---

## Engine Lifecycle <!-- 8 -->

- `FlutterEngineGroup` is created once in `Bricks.initialize()` and held by `BricksEngineManager`
- Each module has a dedicated `ENGINE_ID` — engines are cached in `FlutterEngineCacheImpl`
- `BricksEngineManager.buildEngine(context, engineId)` reuses a cached engine or creates a new one via `FlutterEngine.dartExecutor.executeDartEntrypoint()` with config JSON as entrypoint args; `Bricks.preWarmEngine()` can be called at app start to create the engine before the user triggers navigation
- Navigation engine and executor engine use different IDs (`createExecutorEngineId` appends UUID) — prevents lifecycle conflict when both are active simultaneously
- `BricksEngineManager.destroyEngine(engineId)` is called in `BrickActivity.onDestroy()` and on lifecycle-observed destroy
- `BricksEngineManager.attachedEngineId` tracks the currently attached engine to guard against stale channel replies
