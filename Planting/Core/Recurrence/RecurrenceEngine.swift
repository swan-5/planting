import Foundation

/// Pure, stateless recurrence expansion shared by Schedule and Todo
/// (PRODUCT_SPEC.md §11, §12, §14). No third-party RRule dependency — the
/// supported pattern set is a deliberate subset of RFC5545 matching what the
/// spec actually asks for (§11, §14 custom-repeat examples).
///
/// Field precedence within a rule (regardless of the `frequency` label the
/// UI used): `weekdays` → weekly-by-weekday; else `dayOfMonth` → monthly by
/// fixed day; else `weekOfMonthOrdinal` + `weekOfMonthWeekday` → monthly by
/// nth/last weekday; else a plain day/week/month step from `frequency`.
enum RecurrenceEngine {
    private static let maxIterations = 10_000

    static func occurrences(
        of rule: RecurrenceRule,
        anchorDate: Date,
        in range: ClosedRange<Date>,
        calendar: Calendar = .current
    ) -> [Date] {
        let anchor = calendar.startOfDay(for: anchorDate)
        let rangeStart = calendar.startOfDay(for: range.lowerBound)
        let rangeEnd = calendar.startOfDay(for: range.upperBound)
        guard anchor <= rangeEnd else { return [] }

        let endDate: Date? = {
            if case .onDate(let d) = rule.end { return calendar.startOfDay(for: d) }
            return nil
        }()
        let maxCount: Int? = {
            if case .afterCount(let n) = rule.end { return n }
            return nil
        }()

        if rule.frequency == .none {
            guard anchor >= rangeStart, anchor <= rangeEnd else { return [] }
            if let endDate, anchor > endDate { return [] }
            return [anchor]
        }

        let interval = max(rule.interval, 1)
        var results: [Date] = []
        var emittedCount = 0
        var iterations = 0

        func withinLimits(_ date: Date) -> Bool {
            if let endDate, date > endDate { return false }
            if let maxCount, emittedCount >= maxCount { return false }
            return true
        }

        if let weekdays = rule.weekdays, !weekdays.isEmpty {
            let anchorWeekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)
            )!
            var weekStart = anchorWeekStart
            outer: while weekStart <= rangeEnd, iterations < maxIterations {
                for offset in 0..<7 {
                    iterations += 1
                    guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart),
                          day >= anchor,
                          let wd = Weekday(rawValue: calendar.component(.weekday, from: day)),
                          weekdays.contains(wd)
                    else { continue }
                    guard withinLimits(day) else { break outer }
                    if day >= rangeStart, day <= rangeEnd { results.append(day) }
                    emittedCount += 1
                }
                guard let next = calendar.date(byAdding: .weekOfYear, value: interval, to: weekStart) else { break }
                weekStart = next
            }
        } else if let dayOfMonth = rule.dayOfMonth {
            var monthAnchor = anchor
            while monthAnchor <= rangeEnd, iterations < maxIterations {
                iterations += 1
                var comps = calendar.dateComponents([.year, .month], from: monthAnchor)
                comps.day = dayOfMonth
                if let day = calendar.date(from: comps), day >= anchor {
                    guard withinLimits(day) else { break }
                    if day >= rangeStart, day <= rangeEnd { results.append(day) }
                    emittedCount += 1
                }
                guard let next = calendar.date(byAdding: .month, value: interval, to: monthAnchor) else { break }
                monthAnchor = next
            }
        } else if let ordinal = rule.weekOfMonthOrdinal, let weekday = rule.weekOfMonthWeekday {
            var monthAnchor = anchor
            while monthAnchor <= rangeEnd, iterations < maxIterations {
                iterations += 1
                if let day = nthWeekday(ordinal: ordinal, weekday: weekday, monthOf: monthAnchor, calendar: calendar),
                   day >= anchor {
                    guard withinLimits(day) else { break }
                    if day >= rangeStart, day <= rangeEnd { results.append(day) }
                    emittedCount += 1
                }
                guard let next = calendar.date(byAdding: .month, value: interval, to: monthAnchor) else { break }
                monthAnchor = next
            }
        } else {
            let stepUnit: Calendar.Component = rule.frequency == .monthly
                ? .month
                : (rule.frequency == .weekly ? .weekOfYear : .day)
            var current = anchor
            while current <= rangeEnd, iterations < maxIterations {
                iterations += 1
                guard withinLimits(current) else { break }
                if current >= rangeStart, current <= rangeEnd { results.append(current) }
                emittedCount += 1
                guard let next = calendar.date(byAdding: stepUnit, value: interval, to: current) else { break }
                current = next
            }
        }

        return results
    }

    /// `ordinal`: 1 = first, 2 = second, ... ; -1 = last, -2 = second-to-last, ...
    private static func nthWeekday(
        ordinal: Int,
        weekday: Weekday,
        monthOf referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: referenceDate)
        ), let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else { return nil }

        let matches: [Date] = dayRange.compactMap { day -> Date? in
            var comps = calendar.dateComponents([.year, .month], from: monthStart)
            comps.day = day
            guard let date = calendar.date(from: comps),
                  calendar.component(.weekday, from: date) == weekday.rawValue
            else { return nil }
            return date
        }
        guard !matches.isEmpty else { return nil }

        if ordinal > 0 {
            let index = ordinal - 1
            return matches.indices.contains(index) ? matches[index] : nil
        } else {
            let index = matches.count + ordinal
            return index >= 0 ? matches[index] : nil
        }
    }
}
