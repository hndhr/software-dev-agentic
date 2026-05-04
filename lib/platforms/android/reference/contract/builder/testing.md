# Android — Testing Patterns

## Unit Test Setup <!-- 70 -->

Test naming convention: `test_given[Condition]_when[Action]_then[ExpectedResult]`

```kotlin
@RunWith(MockitoJUnitRunner::class)
class GetTimeOffRequestsUseCaseTest {

    @get:Rule
    val fake = JUnitForger()

    private lateinit var useCase: GetTimeOffRequestsUseCase

    @Mock lateinit var mockRepository: TimeOffRepository
    @Mock lateinit var mockResult: Single<List<TimeOffRequest>>
    @Mock lateinit var mockSchedulerTransformers: SchedulerTransformers
    @Mock lateinit var mockLogger: Logger

    @Before
    fun setUp() {
        fake.reset(1)
    }

    @After
    fun tearDown() {
        reset(mockRepository, mockResult, mockSchedulerTransformers, mockLogger)
    }
}
```

## Use Case Tests <!-- 70 -->

```kotlin
@Test
fun test_givenValidParams_whenExecute_thenRepositoryShouldGetRequests() {
    // given
    useCase = GetTimeOffRequestsUseCase(mockRepository, mockSchedulerTransformers, mockLogger)
    val params = with(fake) {
        GetTimeOffRequestsUseCase.Params(id = aString())
    }
    given(mockRepository.getTimeOffRequests(params.id)).willReturn(mockResult)

    // when
    useCase.execute(params)

    // then
    then(mockRepository).should().getTimeOffRequests(params.id)
    then(mockRepository).shouldHaveNoMoreInteractions()
}

@Test
fun test_givenNullSchedulerAndLogger_whenExecute_thenWorksWithoutThem() {
    // given
    useCase = GetTimeOffRequestsUseCase(mockRepository)
    val params = with(fake) { GetTimeOffRequestsUseCase.Params(id = aString()) }
    given(mockRepository.getTimeOffRequests(params.id)).willReturn(mockResult)

    // when
    useCase.execute(params)

    // then
    then(mockRepository).should().getTimeOffRequests(params.id)
}
```

## Mapper Tests <!-- 70 -->

```kotlin
@RunWith(MockitoJUnitRunner::class)
class TimeOffRequestMapperTest {

    private lateinit var mapper: TimeOffRequestMapper

    @Before
    fun setUp() { mapper = TimeOffRequestMapper() }

    @Test
    fun test_givenValidResponse_whenMap_thenEntityIsCorrect() {
        val response = TimeOffRequestResponse(
            id = "123", employeeId = "emp-1", startDate = "2024-01-01",
            endDate = "2024-01-05", reason = "Vacation", status = "pending", totalDays = 5
        )
        val result = mapper.map(response)
        assertEquals("123", result.id)
        assertEquals(5, result.totalDays)
    }

    @Test
    fun test_givenNullFields_whenMap_thenDefaultsApplied() {
        val result = mapper.map(TimeOffRequestResponse(null, null, null, null, null, null, null))
        assertEquals("", result.id)
        assertEquals(0, result.totalDays)
    }

    @Test
    fun test_givenListResponse_whenMapList_thenAllEntitiesMapped() {
        val responses = listOf(
            TimeOffRequestResponse("1", null, null, null, null, null, 3),
            TimeOffRequestResponse("2", null, null, null, null, null, 5)
        )
        val results = responses.map { mapper.map(it) }
        assertEquals(2, results.size)
        assertEquals("1", results[0].id)
    }
}
```

## Presenter Tests <!-- 70 -->

```kotlin
@RunWith(MockitoJUnitRunner::class)
class TimeOffRequestPresenterTest {

    @get:Rule
    val fake = JUnitForger()

    @Mock lateinit var mockView: TimeOffRequestContract.View
    @Mock lateinit var mockUseCase: GetTimeOffRequestsUseCase
    @Mock lateinit var mockSchedulerTransformers: SchedulerTransformers
    @Mock lateinit var mockErrorHandler: ErrorHandler

    private lateinit var presenter: TimeOffRequestPresenter

    @Before
    fun setUp() {
        fake.reset(1)
        presenter = TimeOffRequestPresenter(mockUseCase, mockSchedulerTransformers, mockErrorHandler)
        presenter.attachView(mockView)
    }

    @After
    fun tearDown() {
        reset(mockView, mockUseCase, mockSchedulerTransformers, mockErrorHandler)
    }

    @Test
    fun test_givenViewAttached_whenLoadData_thenShowLoadingThenData() {
        // given
        val featureId = fake.aString()
        val mockData = with(fake) { TimeOffRequest(aString(), aString(), aString(), aString(), aString(), aString(), aPositiveInt()) }
        given(mockUseCase.execute(any())).willReturn(Single.just(listOf(mockData)))

        // when
        presenter.loadTimeOffRequests(featureId)

        // then
        val inOrder = inOrder(mockView)
        inOrder.verify(mockView).showLoading()
        inOrder.verify(mockView).hideLoading()
        inOrder.verify(mockView).showTimeOffRequests(listOf(mockData))
        inOrder.verifyNoMoreInteractions()
    }

    @Test
    fun test_givenError_whenLoadData_thenShowError() {
        // given
        val error = RuntimeException("Network error")
        given(mockUseCase.execute(any())).willReturn(Single.error(error))

        // when
        presenter.loadTimeOffRequests(fake.aString())

        // then
        val inOrder = inOrder(mockView)
        inOrder.verify(mockView).showLoading()
        inOrder.verify(mockView).hideLoading()
        verify(mockErrorHandler).handle(eq(error), any())
    }

    @Test
    fun test_givenViewDetached_whenLoadData_thenNoViewInteraction() {
        // given
        presenter.detachView()

        // when
        presenter.loadTimeOffRequests(fake.aString())

        // then
        verifyNoMoreInteractions(mockView)
    }
}
```

Rules:
- Test naming: `test_given[Condition]_when[Action]_then[ExpectedResult]`
- Use `inOrder(mockView)` to verify call order (showLoading → hideLoading → showData)
- `presenter.attachView(mockView)` in `@Before`, `reset(...)` all mocks in `@After`
- `presenter.detachView()` (not `detach()`) — test that detached presenter ignores use case results
- Always test: success path, error path, detached-view path
