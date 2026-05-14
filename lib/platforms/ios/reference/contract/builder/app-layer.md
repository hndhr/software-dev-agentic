# iOS — App Layer

> Concepts and invariants: `reference/builder/app-layer.md`. This file covers Swift/Needle patterns for iOS.

## Dependency Registration <!-- 55 -->

iOS uses **Needle** — a compile-time, hierarchical component tree. Each feature has its own `Component<DependencyType>`.

**Component hierarchy:**
```
RootComponent
  └── MainTabComponent
        └── {Feature}Component (child component per feature)
```

**Step 1 — Define the Dependency protocol:**

```swift
// Talenta/DIComponents/{Feature}/{Feature}Dependency.swift
protocol {Feature}Dependency: Dependency {
    var get{Feature}UseCase: Get{Feature}UseCase { get }
    var {feature}Repository: {Feature}Repository { get }
}
```

**Step 2 — Implement the Component:**

```swift
// Talenta/DIComponents/{Feature}/{Feature}Component.swift
final class {Feature}Component: Component<{Feature}Dependency> {
    var get{Feature}UseCase: Get{Feature}UseCase {
        Get{Feature}UseCase(repository: dependency.{feature}Repository)
    }

    var {feature}Repository: {Feature}Repository {
        {Feature}RepositoryImpl.sharedInstance
    }
}
```

**Step 3 — Wire into MainTabComponent:**

```swift
// Talenta/DIComponents/MainTab/MainTabComponent.swift
extension MainTabComponent: {Feature}Dependency {
    var {feature}Repository: {Feature}Repository {
        {Feature}RepositoryImpl.sharedInstance
    }
}
```

**Step 4 — Needle code generation:**

After adding a new component, run Needle's code generator:
```bash
needle generate Talenta/DIComponents/NeedleGenerated.swift Talenta/
```

**Rules:**
- ✅ One `Component` per feature
- ✅ Declare dependencies in the `Dependency` protocol — never access sibling components directly
- ✅ `NeedleGenerated.swift` is always auto-generated — never edit by hand
- ❌ No service locators or singletons outside Needle except `sharedInstance` on `*Impl` types

---

## Route Registration <!-- 48 -->

iOS uses the **Coordinator pattern** with `BaseCoordinator<ResultType>`.

**Step 1 — Create the Feature Coordinator:**

```swift
// Talenta/Controllers/{Feature}/{Feature}Coordinator.swift
final class {Feature}Coordinator: BaseCoordinator<{Feature}Result> {

    private let navigationController: UINavigationController
    private let component: {Feature}Component

    init(
        navigationController: UINavigationController,
        component: {Feature}Component
    ) {
        self.navigationController = navigationController
        self.component = component
    }

    override func start() -> Observable<{Feature}Result> {
        let viewModel = {Feature}ViewModel(
            navigator: self,
            get{Feature}UseCase: component.get{Feature}UseCase
        )
        let viewController = {Feature}ViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)

        return viewModel.result
            .take(1)
            .do(onNext: { [weak self] _ in
                self?.navigationController.popViewController(animated: true)
            })
    }
}
```

**Step 2 — Register deep link (if applicable):**

```swift
// Talenta/DIComponents/Deeplink/DeeplinkComponent.swift
extension DeeplinkComponent {
    func coordinate{Feature}(path: String) -> Observable<Void> {
        let component = {Feature}Component(parent: self)
        let coordinator = {Feature}Coordinator(
            navigationController: rootNavigationController,
            component: component
        )
        return coordinate(to: coordinator).map { _ in }
    }
}
```

**Rules:**
- ✅ One coordinator per feature flow
- ✅ `BaseCoordinator<ResultType>` — result type models what the coordinator returns to its parent
- ✅ Rx lifecycle: `start()` returns `Observable<ResultType>` — parent subscribes
- ❌ No `UIViewController` subclasses performing navigation directly

---

## Module Registration <!-- 16 -->

iOS does **not** use an explicit `ModuleManager`. Features are linked implicitly via the Needle component hierarchy. No module registration step is needed.

**Component child registration is implicit:** Adding a `{Feature}Component(parent: mainTabComponent)` at the call site is sufficient — Needle generates the bootstrap code automatically.

**Summary:**
| Step | Required? |
|---|---|
| Dependency Registration (Needle Component) | ✅ Required |
| Route Registration (Coordinator) | ✅ Required |
| Module Registration (ModuleManager) | ❌ Not applicable — Needle handles this implicitly |

---

## Analytics Constants <!-- 26 -->

Event names and screen identifiers are declared as a Swift struct in the feature's `Constants/` directory.

```swift
// Talenta/Module/{Feature}/Constants/{Feature}FirebaseName.swift
struct {Feature}FirebaseName {
    static let screenName  = "{feature}_screen"
    static let tapEvent    = "{feature}_tap"
    static let submitEvent = "{feature}_submit"
}
```

**Path:** `Talenta/Module/{Feature}/Constants/{Feature}FirebaseName.swift`

**Rules:**
- ✅ One `struct` per feature — no shared analytics constants file
- ✅ `static let` string constants only — no logic, no SDK imports
- ✅ snake_case values match Firebase naming convention
- ❌ Never import the Analytics SDK in this constants file
- ❌ Never use inline string literals in ViewModels — always reference these constants

**When to create:** Any feature that instruments user interactions or screen views. Optional — skip if the feature has no analytics events.

---

## Feature Flag Registration <!-- 32 -->

iOS uses **MekariFlagCustomProvider** (`Utils/MekariFlag/MekariFlagCustomProvider.swift`) backed by the MekariFlag SDK (Flagsmith). Add a new case to `FeatureIdentity` — the case name is the flag key.

