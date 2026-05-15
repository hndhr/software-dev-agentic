# Android — App Layer

> Concepts and invariants: `reference/builder/app-layer.md`. This file covers Kotlin/Dagger 2 patterns for Android.

## Dependency Registration <!-- 62 -->

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

## Route Registration <!-- 54 -->

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

## Module Registration <!-- 30 -->

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

## Analytics Constants <!-- 15 -->

Analytics event names and screen identifiers are declared as constants in the feature module — never as inline strings in ViewModel or Fragment code.

**Path pattern:** `feature_{feature}/src/main/java/co/talenta/{feature}/analytics/{Feature}AnalyticsConstants.kt`

**Rules:**
- ✅ `object` with `const val String` constants — no logic, no analytics SDK import
- ✅ snake_case string values matching the analytics platform convention
- ❌ Never inline event name strings in ViewModel or Fragment

**When to create:** Any feature that instruments user interactions or screen views. Optional — skip if the feature has no analytics events.

---

## Feature Flag Registration <!-- 45 -->

Android has three flag types — pick the right enum based on the flag's backend:

| Type | Enum | Backend |
|---|---|---|
| Local only | `LocalFeatureFlag` | No backend — compile-time default |
| Firebase Remote Config | `RemoteConfigFeatureFlag` | `firebaseRemoteConfigKey` string |
| MekariFlag (Flagsmith) | `FlagsmithFeatureFlag` | `featureId` string |

All three implement the `Feature` interface (`domain/featureflag/Feature.kt`). Checked via `FeatureFlagManager.isFeatureEnabled(featureFlag)`.

**Add to the appropriate enum (`domain/featureflag/Feature.kt` or `flagsmith/FlagsmithFeatureFlag.kt`):**

```kotlin
// RemoteConfigFeatureFlag example
ENABLE_{FEATURE}(
    description = "Short description of what this gates",
    deprecated = arrayOf(),
    link = arrayOf("https://jurnal.atlassian.net/browse/{TICKET}"),
    defaultFlag = false,
    firebaseRemoteConfigKey = RemoteConfigKey.ENABLE_{FEATURE},
),

// FlagsmithFeatureFlag example
ENABLE_{FEATURE}(
    description = "Short description of what this gates",
    deprecated = arrayOf(),
    link = arrayOf("https://jurnal.atlassian.net/browse/{TICKET}"),
    defaultFlag = false,
    featureId = "enable_{feature}",
),
```

**Rules:**
- ✅ Always provide `description` and `link` — required for traceability
- ✅ `firebaseRemoteConfigKey` must match a constant in `RemoteConfigKey` — confirm with backend
- ✅ `featureId` must exactly match the Flagsmith feature key — confirm with backend
- ✅ `defaultFlag = false` unless the feature should be on by default when the flag is unreachable
- ❌ Never use raw string literals for flag keys at call sites — always reference the enum

**When to add:** Any feature that requires remote gating or gradual rollout. Optional — skip for features that launch to 100% of users immediately.

---

## Push Notification Registration <!-- 25 -->

Android centralizes FCM handling in `TalentaNotificationManagerImpl` (`app/src/main/java/co/talenta/service/fcm/TalentaNotificationManagerImpl.kt`). The FCM service in `AndroidManifest.xml` delegates to this class — no per-feature setup is needed.

**Token lifecycle:**
- `PostFcmTokenUseCase` — sends token to server (called in `HomeFragment.sendFcmTokenToServerIfNeeded()` after login)
- `DeleteFcmTokenUseCase` — deletes token from server on logout (called in `LogoutPresenter`, `ForgotPinLogoutPresenter`, `SessionExpiredActivity`)
- Last pushed token is stored in `SessionPreference.setLastPushedFcmToken(token)`

**Incoming message handling:**
- `TalentaNotificationManagerImpl.onMessageReceived()` receives the `RemoteMessage`
- Payload is in `remoteMessage.data["talenta_android_notification"]` — a JSON string deserialized into `TalentaNotificationPayload`
- `NotificationNavigationType` enum drives routing: `DEEPLINK`, `SCREEN_NAME`, `SILENT_PUSH_NOTIFICATION`, `URI`
- Silent push notifications route through domain use cases — they do not trigger UI state directly
- Display concerns (channels, icons, sound) are isolated in `TalentaNotificationBuilderImpl` — separate from the message handler

