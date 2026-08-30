import Foundation
import Observation

@Observable
final class TodoHomeViewModel {
    enum Segment: String, CaseIterable, Identifiable {
        case today = "Today", all = "All", completed = "Completed"
        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case dueDate = "Due Date", createdDate = "Created", category = "Category"
        var id: String { rawValue }
    }

    var segment: Segment = .today
    var sortOption: SortOption = .dueDate
    private(set) var items: [TodoItem] = []

    private let repository: TodoRepository
    private let calendar: Calendar
    /// "All"/"Completed" span a bounded horizon rather than unbounded time,
    /// so an infinitely-repeating todo doesn't materialize forever.
    private let horizonDays = 180

    init(repository: TodoRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func load() {
        let today = calendar.startOfDay(for: .now)
        do {
            switch segment {
            case .today:
                items = try repository.items(in: today...today)
                    .filter { TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: today, calendar: calendar) }
                    .filter { !$0.occurrence.completed }
            case .all:
                let horizon = calendar.date(byAdding: .day, value: horizonDays, to: today) ?? today
                items = try repository.items(in: today...horizon)
                    .filter { !$0.occurrence.completed }
            case .completed:
                let past = calendar.date(byAdding: .day, value: -horizonDays, to: today) ?? today
                items = try repository.items(in: past...today)
                    .filter { $0.occurrence.completed }
            }
            sort()
        } catch {
            print("Failed to load todos: \(error)")
        }
    }

    func sort() {
        switch sortOption {
        case .dueDate:
            items.sort { effectiveDueDate($0) < effectiveDueDate($1) }
        case .createdDate:
            items.sort { $0.todo.createdAt < $1.todo.createdAt }
        case .category:
            items.sort { ($0.todo.category?.name ?? "") < ($1.todo.category?.name ?? "") }
        }
    }

    func toggleCompletion(_ item: TodoItem) {
        do {
            try repository.setCompleted(item.occurrence, completed: !item.occurrence.completed, at: .now)
            load()
        } catch {
            print("Failed to update todo completion: \(error)")
        }
    }

    func dDayLabel(for item: TodoItem) -> String {
        let due = calendar.startOfDay(for: effectiveDueDate(item))
        let today = calendar.startOfDay(for: .now)
        let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
        if days == 0 { return "Due today" }
        if days > 0 { return "D-\(days)" }
        return "D+\(-days)"
    }

    private func effectiveDueDate(_ item: TodoItem) -> Date {
        item.todo.dueDate ?? item.occurrence.occurrenceDate
    }
}
