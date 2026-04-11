# Talenta iOS — Architecture V2: Core Services

## 9.1 StorageService

Abstract key-value storage for tokens, preferences, cached data.

```swift
// Core/Storage/StorageService.swift
protocol StorageService: Sendable {
    func get<T: Codable>(_ key: StorageKey) -> T?
    func set<T: Codable>(_ value: T, for key: StorageKey)
    func remove(_ key: StorageKey)
    func clearAll()
    func contains(_ key: StorageKey) -> Bool
}

enum StorageKey: String, Sendable {
    // Auth
    case accessToken
    case refreshToken
    case tokenExpiration

    // User
    case userId
    case userEmail
    case lastSyncDate

    // App State
    case onboardingCompleted
    case lastSelectedTab
}

// UserDefaults Implementation
final class UserDefaultsStorageService: StorageService {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func get<T: Codable>(_ key: StorageKey) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func set<T: Codable>(_ value: T, for key: StorageKey) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }

    func remove(_ key: StorageKey) {
        defaults.removeObject(forKey: key.rawValue)
    }

    func clearAll() {
        StorageKey.allCases.forEach { remove($0) }
    }

    func contains(_ key: StorageKey) -> Bool {
        defaults.object(forKey: key.rawValue) != nil
    }
}

// Keychain Implementation (for sensitive data)
final class KeychainStorageService: StorageService {
    // ... keychain implementation
}

// Composite (Keychain + UserDefaults)
final class SecureStorageService: StorageService {
    private let keychain = KeychainStorageService()
    private let userDefaults = UserDefaultsStorageService()

    private let sensitiveKeys: Set<StorageKey> = [
        .accessToken,
        .refreshToken
    ]

    private func service(for key: StorageKey) -> StorageService {
        sensitiveKeys.contains(key) ? keychain : userDefaults
    }

    func get<T: Codable>(_ key: StorageKey) -> T? { service(for: key).get(key) }
    func set<T: Codable>(_ value: T, for key: StorageKey) { service(for: key).set(value, for: key) }
    func remove(_ key: StorageKey) { service(for: key).remove(key) }
    func clearAll() { keychain.clearAll(); userDefaults.clearAll() }
    func contains(_ key: StorageKey) -> Bool { service(for: key).contains(key) }
}
```

**Usage:** Use `StorageHelper.getStringValue(key:)` for simple token reads in most cases. Use `StorageService` protocol when building new injectable components.

---

## 9.2 DateService

Centralized date handling with timezone/formatting.

```swift
// Core/Date/DateService.swift
protocol DateService {
    var now: Date { get }
    var currentTimeZone: TimeZone { get }

    func format(_ date: Date, style: DateFormatStyle) -> String
    func parse(_ string: String, format: DateFormatStyle) -> Date?
    func startOfDay(_ date: Date) -> Date
    func endOfDay(_ date: Date) -> Date
    func addDays(_ days: Int, to date: Date) -> Date
    func daysBetween(_ start: Date, _ end: Date) -> Int
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool
}

enum DateFormatStyle {
    case iso8601              // "2024-01-15T14:30:00Z"
    case apiDate              // "2024-01-15"
    case apiDateTime          // "2024-01-15 14:30:00"
    case displayDate          // "Jan 15, 2024"
    case displayDateTime      // "Jan 15, 2024 at 2:30 PM"
    case displayTime          // "2:30 PM"
    case relative             // "2 days ago"
    case custom(String)
}

final class DateServiceImpl: DateService {
    private let calendar: Calendar
    private let locale: Locale

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.locale = locale
    }

    var now: Date { Date() }
    var currentTimeZone: TimeZone { calendar.timeZone }

    func format(_ date: Date, style: DateFormatStyle) -> String {
        switch style {
        case .iso8601: return ISO8601DateFormatter().string(from: date)
        case .apiDate: return formatWith("yyyy-MM-dd", date)
        case .displayDate:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = locale
            return formatter.string(from: date)
        case .custom(let format): return formatWith(format, date)
        default: return formatWith("yyyy-MM-dd HH:mm:ss", date)
        }
    }
}

// Convenience Extensions
extension DateService {
    func toAPIDate(_ date: Date) -> String { format(date, style: .apiDate) }
    func fromAPIDate(_ string: String) -> Date? { parse(string, format: .apiDate) }
    func isToday(_ date: Date) -> Bool { isSameDay(date, now) }
    func isPast(_ date: Date) -> Bool { date < now }
    func isFuture(_ date: Date) -> Bool { date > now }
}
```

**Usage:** For simple date formatting in most code, use `Date+Extensions.swift` helpers (`.toDMYString()`, `.toHHMMString()`, etc.) — see `arch/error-utilities.md` section 9.5. Use `DateService` when building injectable components that need testable date logic.
