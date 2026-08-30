import Foundation
import SwiftData

struct TodoItem: Identifiable {
    let todo: Todo
    let occurrence: TodoOccurrence
    var id: UUID { occurrence.id }
}

protocol TodoRepository {
    func fetchAllTodos() throws -> [Todo]
    func create(_ todo: Todo) throws
    func update(_ todo: Todo) throws
    func delete(_ todo: Todo) throws
    func setCompleted(_ occurrence: TodoOccurrence, completed: Bool, at date: Date) throws
    /// Materializes any missing TodoOccurrence rows for repeating todos whose
    /// recurrence produces a date inside `range`, then returns every
    /// (Todo, TodoOccurrence) pair whose visibility window overlaps `range`.
    /// Callers narrow to a single day with TodoVisibility.isVisible.
    func items(in range: ClosedRange<Date>) throws -> [TodoItem]
    func completionSummary(on date: Date) throws -> DailyCompletionSummary
    /// Drag-to-reschedule. Non-repeating: shifts the parent Todo's
    /// startDate/dueDate by the gap between `sourceDate` and `newDate`,
    /// preserving the span length. Repeating: moves just this one
    /// occurrence, independent of the series (PRODUCT_SPEC.md §12).
    func moveOccurrence(id: UUID, sourceDate: Date, to newDate: Date) throws
    /// Paste. Always creates a plain, non-repeating copy — duplicating an
    /// entire recurring series isn't supported from a single-occurrence copy.
    func duplicateOccurrence(id: UUID, to newDate: Date) throws
    /// "Move to top" — sets this occurrence's manual order below `minOrder`
    /// (the current lowest order among the other items on the same date).
    func setOrder(occurrenceID: UUID, order: Int) throws
}

final class SwiftDataTodoRepository: TodoRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func fetchAllTodos() throws -> [Todo] {
        try context.fetch(FetchDescriptor<Todo>(sortBy: [SortDescriptor(\.createdAt)]))
    }

    func create(_ todo: Todo) throws {
        context.insert(todo)
        if todo.recurrenceRule.frequency == .none {
            let occurrence = TodoOccurrence(todo: todo, occurrenceDate: calendar.startOfDay(for: todo.startDate))
            context.insert(occurrence)
            todo.occurrences.append(occurrence)
        }
        try context.save()
    }

    func update(_ todo: Todo) throws {
        todo.updatedAt = .now
        try context.save()
    }

    func delete(_ todo: Todo) throws {
        context.delete(todo)
        try context.save()
    }

    func setCompleted(_ occurrence: TodoOccurrence, completed: Bool, at date: Date = .now) throws {
        occurrence.completed = completed
        occurrence.completedAt = completed ? date : nil
        try context.save()
    }

    func items(in range: ClosedRange<Date>) throws -> [TodoItem] {
        try materializeRecurringOccurrences(in: range)
        return try fetchAllTodos().flatMap { todo in
            todo.occurrences
                .filter { TodoVisibility.window(for: todo, occurrence: $0, calendar: calendar).overlaps(range) }
                .map { TodoItem(todo: todo, occurrence: $0) }
        }
    }

    func completionSummary(on date: Date) throws -> DailyCompletionSummary {
        let day = calendar.startOfDay(for: date)
        let visible = try items(in: day...day).filter {
            TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: day, calendar: calendar)
        }
        let completed = visible.filter { $0.occurrence.completed }.count
        return DailyCompletionSummary(completed: completed, total: visible.count)
    }

    func moveOccurrence(id: UUID, sourceDate: Date, to newDate: Date) throws {
        let descriptor = FetchDescriptor<TodoOccurrence>(predicate: #Predicate { $0.id == id })
        guard let occurrence = try context.fetch(descriptor).first, let todo = occurrence.todo else { return }

        let day = calendar.startOfDay(for: newDate)
        let deltaDays = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: sourceDate),
            to: day
        ).day ?? 0
        guard deltaDays != 0 else { return }

        if todo.recurrenceRule.frequency == .none {
            todo.startDate = calendar.date(byAdding: .day, value: deltaDays, to: todo.startDate) ?? todo.startDate
            if let due = todo.dueDate {
                todo.dueDate = calendar.date(byAdding: .day, value: deltaDays, to: due) ?? due
            }
        } else {
            occurrence.occurrenceDate = day
        }
        todo.updatedAt = .now
        try context.save()
    }

    func duplicateOccurrence(id: UUID, to newDate: Date) throws {
        let descriptor = FetchDescriptor<TodoOccurrence>(predicate: #Predicate { $0.id == id })
        guard let occurrence = try context.fetch(descriptor).first, let sourceTodo = occurrence.todo else { return }

        let day = calendar.startOfDay(for: newDate)
        var newDueDate: Date?
        if let due = sourceTodo.dueDate {
            let spanDays = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: sourceTodo.startDate),
                to: calendar.startOfDay(for: due)
            ).day ?? 0
            newDueDate = calendar.date(byAdding: .day, value: spanDays, to: day)
        }

        let copy = Todo(
            title: sourceTodo.title,
            startDate: day,
            dueDate: newDueDate,
            category: sourceTodo.category,
            memo: sourceTodo.memo,
            recurrenceRule: .none
        )
        try create(copy)
    }

    func setOrder(occurrenceID: UUID, order: Int) throws {
        let descriptor = FetchDescriptor<TodoOccurrence>(predicate: #Predicate { $0.id == occurrenceID })
        guard let occurrence = try context.fetch(descriptor).first else { return }
        occurrence.order = order
        try context.save()
    }

    private func materializeRecurringOccurrences(in range: ClosedRange<Date>) throws {
        let repeatingTodos = try fetchAllTodos().filter { $0.recurrenceRule.frequency != .none }
        guard !repeatingTodos.isEmpty else { return }

        for todo in repeatingTodos {
            let existingDates = Set(todo.occurrences.map { calendar.startOfDay(for: $0.occurrenceDate) })
            let dueDates = RecurrenceEngine.occurrences(
                of: todo.recurrenceRule,
                anchorDate: todo.startDate,
                in: range,
                calendar: calendar
            )
            for date in dueDates where !existingDates.contains(date) {
                let occurrence = TodoOccurrence(todo: todo, occurrenceDate: date)
                context.insert(occurrence)
                todo.occurrences.append(occurrence)
            }
        }
        try context.save()
    }
}
