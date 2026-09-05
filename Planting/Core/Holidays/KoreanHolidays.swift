import Foundation

/// Not in PRODUCT_SPEC.md — added on request, toggled from Settings.
///
/// The 8 fixed-date holidays repeat exactly every year and are exact. The
/// lunar-calendar ones (Seollal, Buddha's Birthday, Chuseok) and their
/// substitute-holiday extensions do not follow a simple formula — each
/// year's solar dates are set by the lunar calendar and, since 2022, a
/// substitute-holiday rule when they land on a weekend. Those are listed
/// explicitly below for 2024–2026 only; a year outside that range will
/// still show the 8 fixed holidays but nothing lunar-based. Extending this
/// past 2026 means adding that year's actual published dates here — there's
/// no way to compute them from a formula.
enum KoreanHolidays {
    private struct FixedHoliday {
        let month: Int
        let day: Int
        let name: String
    }

    private static let fixedHolidays: [FixedHoliday] = [
        FixedHoliday(month: 1, day: 1, name: "신정"),
        FixedHoliday(month: 3, day: 1, name: "삼일절"),
        FixedHoliday(month: 5, day: 5, name: "어린이날"),
        FixedHoliday(month: 6, day: 6, name: "현충일"),
        FixedHoliday(month: 8, day: 15, name: "광복절"),
        FixedHoliday(month: 10, day: 3, name: "개천절"),
        FixedHoliday(month: 10, day: 9, name: "한글날"),
        FixedHoliday(month: 12, day: 25, name: "크리스마스"),
    ]

    /// year/month/day → name, for holidays that shift every year.
    private static let lunarBasedHolidays: [String: String] = [
        // 2024
        "2024-02-09": "설날 연휴", "2024-02-10": "설날", "2024-02-11": "설날 연휴",
        "2024-02-12": "대체공휴일",
        "2024-05-15": "부처님오신날",
        "2024-09-16": "추석 연휴", "2024-09-17": "추석", "2024-09-18": "추석 연휴",
        // 2025
        "2025-01-28": "설날 연휴", "2025-01-29": "설날", "2025-01-30": "설날 연휴",
        "2025-05-05": "부처님오신날·어린이날", "2025-05-06": "대체공휴일",
        "2025-10-05": "추석 연휴", "2025-10-06": "추석", "2025-10-07": "추석 연휴",
        "2025-10-08": "대체공휴일",
        // 2026
        "2026-02-16": "설날 연휴", "2026-02-17": "설날", "2026-02-18": "설날 연휴",
        "2026-05-24": "부처님오신날", "2026-05-25": "대체공휴일",
        "2026-09-24": "추석 연휴", "2026-09-25": "추석", "2026-09-26": "추석 연휴",
    ]

    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = MonthGridBuilder.calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// The holiday name for `date`, or nil if it isn't one.
    static func name(for date: Date, calendar: Calendar = MonthGridBuilder.calendar) -> String? {
        if let lunarName = lunarBasedHolidays[keyFormatter.string(from: date)] {
            return lunarName
        }
        let comps = calendar.dateComponents([.month, .day], from: date)
        return fixedHolidays.first { $0.month == comps.month && $0.day == comps.day }?.name
    }
}
