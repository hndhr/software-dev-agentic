# Android — Error Handling

## ErrorHandler <!-- 70 -->

Central error handler injected into presenters. Never call `view?.showError(error.message)` directly.

```kotlin
// In presenter:
class FeaturePresenter @Inject constructor(
    private val useCase: GetFeatureUseCase,
    private val errorHandler: ErrorHandler
) : BasePresenter<FeatureContract.View>(), FeatureContract.Presenter {

    override fun loadData(id: String) {
        useCase.execute(GetFeatureUseCase.Params(id))
            .doOnSubscribe { view?.showLoading() }
            .doFinally { view?.hideLoading() }
            .subscribe(
                { view?.showData(it) },
                { error -> errorHandler.handle(error) { view?.showError(it) } }
            )
            .addToDisposables()
    }
}
```

## Error Response Models <!-- 70 -->

```kotlin
data class ErrorResponse(
    @SerializedName("error") val error: ErrorDetail?
)

data class ErrorDetail(
    @SerializedName("code") val code: String?,
    @SerializedName("message") val message: String?,
    @SerializedName("errors") val errors: List<FieldError>?
)

data class FieldError(
    @SerializedName("field") val field: String?,
    @SerializedName("message") val message: String?
)

class ApiException(
    val code: Int,
    val errorResponse: ErrorResponse?,
    override val message: String
) : Exception(message)
```

## Error Interceptor <!-- 70 -->

```kotlin
class ErrorInterceptor @Inject constructor(private val gson: Gson) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val response = chain.proceed(chain.request())
        if (!response.isSuccessful) {
            val errorBody = response.body?.string()
            val errorResponse = try { gson.fromJson(errorBody, ErrorResponse::class.java) } catch (e: Exception) { null }
            throw ApiException(
                code = response.code,
                errorResponse = errorResponse,
                message = errorResponse?.error?.message ?: "Unknown error"
            )
        }
        return response
    }
}
```

## Repository Error Mapping <!-- 70 -->

Map `ApiException` to domain exceptions in the repository impl:

```kotlin
override fun getFeatureItems(page: Int): Single<List<FeatureEntity>> {
    return api.getFeatureItems(page)
        .map { response -> response.data?.map { mapper.map(it) } ?: emptyList() }
        .onErrorResumeNext { throwable ->
            when (throwable) {
                is ApiException -> when (throwable.code) {
                    401 -> Single.error(UnauthorizedException())
                    403 -> Single.error(ForbiddenException())
                    404 -> Single.error(NotFoundException())
                    else -> Single.error(throwable)
                }
                is IOException -> Single.error(NetworkException())
                else -> Single.error(throwable)
            }
        }
}
```
