# Android — Error Handling

> Concepts and invariants: `reference/builder/data.md`. This file covers Android/Kotlin-specific error handling patterns.

## Error Flow <!-- 14 -->

```
DataSource (ApiException / IOException)
      ↓
RepositoryImpl  →  maps to DomainException
      ↓
UseCase         →  propagates via RxJava onError
      ↓
Presenter       →  ErrorHandler.handle() → view?.showError()
      ↓
View (Activity/Fragment)  →  shows Toast / inline error UI
```

## Error Types <!-- 11 -->

| Type | Layer | Description |
|---|---|---|
| `ApiException` | Data | HTTP error from Retrofit; carries status code |
| `IOException` | Data | Network failure (no connectivity, timeout) |
| `DomainException` | Domain | Sealed class; subtypes: `Unauthorized`, `NotFound`, `NetworkError`, `Unknown` |
| `BaseErrorModel` | Presentation | UI-facing error with user-readable message |

See `domain.md → Domain Errors` for `DomainException` definition.

## Error Mapping <!-- 24 -->

RepositoryImpl maps transport errors to `DomainException` via `onErrorResumeNext`:

```kotlin
.onErrorResumeNext { throwable ->
    when (throwable) {
        is ApiException -> when (throwable.code) {
            401 -> Single.error(DomainException.Unauthorized())
            404 -> Single.error(DomainException.NotFound())
            else -> Single.error(throwable)
        }
        is IOException -> Single.error(DomainException.NetworkError())
        else -> Single.error(throwable)
    }
}
```

Presenter delegates to `ErrorHandler` — never inspect the error directly in the Presenter:

```kotlin
errorHandler.handle(error) { message -> view?.showError(message) }
```

## Error UI <!-- 6 -->

> Android error UI patterns not yet catalogued. Add toast/snackbar/inline error conventions here when established.

Standard pattern: `showToast(error.message.orEmpty())` for transient errors; inline `showEmptyState()` + retry button for list screens.
