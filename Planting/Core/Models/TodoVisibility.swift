import Foundation

/// PRODUCT_SPEC.md §3.3, §9.2 — an occurrence occupies every day in its
/// natural window (non-repeating: startDate...dueDate; repeating: its own
/// occurrenceDate), regardless of completion state. Completing it only
/// flips the checkbox (□ → ✓) for the days it was already showing on — it
/// does not relocate the item to the day it happened to be checked off.
///
/// An earlier version collapsed the window to `completedAt`'s day on
/// completion, which caused a visible bug: completing an item from a date
/// other than today (e.g. from Date Detail on a past/future date) stamped
/// `completedAt` with the real current time, so the item appeared to "jump"
/// to today's cell instead of staying put. `completedAt` is kept purely as
/// a timestamp (used by the Todo Home "Completed" tab), not as a display key.
enum TodoVisibility {
    static func window(for todo: Todo, occurrence: TodoOccurrence, calendar: Calendar) -> ClosedRange<Date> {
        let isRepeating = todo.recurrenceRule.frequency != .none
        let start = calendar.startOfDay(for: isRepeating ? occurrence.occurrenceDate : todo.startDate)
        let rawEnd = isRepeating ? occurrence.occurrenceDate : (todo.dueDate ?? todo.startDate)
        let end = max(start, calendar.startOfDay(for: rawEnd))
        return start...end
    }

    static func isVisible(todo: Todo, occurrence: TodoOccurrence, on date: Date, calendar: Calendar) -> Bool {
        window(for: todo, occurrence: occurrence, calendar: calendar).contains(calendar.startOfDay(for: date))
    }
}
