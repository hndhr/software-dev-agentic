# iOS — Hybrid Embedding (Host Side)

> Canonical terms and communication model: `reference/builder/app-layer.md` — `## Hybrid Embedding` section.
> This file covers iOS-specific patterns using BrickWrap + FlutterModuleManager.

---

## Key Files <!-- 16 -->

| File | Role |
|------|------|
| `Talenta/BrickWrap/Bricks.swift` | Singleton entry point — engine init, module factory |
| `Talenta/BrickWrap/System/Utils/BricksEngineManager.swift` | FlutterEngineGroup lifecycle, channel creation, engine cache |
| `Talenta/BrickWrap/System/Navigator/BricksNavigator.swift` | Launches guest as full-screen `BricksViewController` |
| `Talenta/BrickWrap/System/Executor/BricksExecutor.swift` | Headless execution — invokes guest and awaits typed callback |
| `Talenta/BrickWrap/System/ViewController/BricksViewController.swift` | `FlutterViewController` subclass — hosts the guest UI, wires `BricksChannelDelegate` |
| `Talenta/BrickWrap/System/Navigator/BricksChannelDelegate.swift` | Handles inbound MethodChannel calls from guest (`sendResponse`, `sendActionRequest`, `is24HourFormat`) — iOS action callbacks are handled inline here, no separate ActionListener |
| `Talenta/BrickWrap/System/Configs/BrickChannelConfig.swift` | Channel name and method name constants |
| `Talenta/Utils/FlutterModuleManager/Factory/ModuleFactory.swift` | HostParams Assembler — builds the `HostParams` JSON blob per module type |
| `Talenta/Utils/FlutterModuleManager/<Name>/<Name>Manager.swift` | Feature-scoped entry point — builds `LaunchParams` and calls `openModule()` |

---

## Host → Guest: Navigation Launch <!-- 27 -->

```swift
// 1. Obtain the module
let module = Bricks.shared.getModule(module: PayslipModule.self)!

// 2. Assemble HostParams via ModuleFactory (HostParams Assembler)
let factory = ModuleFactory<PayslipParams>(moduleParams: PayslipParams(...))
let hostParamsString = factory.generateStringHostParams()

// 3. Build LaunchParams with a brick:// URI
let launchParam = LaunchParams(
    brickAddress: BricksAddress(
        host: PayslipConfig.host,
        path: PayslipConfig.route,
        param: hostParamsString,   // becomes ?hostParam=<json> in the URI
        engine: PayslipConfig.engineId
    ),
    presentingViewController: self
)

// 4. Launch — engine is created/reused; URI sent to guest via MethodChannel "open"
module.openModule(launchParam: launchParam, completion: { result in ... })
```

---

## Adding a New Module (iOS) <!-- 19 -->

1. **BrickWrap module class** — create `Talenta/BrickWrap/Modules/<Name>/<Name>Module.swift` conforming to `BricksModule`
2. **Config** — add `<Name>Config.swift` with `engineId`, `host`, and route constants
3. **Register in Bricks factory** — add a `case is <Name>Module.Type:` branch in `Bricks.getModule()`
4. **ResponseHandler** — create `<Name>ResponseHandler.swift`; register it in `BricksViewController.getResponseHandler()` by adding a `case <Name>Config.engineId:` branch to the switch:
   ```swift
   case <Name>Config.engineId:
       let handler = <Name>ResponseHandler(presentedViewController: self, route: route)
       handler.delegate = self
       return handler
   ```
5. **Action handling** — if the module fires `sendActionRequest` events, handle them inside `<Name>ResponseHandler.handleResponseCompletion(data:error:completion:)` — iOS has no separate ActionListener; action callbacks are dispatched through the ResponseHandler's completion block
6. **FlutterModuleManager entry** — add `<Name>Manager.swift` under `Utils/FlutterModuleManager/<Name>/` with the feature-facing API
7. **HostParams** — add `<Name>Params.swift` and `<Name>HostParams.swift`; register in `ModuleFactory.generateStringHostParams()` with a `case is <Name>Params.Type:` branch
8. **Coordinate** `moduleHost` constant and engine slot ID with the guest (Flutter) team — these must match `brick_constants.dart`

---

## MethodChannel Constants (iOS) <!-- 14 -->

```swift
// BrickChannelConfig.swift
static let methodChannel          = "com.mekari.module"     // channel name
static let sendMethodOpen         = "open"                  // host → guest: navigate
static let sendMethodExecute      = "execute"               // host → guest: headless
static let receiveResponseMethod  = "sendResponse"          // guest → host: result
static let receiveActionMethod    = "sendActionRequest"     // guest → host: native action
static let is24HourFormat         = "is24HourFormat"        // guest → host: query (sync)
```

---

## Engine Lifecycle <!-- 11 -->

- `FlutterEngineGroup` is created once in `Bricks.initialize()` and held by `BricksEngineManager.shared`
- Each module has a dedicated `engineId` string — engines are cached by this ID in `BricksEngineCache`
- `BricksEngineManager.buildBricksEngine(engineId:)` reuses a cached engine or creates a new one via `engineGroup.makeEngine(with:)`
- HostParams JSON is passed as `entrypointArgs` at engine creation time so the guest has config available even before the URI arrives; the same data is also encoded in the `brick://` URI's `?hostParam=` query argument — the guest reads from the URI
- `BricksEngineManager.inactiveEngine(engineId:)` removes the engine from cache on module close; called in the `BricksNavigator` completion block when `autoDismissModule` is true
- iOS does not have an explicit pre-warm API (unlike Android's `Bricks.preWarmEngine()`); the engine is created lazily on the first `buildBricksEngine(engineId:)` call

---

## ModuleFactory — HostParams Assembly <!-- 17 -->

`ModuleFactory<T>` (the HostParams Assembler on iOS) builds the JSON blob the guest receives as the `?hostParam=` URI query argument:

```swift
BaseHostParams(
    authenticationParams: <token, refreshToken, locale, isUseKong, useLegacyEndpoint>,
    toggleParams:         <feature toggle flags>,
    userParams:           <user profile>,
    moduleParams:         <module-specific params>,
    featureFlagParams:    <remote config flags>
)
```

Each module has a typed `<Name>HostParams` struct; `ModuleFactory.generateStringHostParams()` switches on `T.self` to pick the right struct.

**Note:** iOS does not currently pass `app_version`, `build_number`, `device_id`, `device_model`, or `os_version` as top-level config keys. Android does (via `BrickHelper.getFlutterAppProperty()` / `getFlutterDeviceProperty()`). If a guest feature reads these fields, they must be added to `ModuleFactory` on iOS too.
