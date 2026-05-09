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

## Module Registration <!-- 15 -->

iOS does **not** use an explicit `ModuleManager`. Features are linked implicitly via the Needle component hierarchy. No module registration step is needed.

**Component child registration is implicit:** Adding a `{Feature}Component(parent: mainTabComponent)` at the call site is sufficient — Needle generates the bootstrap code automatically.

**Summary:**
| Step | Required? |
|---|---|
| Dependency Registration (Needle Component) | ✅ Required |
| Route Registration (Coordinator) | ✅ Required |
| Module Registration (ModuleManager) | ❌ Not applicable — Needle handles this implicitly |