**Notification click routing:** notification pending intent targets `RedirectionActivity` — see Deeplink Registration below.

**Rules:**
- ✅ Per-feature notification types add a `NotificationNavigationType` variant and a handler in `TalentaNotificationManagerImpl`
- ✅ New notification screen destinations register a deeplink path and rely on `RedirectionActivity` for routing
- ❌ Never handle FCM messages or display notifications inside feature modules

---

## Deeplink Registration <!-- 53 -->

Android deeplinks enter through `RedirectionActivity` (`app/src/main/java/co/talenta/modul/redirection/RedirectionActivity.kt`) — a `singleTask` exported activity declared in `AndroidManifest.xml`.

**Two entry point types:**

| Type | Scheme | Handler |
|---|---|---|
| Custom scheme | `talenta://` (or `talenta.staging://`) | `checkTalentaDeepLink(uri)` |
| App link (universal) | `https://` / `http://` | `checkWebAppLink(uri)` |

**URL parsing:**
- `UrlHelper` (`base/src/main/java/co/talenta/base/helper/UrlHelper.kt`) — singleton with `contains()` pattern matching
- Each feature registers its URL pattern as a function: e.g., `isTaskDetail()` checks for `"task/detail"`
- Query parameters extracted via `uri.getQueryParameter(key)` — common keys: `id`, `action`, `date`, `type`

**Step 1 — Add a URL pattern to `UrlHelper`:**

```kotlin
// base/src/main/java/co/talenta/base/helper/UrlHelper.kt
fun Uri.is{Feature}(): Boolean = toString().contains("{feature-url-segment}")
```

**Step 2 — Add routing in `RedirectionActivity.checkTalentaDeepLink()`:**

```kotlin
uri.is{Feature}() -> redirect{Feature}(uri)
```

**Step 3 — Implement the redirect method:**

```kotlin
private fun redirect{Feature}(uri: Uri) {
    val id = uri.getQueryParameter("id").orEmpty()
    {feature}Navigation.navigateTo{Feature}(this, id)
}
```

**Step 4 — Register Intent filter for App Links (if universally linked):**

```xml
<!-- app/src/main/AndroidManifest.xml — inside RedirectionActivity intent-filter -->
<data android:pathPrefix="@string/universal_link_{feature}_index" />
```

**Rules:**
- ✅ All deeplink entry points flow through `RedirectionActivity` — never add `VIEW` intent filters to feature Activities
- ✅ URL patterns live in `UrlHelper` — never hardcode URL strings inside `RedirectionActivity`
- ✅ Routing delegates to the feature's Navigation interface — `RedirectionActivity` never starts Activities directly
- ❌ Never parse deeplink URLs in ViewModels or Fragments

---

## Planner Search Patterns <!-- 12 -->

Consumed by `builder-app-planner`. `{Feature}` = PascalCase, `{feature}` = snake_case per Android convention.

| Scope key | Glob / Path | Grep hint |
|---|---|---|
| `di` | `*Feature{Feature}Module.kt`, `*{Feature}ActivityBindingModule.kt`, `*MainComponent.kt` under `app/di/` | `{Feature}ActivityBindingModule` in `app/di/MainComponent.kt` |
| `route` | `*{Feature}Navigation.kt` under `base/navigation/`, `*{Feature}NavigationImpl.kt` under `app/navigator/`, `*NavigationModule.kt` under `app/di/` | `{Feature}Navigation` in `app/di/NavigationModule.kt` |
| `module` | `settings.gradle`, `app/build.gradle`, `*MainComponent.kt` under `app/di/` | `feature_{feature}` in `settings.gradle` |
| `analytics` | `*{Feature}AnalyticsConstants.kt` under `feature_{feature}/src/main/java/` | — |
| `feature_flag` | `domain/featureflag/Feature.kt`, `*FlagsmithFeatureFlag.kt` | `ENABLE_{FEATURE}` enum entry |
| `hybrid_embedding` | Load only if finding involves a Flutter module entry point — `bricks-talenta/*/module/*`, `app/*/brickhelper/*` | Load `reference/hybrid-embedding.md` + `reference/builder/hybrid-embedding.md` |
