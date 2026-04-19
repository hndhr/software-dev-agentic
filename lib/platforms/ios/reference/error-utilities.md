# iOS — Error Handling & Utilities

## Error Handling

### Error Flow

```
DataSource throws NetworkError
    ↓ caught by
Repository transforms to BaseErrorModel
    ↓ propagated via
UseCase (passes through or enriches)
    ↓ caught by
ViewModel maps to user message → Action
    ↓ rendered by
ViewController shows error UI
```

### BaseErrorModel

```swift
// Shared/Domain/Entities/BaseErrorModel.swift
struct BaseErrorModel: Error {
    let status: Int?
    let message: String
    let errors: [String: [String]]?

    init(
        status: Int? = nil,
        message: String = "An error occurred",
        errors: [String: [String]]? = nil
    ) {
        self.status = status
        self.message = message
        self.errors = errors
    }
}
```

### Result Type

```swift
Result<Model, BaseErrorModel>

// Success
expected(.success(model))

// Failure
expected(.failure(BaseErrorModel(message: "Network error")))
```

### Error Mapper

```swift
// Shared/Data/Mapper/BaseErrorModelMapper.swift
class BaseErrorModelMapper {
    func fromResponseToModel(from error: TalentaBaseError) -> BaseErrorModel {
        return BaseErrorModel(
            status: error.status,
            message: error.message.orEmpty(),
            errors: error.errors
        )
    }
}
```

**Error Handling Pattern:**
- All UseCase/Repository completions use `Result<Model, BaseErrorModel>`
- Map API errors to `BaseErrorModel` in repositories
- ViewModel handles result, emits actions (toast, alert)
- ViewController displays errors via actions

---

## Utilities

> For StorageService and DateService specs, see `.claude/reference/core-services.md`.

### Null Safety Extensions

**CRITICAL PATTERN:** Always use extension methods for optional unwrapping.

```swift
// Core/Extensions/Optional+NullSafety.swift

// Numeric Types
extension Optional where Wrapped: Numeric {
    func orZero() -> Wrapped {
        self ?? 0
    }

    func orDefault(_ defaultValue: Wrapped) -> Wrapped {
        self ?? defaultValue
    }
}

// String
extension Optional where Wrapped == String {
    func orEmpty() -> String {
        self ?? ""
    }

    func orDefault(_ defaultValue: String) -> String {
        guard let self = self, !self.trimmingCharacters(in: .whitespaces).isEmpty else {
            return defaultValue
        }
        return self
    }
}

// Collections
extension Optional where Wrapped: Collection {
    func orEmpty() -> Wrapped {
        self ?? [] as! Wrapped
    }

    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

// Bool
extension Optional where Wrapped == Bool {
    func orFalse() -> Bool {
        self ?? false
    }

    func orTrue() -> Bool {
        self ?? true
    }
}

// General Optional
extension Optional {
    func orDefault(_ factory: @autoclosure () -> Wrapped) -> Wrapped {
        self ?? factory()
    }

    @discardableResult
    func orElse(_ action: () -> Wrapped) -> Wrapped {
        self ?? action()
    }
}
```

**Usage Examples:**

```swift
// ViewModel building display state
let employeeName = employee.nickname.orEmpty()
let displayCount = employees?.count.orZero()

// Repository handling missing values
let limit = params.limit.orDefault(20)

// API response fallbacks
let bio = profile.bio.orDefault("No bio available")

// Feature flags
let isEnabled = featureFlags?.newUI.orFalse()

// IMPORTANT: Wrap optional chains in parentheses
let appBarTitle = ($0.dataState.data?.appBarTitle).orEmpty()
let isHidden = (state.dataState.data?.actionContainerIsHidden).orFalse()
```

### Logger

Centralized logging with severity levels.

```swift
// Core/Logger/Logger.swift
import OSLog

enum LogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var emoji: String {
        switch self {
        case .verbose: "💬"
        case .debug: "🐛"
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "❌"
        }
    }
}

protocol Logger {
    func log(_ message: String, level: LogLevel, file: String, function: String, line: Int)
}

extension Logger {
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}

final class ConsoleLogger: Logger {
    private let minLevel: LogLevel
    private let osLogger: OSLog.Logger

    init(minLevel: LogLevel = .debug) {
        self.minLevel = minLevel
        self.osLogger = OSLog.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "general")
    }

    func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        guard level >= minLevel else { return }

        let filename = (file as NSString).lastPathComponent
        let logMessage = "\(level.emoji) [\(filename):\(line)] \(function): \(message)"

        osLogger.log(level: level.osLogType, "\(logMessage)")
    }
}

// Global Logger
enum Log {
    nonisolated(unsafe) static var shared: Logger = ConsoleLogger()

    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.debug(message, file: file, function: function, line: line)
    }

    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.info(message, file: file, function: function, line: line)
    }

    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.warning(message, file: file, function: function, line: line)
    }

    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.error(message, file: file, function: function, line: line)
    }
}
```

### Helper Extensions Index

Extension files live in `Talenta/Shared/Extension/`. Use this index to find helpers without searching.

| Helper | File | Key Methods |
|--------|------|-------------|
| `String?` | `Extension+String?.swift` | `.orEmpty()`, `.ifNullOrEmptyReturnDash()` |
| `Int?` | `Extension+Int?.swift` | `.orZero()`, `.orOne()` |
| `Double?` | `Extension+Double?.swift` | `.orZero()` |
| `Bool?` | `Extension+Bool?.swift` | `.orFalse()`, `.orTrue()` |
| `Array?` | `Extension+Array?.swift` | `.orEmpty()` |
| `Date` | `Date+Extensions.swift` | `.toDMYString()`, `.toHHMMString()`, `.toYMDString()`, `.isToday`, `.isPast`, `.startOfDay` |
| `String` → Date | `Date+Extensions.swift` | `.toDate(format:)`, `.toTimeDate()` |
| `Double/Int` (currency) | `Extension+Double.swift` | `.toRupiahString()`, `.toFormattedString()` |
| `String` utilities | `Extension+String.swift` | `.removeWhitespace`, `.capitalizeFirstLetter`, `.isNumeric`, `.truncate(length:)`, `.masked` |
| `UIView` | `UIView+Extensions.swift` | `.addSubviews(...)`, `.roundCorners(...)`, `.addShadow(...)`, `.shake()` |
| `UIViewController` | `UIViewController+Extensions.swift` | `.showAlert(...)`, `.showErrorAlert(message:)`, `.showConfirmation(...)`, `.hideKeyboardWhenTappedAround()` |
| `BaseErrorModel` | `BaseErrorModel+Extensions.swift` | `.createEmptyDataError()`, `.createNetworkError()`, `.from(error:)` |
| `Observable` | `Observable+Extensions.swift` | `.unwrap()`, `.mapToVoid()`, `.retryWithDelay(...)` |

**Critical:** Wrap optional chains in parentheses before calling extension methods:
```swift
($0.dataState.data?.title).orEmpty()     // ✅
$0.dataState.data?.title.orEmpty()       // ❌ compile error
```
