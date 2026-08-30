import Foundation

/// Weekday shared by Schedule and Todo recurrence (PRODUCT_SPEC.md §11, §14).
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    var id: Int { rawValue }
}

enum RecurrenceFrequency: String, Codable {
    case none, daily, weekly, monthly, custom
}

enum RecurrenceEnd: Codable, Equatable {
    case never
    case onDate(Date)
    case afterCount(Int)
}

/// Recurrence configuration shared by Schedule and Todo (PRODUCT_SPEC.md §11, §14, §23).
///
/// `frequency` mainly drives which fields the create/edit UI shows; the actual
/// occurrence computation (see `RecurrenceEngine`) reads whichever fields are
/// populated regardless of `frequency`, so "every 2 weeks on Monday" is expressed
/// as `interval: 2, weekdays: [.monday]` whether the UI labels it Weekly or Custom.
///
/// Examples:
/// - "Mon / Wed / Fri" weekly           → weekdays: [.monday, .wednesday, .friday]
/// - "every 2 weeks on Monday"          → interval: 2, weekdays: [.monday]
/// - "every month on the 15th"          → frequency: .monthly, dayOfMonth: 15
/// - "last Friday of every month"       → frequency: .monthly, weekOfMonthOrdinal: -1, weekOfMonthWeekday: .friday
struct RecurrenceRule: Codable, Equatable {
    var frequency: RecurrenceFrequency = .none
    var interval: Int = 1
    var weekdays: Set<Weekday>? = nil
    var dayOfMonth: Int? = nil
    /// 1 = first, 2 = second, -1 = last, etc. Used with `weekOfMonthWeekday`.
    var weekOfMonthOrdinal: Int? = nil
    var weekOfMonthWeekday: Weekday? = nil
    var end: RecurrenceEnd = .never

    static let none = RecurrenceRule(frequency: .none)
}
