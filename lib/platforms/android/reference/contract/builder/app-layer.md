# Android — App Layer

> Concepts and invariants: `reference/builder/app-layer.md`. This file covers Kotlin/Dagger 2 patterns for Android.

## Dependency Registration <!-- 57 -->

Android uses **Dagger 2** with `@Module` + `@Binds` + `@ContributesAndroidInjector` per feature.

**Step 1 — Create the feature DI module:**

```kotlin
// feature_{feature}/di/Feature{Feature}Module.kt

@Module
abstract class Feature{Feature}Module {

    @Binds
    abstract fun bind{Feature}Repository(
        impl: {Feature}RepositoryImpl
    ): {Feature}Repository

    @Binds
    abstract fun bind{Feature}RemoteDataSource(
        impl: {Feature}RemoteDataSourceImpl
    ): {Feature}RemoteDataSource

    @ContributesAndroidInjector(modules = [Feature{Feature}Module::class])
    abstract fun contribute{Feature}Activity(): {Feature}Activity
}
```

**Step 2 — Create the ActivityBindingModule entry:**

```kotlin
// app/di/{Feature}ActivityBindingModule.kt

@Module
abstract class {Feature}ActivityBindingModule {

    @ContributesAndroidInjector(modules = [Feature{Feature}Module::class])
    abstract fun contribute{Feature}Activity(): {Feature}Activity
}
```

**Step 3 — Add to MainComponent:**

```kotlin
// app/di/MainComponent.kt
@Singleton
@Component(
    modules = [
        // ... existing modules
        {Feature}ActivityBindingModule::class,  // ← add here
    ]
)
interface MainComponent : AndroidInjector<App>
```

**Rules:**
- ✅ One `@Module` per feature under `feature_{feature}/di/`
- ✅ `@Binds` for interface-to-implementation binding — never `@Provides` for simple bindings
- ✅ `@ContributesAndroidInjector` scopes injection to the Activity/Fragment
- ❌ Never inject `Context` directly — use `@ApplicationContext` or `@ActivityContext`

---

## Route Registration <!-- 42 -->

Android uses **interface-based navigation** — the navigation interface lives in `base/`, the implementation lives in `app/navigator/`, and it is bound in a `NavigationModule`.

**Step 1 — Declare the navigation interface in `base/`:**

```kotlin
// base/navigation/{Feature}Navigation.kt

interface {Feature}Navigation {
    fun navigateTo{Feature}(context: Context)
    fun navigateTo{Feature}Detail(context: Context, id: String)
}
```

**Step 2 — Implement in `app/navigator/`:**

```kotlin
// app/navigator/{Feature}NavigationImpl.kt

class {Feature}NavigationImpl @Inject constructor() : {Feature}Navigation {

    override fun navigateTo{Feature}(context: Context) {
        context.startActivity(Intent(context, {Feature}Activity::class.java))
    }

    override fun navigateTo{Feature}Detail(context: Context, id: String) {
        context.startActivity(
            Intent(context, {Feature}DetailActivity::class.java).apply {
                putExtra({Feature}DetailActivity.EXTRA_ID, id)
            }
        )
    }
}
```

**Step 3 — Bind in NavigationModule:**

```kotlin
// app/di/NavigationModule.kt
@Module
abstract class NavigationModule {
    // ... existing bindings
    @Binds abstract fun bind{Feature}Navigation(impl: {Feature}NavigationImpl): {Feature}Navigation  // ← add here
}
```

**Rules:**
- ✅ Navigation interface in `base/` — never import Activity classes into feature modules
- ✅ One interface per feature, injected into ViewModels that need to navigate
- ❌ No `startActivity` calls inside feature module ViewModels — delegate to the navigator

---

## Module Registration <!-- 25 -->

Android module registration has two parts: wiring Dagger (via `MainComponent`) and wiring Gradle (via `settings.gradle`).

**Step 1 — Add to `settings.gradle`:**

```groovy
// settings.gradle
include ':feature_{feature}'   // ← add here
```

**Step 2 — Add to root `build.gradle` or `app/build.gradle` dependencies:**

```groovy
// app/build.gradle
dependencies {
    // ... existing
    implementation project(':feature_{feature}')   // ← add here
}
```

**Step 3 — Dagger wiring is handled in Dependency Registration (Step 3 above) — `{Feature}ActivityBindingModule` added to `MainComponent`.**

**Rules:**
- ✅ Module name in `settings.gradle` must match the directory name exactly
- ✅ Both Gradle wiring and Dagger wiring are required — neither alone is sufficient
- ❌ Never add feature module code directly to the `app/` module — keep feature code in `feature_{feature}/`

---

## Analytics Constants <!-- 13 -->

Analytics event names and screen identifiers are declared as constants in the feature module — never as inline strings in ViewModel or Fragment code.

**Path pattern:** `feature_{feature}/src/main/java/co/talenta/{feature}/analytics/{Feature}AnalyticsConstants.kt`

**Rules:**
- ✅ `object` with `const val String` constants — no logic, no analytics SDK import
- ✅ snake_case string values matching the analytics platform convention
- ❌ Never inline event name strings in ViewModel or Fragment

**When to create:** Any feature that instruments user interactions or screen views. Optional — skip if the feature has no analytics events.

---

## Feature Flag Registration <!-- 12 -->

Discover the feature flag pattern in use for this project — Android projects vary. Common patterns:

- **Remote Config wrapper** — a constants object with flag key strings + a manager/repository that resolves them
- **`FeatureFlagManager`** — a shared singleton with one method per flag, returning `Boolean`

Grep for existing flag registrations before proposing a new one:
```
Grep "featureFlag\|FeatureFlag\|feature_flag" in app/src/ and base/
```

**When to add:** Any feature that requires remote gating or gradual rollout. Optional — skip for features that launch to 100% of users immediately.
