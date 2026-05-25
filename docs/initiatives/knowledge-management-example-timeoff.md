# Knowledge Article Example — TimeOff

> Cross-platform: native list (iOS/Android) → Flutter module detail

---

**Feature:** TimeOff
**Summary:** Allows employees to submit, view, and track time-off requests. List is rendered natively per platform; detail is a shared Flutter module embedded via FlutterEngine.

---

**References**
- PRD: `<Confluence link>`
- Figma: `<Figma link>`
- Jira: HR-421
- BE Contract: `<Confluence or Postman link>`

---

**API Contracts**
- `GET /v1/time-off?employeeId={id}&page={n}` → `TimeOffItem[]` — consumed by native list
- `GET /v1/time-off/{id}` → `TimeOffDetail` — consumed by Flutter module

---

**Data Model**

`TimeOffItem`
| Field | Type |
|---|---|
| id | String |
| employeeId | String |
| type | Enum: annual, sick, unpaid, special |
| startDate | Date |
| endDate | Date |
| totalDays | Int |
| status | Enum: pending, approved, rejected, cancelled |

`TimeOffDetail` (extends TimeOffItem)
| Field | Type |
|---|---|
| reason | String |
| approverName | String |
| approvedAt | Date? |
| attachments | File[] |
| history | ApprovalHistory[] |

---

**High Level Design** _(optional)_

```
  Network Layer        Data Layer                 Domain Layer              Presentation Layer
  ───────────────┬─────────────────────────┬──────────────────────────┬──────────────────────────────
                 │                         │                          │  [Android · Clean]
                 │  TimeOffListRemoteDS    │  TimeOffItem             │  TimeOffListFragment
  REST API ◄─────┤  (Android)             ◄─  GetTimeOffListUseCase  ◄─  TimeOffListViewModel
                 │  TimeOffListRepository  │  (Android)               │
                 │  (Android)              │                          │  ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄
                 │                         │                          │  [iOS · pre-Clean]
                 │                         │  TimeOffListService      ◄─  TimeOffListVC
                 │                         │  (iOS)                   │
                 │                         │                          │  ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄
                 │                         │                          │  TimeOffFlutterBridge
  ───────────────┴─────────────────────────┴──────────────────────────┴──────────────────────────────
                                           ↓  FlutterEngine  (route: /time-off/detail · timeOffId)
  ───────────────┬─────────────────────────┬──────────────────────────┬──────────────────────────────
                 │                         │                          │  [Flutter Module · Clean]
                 │  TimeOffDetailRemoteDS  │  TimeOffDetail           │  TimeOffDetailBloc
  REST API ◄─────┤  TimeOffDetail         ◄─  GetTimeOffDetail       ◄─  TimeOffDetailPage
                 │  Repository             │  UseCase                 │
  ───────────────┴─────────────────────────┴──────────────────────────┴──────────────────────────────
```

---

**Data Flow**
1. `TimeOffListVC` (iOS) / `TimeOffListFragment` (Android) calls `GET /v1/time-off?employeeId={id}` and renders `TimeOffItem` list
2. User taps an item — `TimeOffListVC` / `TimeOffListFragment` extracts `timeOffId`
3. `TimeOffFlutterBridge` boots FlutterEngine (or reuses cached instance), pushes route `/time-off/detail` with `timeOffId` as argument
4. `TimeOffDetailApp` initialises `TimeOffDetailBloc` with `timeOffId`
5. `TimeOffDetailBloc` dispatches `GetTimeOffDetailUseCase(timeOffId)`
6. `GetTimeOffDetailUseCase` calls `TimeOffDetailRepository.getDetail(id)`
7. `TimeOffDetailRepository` calls `TimeOffDetailRemoteDS` → `GET /v1/time-off/{id}`
8. Response mapped to `TimeOffDetail` domain entity → emitted as `Loaded` state
9. `TimeOffDetailPage` renders full detail

```
  [TimeOffListVC]          [TimeOffListFragment]
  iOS · pre-Clean          Android · Clean
          │                            │
          │ tap · timeOffId            │ tap · timeOffId
          └──────────────┬─────────────┘
                         ▼
                ┌──────────────────────┐
                │  TimeOffFlutterBridge│
                │  route + timeOffId   │
                └────────┬─────────────┘
                         ▼
                ┌──────────────────────┐
                │   TimeOffDetailBloc  │
                └────────┬─────────────┘
                         ▼
                ┌──────────────────────────┐
                │  GetTimeOffDetailUseCase │
                └────────┬─────────────────┘
                         ▼
                ┌──────────────────────────┐
                │  TimeOffDetailRepository │
                └────────┬─────────────────┘
                         ▼
                ┌──────────────────────────┐
                │  TimeOffDetailRemoteDS   │
                └────────┬─────────────────┘
                         ▼
                GET /v1/time-off/{id}
```

---

**Artifacts (per platform)**

| Layer | iOS Native | Android Native | Flutter Module |
|---|---|---|---|
| Screen | `TimeOffListVC` | `TimeOffListFragment` | `TimeOffDetailPage` |
| State holder | `TimeOffListService` | `TimeOffListViewModel` | `TimeOffDetailBloc` |
| Use case | — | `GetTimeOffListUseCase` | `GetTimeOffDetailUseCase` |
| Repository | — | `TimeOffListRepository` | `TimeOffDetailRepository` |
| Remote DS | — | `TimeOffListRemoteDS` | `TimeOffDetailRemoteDS` |
| Domain entity | — | `TimeOffItem` | `TimeOffDetail` |
| Bridge | `TimeOffFlutterBridge` | `TimeOffFlutterBridge` | — |

---

**Platform Variants**
- iOS: `[pre-Clean]` MVC — `TimeOffListVC` → `TimeOffListService` → API direct call
- Android: `[Clean]` `TimeOffListFragment` → `TimeOffListViewModel` → `GetTimeOffListUseCase` → Repository
- Flutter: `[Clean]` BLoC → UseCase → Repository (detail module only)

---

**Gotchas / Known Constraints**
- FlutterEngine warm-up must happen before the list is shown — cold start on item tap causes a visible delay
- `timeOffId` is passed as `String` via route args — Flutter module must not assume `Int` type
- iOS list does not cache responses; Android ViewModel does — list state diverges on back-navigation
