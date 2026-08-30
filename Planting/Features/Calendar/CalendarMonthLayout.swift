import Foundation

/// One cell in the 7-column month grid. `isInCurrentMonth` distinguishes
/// leading/trailing days borrowed from adjacent months (PRODUCT_SPEC.md §6.3).
struct MonthGridDay: Identifiable, Hashable {
    let date: Date
    let isInCurrentMonth: Bool
    var id: TimeInterval { date.timeIntervalSince1970 }
}

enum MonthGridBuilder {
    /// PRODUCT_SPEC.md §6.3 fixes the header as SUN...SAT regardless of
    /// device locale/region, so the grid always starts the week on Sunday.
    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }

    static func days(for monthAnchor: Date, calendar: Calendar = calendar) -> [MonthGridDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor),
              let daysInMonth = calendar.range(of: .day, in: .month, for: monthInterval.start)?.count
        else { return [] }

        let firstOfMonth = monthInterval.start
        let leadingCount = calendar.component(.weekday, from: firstOfMonth) - 1
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingCount, to: firstOfMonth) else { return [] }

        let totalCells = Int(ceil(Double(leadingCount + daysInMonth) / 7.0)) * 7
        return (0..<totalCells).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let isInCurrentMonth = calendar.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
            return MonthGridDay(date: date, isInCurrentMonth: isInCurrentMonth)
        }
    }
}
