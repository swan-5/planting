import Foundation

/// Auto-aggregated stats for one month, computed fresh each time rather
/// than stored — so re-opening a past month's Reflection always reflects
/// the data as it stands today, while the hand-written reflection text
/// (see MonthlyReflection) is the only part that's actually persisted.
struct MonthlyReflectionData {
    /// One entry per in-month day — the raw material for the GitHub-style
    /// heatmap in the Summary section (not in the spec, added on request).
    struct DayCompletion: Identifiable {
        let date: Date
        let completed: Int
        let total: Int
        var id: Date { date }
    }

    let monthDate: Date
    let totalTodos: Int
    let completedTodos: Int
    let scheduleCount: Int
    let memoCount: Int
    let dailyCompletion: [DayCompletion]

    var completionRate: Double {
        totalTodos == 0 ? 0 : Double(completedTodos) / Double(totalTodos)
    }
}

enum MonthlyReflectionCalculator {
    static func compute(
        for monthDate: Date,
        scheduleRepository: ScheduleRepository,
        todoRepository: TodoRepository,
        memoRepository: MemoRepository,
        calendar: Calendar = MonthGridBuilder.calendar
    ) -> MonthlyReflectionData {
        let gridDays = MonthGridBuilder.days(for: monthDate, calendar: calendar)
        let monthDaysOnly = gridDays.filter(\.isInCurrentMonth)

        guard let monthStart = monthDaysOnly.first?.date, let monthEnd = monthDaysOnly.last?.date else {
            return MonthlyReflectionData(
                monthDate: monthDate, totalTodos: 0, completedTodos: 0, scheduleCount: 0,
                memoCount: 0, dailyCompletion: []
            )
        }
        let monthRange = calendar.startOfDay(for: monthStart)...calendar.startOfDay(for: monthEnd)

        let scheduleOccurrences = (try? scheduleRepository.occurrences(in: monthRange)) ?? []

        let candidateTodoItems = (try? todoRepository.items(in: monthRange)) ?? []
        let monthTodoItems = candidateTodoItems.filter {
            TodoVisibility.window(for: $0.todo, occurrence: $0.occurrence, calendar: calendar).overlaps(monthRange)
        }
        let completedCount = monthTodoItems.filter(\.occurrence.completed).count

        let memoCount = ((try? memoRepository.fetchAll()) ?? []).filter { memo in
            let day = calendar.startOfDay(for: memo.date)
            return day >= monthRange.lowerBound && day <= monthRange.upperBound
        }.count

        func todosVisible(on date: Date) -> [TodoItem] {
            let day = calendar.startOfDay(for: date)
            return monthTodoItems.filter { TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: day, calendar: calendar) }
        }

        let dailyCompletion = monthDaysOnly.map { day -> MonthlyReflectionData.DayCompletion in
            let items = todosVisible(on: day.date)
            return MonthlyReflectionData.DayCompletion(
                date: calendar.startOfDay(for: day.date),
                completed: items.filter(\.occurrence.completed).count,
                total: items.count
            )
        }

        return MonthlyReflectionData(
            monthDate: monthDate,
            totalTodos: monthTodoItems.count,
            completedTodos: completedCount,
            scheduleCount: scheduleOccurrences.count,
            memoCount: memoCount,
            dailyCompletion: dailyCompletion
        )
    }
}
