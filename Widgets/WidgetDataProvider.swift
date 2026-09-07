import Foundation
import SwiftData
import SwiftUI

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

        let uid = PersistenceController.currentUserID
        let todos = (try? context.fetch(FetchDescriptor<Todo>(predicate: #Predicate { $0.ownerID == uid }))) ?? []
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
        let uid = PersistenceController.currentUserID
        let todos = (try? context.fetch(FetchDescriptor<Todo>(predicate: #Predicate { $0.ownerID == uid }))) ?? []

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

    /// One day's worth of detail for the Calendar widget's full-month grid
    /// — not in the spec, added on request so the widget's month view
    /// reads like an actual (simplified) calendar instead of just dots.
    /// Only the single most relevant schedule/todo per day is kept, since
    /// a widget cell has nowhere near the room the app's own date cell has.
    struct DayDetail {
        var scheduleTitle: String?
        var scheduleColor: Color?
        var todoTitle: String?
        var todoCompleted = false
        var todoCount = 0
        var holidayName: String?
        var isBirthday = false
    }

    static func monthDetail(
        for referenceDate: Date,
        calendar: Calendar = MonthGridBuilder.calendar
    ) -> (days: [MonthGridDay], details: [Date: DayDetail]) {
        let days = MonthGridBuilder.days(for: referenceDate, calendar: calendar)
        guard let first = days.first?.date, let last = days.last?.date else { return (days, [:]) }
        let range = first...last

        let context = ModelContext(PersistenceController.sharedContainer)
        let scheduleRepository = SwiftDataScheduleRepository(context: context, calendar: calendar)
        let scheduleOccurrences = (try? scheduleRepository.occurrences(in: range)) ?? []
        let uid = PersistenceController.currentUserID
        let todos = (try? context.fetch(FetchDescriptor<Todo>(predicate: #Predicate { $0.ownerID == uid }))) ?? []
        let birthdayMonthDay = (try? SwiftDataUserProfileRepository(context: context).fetch()?.birthday)
            .flatMap { $0 }
            .map { calendar.dateComponents([.month, .day], from: $0) }

        var details: [Date: DayDetail] = [:]
        for day in days {
            let dayStart = calendar.startOfDay(for: day.date)
            var detail = DayDetail()

            if let occurrence = scheduleOccurrences.first(where: {
                dayStart >= calendar.startOfDay(for: $0.date) && dayStart <= calendar.startOfDay(for: $0.endDate)
            }) {
                detail.scheduleTitle = occurrence.schedule.title
                detail.scheduleColor = occurrence.schedule.category?.color ?? PlantingColor.primaryBlue
            }

            for todo in todos {
                for occurrence in todo.occurrences {
                    guard !occurrence.isSkipped,
                          TodoVisibility.isVisible(todo: todo, occurrence: occurrence, on: dayStart, calendar: calendar)
                    else { continue }
                    detail.todoCount += 1
                    if detail.todoTitle == nil {
                        detail.todoTitle = todo.title
                        detail.todoCompleted = occurrence.completed
                    }
                }
            }

            detail.holidayName = KoreanHolidays.name(for: dayStart, calendar: calendar)
            if let birthdayMonthDay {
                let comps = calendar.dateComponents([.month, .day], from: dayStart)
                detail.isBirthday = comps.month == birthdayMonthDay.month && comps.day == birthdayMonthDay.day
            }

            details[dayStart] = detail
        }

        return (days, details)
    }
}