> ⚠️ `FeatureFlagKey` / `FeatureFlagCollection` in `Shared/Infrastructure/FeatureFlag/FeatureFlag.swift` is the V2 system — **not in use yet**. Do not add to it.

**Add to `FeatureIdentity` enum:**

```swift
// Utils/MekariFlag/MekariFlagCustomProvider.swift
enum FeatureIdentity: String {
    // ... existing cases
    case isEnable{Feature}  // ← add here — case name = Flagsmith flag key
}
```

**Read the flag value:**

```swift
// In ViewModel or DataSource — inject MekariFlagCustomProtocol
let isEnabled = flagProvider.getBoolValue(forFeature: FeatureIdentity.isEnable{Feature}.rawValue)
```

**Rules:**
- ✅ Case name must exactly match the flag key string configured in Flagsmith — confirm with backend
- ✅ Inject `MekariFlagCustomProtocol` — never access `MekariFlagCustomProvider` directly in business logic
- ❌ Never use raw string literals for flag keys — always reference `FeatureIdentity`

**When to add:** Any feature that requires remote gating or gradual rollout. Optional — skip for features that launch immediately to 100% of users.

---

## Push Notification Registration <!-- 20 -->

Push notifications and deeplinks share the same delivery path — both ultimately write to `DeeplinkStreamImpl.shared`. No per-feature notification registration is needed; the infrastructure is wired once in `AppDelegate`.

**Token lifecycle:**
- `AppDelegate.messaging(_:didReceiveRegistrationToken:)` receives new FCM tokens → calls `FCMManager.setToken(value:)` (stores locally) and `FCMManager.postToken()` (posts to server via `PostSendFCMTokenUseCase`)
- On logout: call `FCMManager.deletePostToken()` — deletes from server (`DeleteFCMTokenUseCase`), clears local storage, and removes from the Messaging SDK
- Token lifecycle is **not** automatic on login/logout — the auth flow must explicitly call `postToken()` on login and `deletePostToken()` on logout

**Notification tap → deeplink routing:**

`AppDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` receives the tap → delegates to `FCMManager.handlePushNotification(userInfo:)` which parses the payload by `navigation_type`:

| `navigation_type` | Payload field | Action |
|---|---|---|
| `deeplinking` | `deeplink_ios` (URL string) | `DeeplinkData(url:)` → `DeeplinkStreamImpl.shared.set(deeplink:)` |
| `screenName` | `screen_name_ios` (path string) | `DeeplinkData(url:nil, payload:)` → `DeeplinkStreamImpl.shared.set(deeplink:)` |
| `uri` | `uri` | `UIApplication.openScreenBasedOnURL()` — bypasses DeeplinkStream |
| *(legacy)* | `type` (DeeplinkPath rawValue) | `DeeplinkStreamImpl.shared.set(deeplink:)` |

**When a new notification type must route to a new screen:** add a `DeeplinkPath` case and ensure the push payload includes `screen_name_ios` with that case's rawValue. `DeeplinkData` parses it automatically. No new files needed.

---

## Deeplink Registration <!-- 54 -->

All deeplink sources — push notification taps, URL schemes, universal links, and home screen quick actions — converge on a single `DeeplinkStreamImpl.shared` (`Talenta/DIComponents/DataStream/DeeplinkStream.swift`). Coordinators subscribe to the stream; they never parse URLs or payloads directly.

**Entry points:**

| Source | Handler | Writes to stream via |
|---|---|---|
| Push notification tap | `FCMManager.handlePushNotification(userInfo:)` | `DeeplinkStreamImpl.shared.set(deeplink:)` |
| URL scheme (`talenta://`) | `DeeplinkManager.handle(url:)` | `dispatch(url:)` → stream |
| Universal link (`https://`) | `DeeplinkManager.handle(userActivity:)` | `dispatch(url:)` → stream |
| Home screen quick action | `DeeplinkManager.handle(shortcutItem:)` | `stream.set(deeplink:)` directly |

All entry points are wired in `AppDelegate` — no coordinator touches them directly.

**Step 1 — Register the path in `DeeplinkPath`:**

```swift
// Talenta/DIComponents/DataStream/DeeplinkStream.swift
enum DeeplinkPath: String {
    // ... existing cases
    case {feature} = "{feature-url-path}"  // ← raw value = URL path, confirm with backend
}
```

**Step 2 — Add a routing method to `DeeplinkComponent`:**

```swift
// Talenta/DIComponents/Deeplink/DeeplinkComponent.swift
extension DeeplinkComponent {
    func coordinate{Feature}() -> Observable<Void> {
        let component = {Feature}Component(parent: self)
        let coordinator = {Feature}Coordinator(
            navigationController: rootNavigationController,
            component: component
        )
        return coordinate(to: coordinator).map { _ in }
    }
}
```

**Step 3 — Subscribe in the consuming coordinator or ViewController:**

```swift
deeplinkStream?.deeplinkData
    .subscribe(onNext: { [weak self] data in
        guard let data = data else { return }
        switch data.link {
        case .{feature}:
            self?.coordinate{Feature}()
        default: break
        }
    })
    .disposed(by: disposeBag)
```

**Rules:**
- ✅ `DeeplinkPath` raw value is the URL path string — confirm with backend/web team
- ✅ After handling, call `deeplinkStream?.set(deeplink: nil)` to clear the stream
- ❌ Never parse URLs or push payloads directly in coordinators or ViewModels — `DeeplinkData` handles all parsing
- ❌ Never add a second deeplink dispatch path — all sources must write to `DeeplinkStreamImpl.shared`

**When to add:** Any feature reachable from a push notification tap, universal link, URL scheme, or home screen quick action.
