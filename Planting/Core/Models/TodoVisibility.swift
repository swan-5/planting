import Foundation

/// PRODUCT_SPEC.md §3.3, §9.2 — an unfinished occurrence occupies every day
/// in its natural window (non-repeating: startDate...dueDate; repeating:
/// its own occurrenceDate).
///
/// On request: once a non-repeating todo is completed, it collapses to a
/// single checkmark on its **due date** — disappearing from the earlier
/// days of its span — regardless of which day it was actually checked off
/// on. This is anchored to `dueDate` (a fixed field) rather than
/// `completedAt`: an earlier version collapsed to `completedAt`'s day,
/// which broke when completing from a date other than today stamped
/// `completedAt` with the real current time, making the item appear to
/// "jump" to today's cell. Anchoring to `dueDate` instead is deterministic
/// no matter when/where the checkbox is tapped. `completedAt` remains a
/// plain timestamp (used by the Todo Home "Completed" tab's date label).
enum TodoVisibility {
    static func window(for todo: Todo, occurrence: TodoOccurrence, calendar: Calendar) -> ClosedRange<Date> {
        let isRepeating = todo.recurrenceRule.frequency != .none

        if occurrence.completed, !isRepeating {
            let day = calendar.startOfDay(for: todo.dueDate ?? todo.startDate)
            return day...day
        }

        let start = calendar.startOfDay(for: isRepeating ? occurrence.occurrenceDate : todo.startDate)
        let rawEnd = isRepeating ? occurrence.occurrenceDate : (todo.dueDate ?? todo.startDate)
        let end = max(start, calendar.startOfDay(for: rawEnd))
        return start...end
    }

    static func isVisible(todo: Todo, occurrence: TodoOccurrence, on date: Date, calendar: Calendar) -> Bool {
        window(for: todo, occurrence: occurrence, calendar: calendar).contains(calendar.startOfDay(for: date))
    }
}
