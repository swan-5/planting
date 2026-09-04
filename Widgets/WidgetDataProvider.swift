import Foundation
import SwiftData

/// Read-only on purpose: unlike the app's TodoRepository.items(in:), this
/// never materializes missing TodoOccurrence rows for repeating todos, so
/// the widget process never writes to the shared store — avoiding any risk
/// of the widget and the app racing to save at the same time. A repeating
/// todo simply won't show here until the app itself has materialized
/// today's occurrence (e.g. by opening the calendar or Todo tab).
enum WidgetDataProvider {
    static func todayData(calendar: Calendar = .current) -> (schedules: [ScheduleOccurrence], todos: [TodoItem]) {
        let context = ModelContext(PersistenceController.sharedContainer)
        let today = calendar.startOfDay(for: .now)

        let scheduleRepository = SwiftDataScheduleRepository(context: context, calendar: calendar)
        let schedules = (try? scheduleRepository.occurrences(in: today...today)) ?? []

        let todos = (try? context.fetch(FetchDescriptor<Todo>())) ?? []
        var todoItems: [TodoItem] = []
        for todo in todos {
            for occurrence in todo.occurrences {
                if !occurrence.isSkipped && TodoVisibility.isVisible(todo: todo, occurrence: occurrence, on: today, calendar: calendar) {
                    todoItems.append(TodoItem(todo: todo, occurrence: occurrence))
                }
            }
        }
        todoItems.sort { lhs, rhs in
            if lhs.occurrence.order != rhs.occurrence.order {
                return lhs.occurrence.order < rhs.occurrence.order
            }
            return lhs.todo.createdAt < rhs.todo.createdAt
        }

        return (schedules, todoItems)
    }

    /// Per-day glance data for the Calendar widget: whether any schedule
    /// covers the day, and the todo completion count. Read-only, same
    /// materialization caveat as `todayData`.
    struct DaySummary {
        var hasSchedule = false
        var todoTotal = 0
        var todoCompleted = 0
    }

    static func monthSummary(
        for referenceDate: Date,
        calendar: Calendar = MonthGridBuilder.calendar
    ) -> (days: [MonthGridDay], summaries: [Date: DaySummary]) {
        let days = MonthGridBuilder.days(for: referenceDate, calendar: calendar)
        guard let first = days.first?.date, let last = days.last?.date else { return (days, [:]) }
        let range = first...last

        let context = ModelContext(PersistenceController.sharedContainer)
        let scheduleRepository = SwiftDataScheduleRepository(context: context, calendar: calendar)
        let scheduleOccurrences = (try? scheduleRepository.occurrences(in: range)) ?? []
        let todos = (try? context.fetch(FetchDescriptor<Todo>())) ?? []

        var summaries: [Date: DaySummary] = [:]
        for day in days {
            let dayStart = calendar.startOfDay(for: day.date)
            var summary = DaySummary()

            for occurrence in scheduleOccurrences {
                let occStart = calendar.startOfDay(for: occurrence.date)
                let occEnd = calendar.startOfDay(for: occurrence.endDate)
                if dayStart >= occStart, dayStart <= occEnd {
                    summary.hasSchedule = true
                    break
                }
            }

            for todo in todos {
                for occurrence in todo.occurrences {
                    if !occurrence.isSkipped && TodoVisibility.isVisible(todo: todo, occurrence: occurrence, on: dayStart, calendar: calendar) {
                        summary.todoTotal += 1
                        if occurrence.completed { summary.todoCompleted += 1 }
                    }
                }
            }

            summaries[dayStart] = summary
        }

        return (days, summaries)
    }
}
