import Foundation
import SwiftData

/// A single expanded instance of a (possibly repeating) Schedule, spanning
/// `date...endDate` (both the same day for a single-day schedule). Schedules
/// have no completion state, so — unlike Todo — these are computed on
/// demand from RecurrenceEngine rather than persisted.
struct ScheduleOccurrence: Identifiable {
    let schedule: Schedule
    let date: Date
    let endDate: Date
    var isMultiDay: Bool { endDate > date }
    var id: String { "\(schedule.id)-\(date.timeIntervalSince1970)" }
}

protocol ScheduleRepository {
    func fetchAll() throws -> [Schedule]
    func create(_ schedule: Schedule) throws
    func update(_ schedule: Schedule) throws
    func delete(_ schedule: Schedule) throws
    func occurrences(in range: ClosedRange<Date>) throws -> [ScheduleOccurrence]
    /// Drag-to-reschedule. Repeating schedules have no per-occurrence
    /// override model yet (see Schedule.swift), so moving one occurrence
    /// shifts the whole series by the same delta — a known limitation.
    func moveSchedule(id: UUID, sourceDate: Date, to newDate: Date) throws
    /// Paste. Always creates a plain, non-repeating copy.
    func duplicateSchedule(id: UUID, to newDate: Date) throws
}

final class SwiftDataScheduleRepository: ScheduleRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func fetchAll() throws -> [Schedule] {
        try context.fetch(FetchDescriptor<Schedule>(sortBy: [SortDescriptor(\.startDate)]))
    }

    func create(_ schedule: Schedule) throws {
        context.insert(schedule)
        try context.save()
    }

    func update(_ schedule: Schedule) throws {
        schedule.updatedAt = .now
        try context.save()
    }

    func delete(_ schedule: Schedule) throws {
        context.delete(schedule)
        try context.save()
    }

    func occurrences(in range: ClosedRange<Date>) throws -> [ScheduleOccurrence] {
        try fetchAll().flatMap { schedule -> [ScheduleOccurrence] in
            let start = calendar.startOfDay(for: schedule.startDate)
            let spanDays = schedule.endDate.map {
                max(0, calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: $0)).day ?? 0)
            } ?? 0

            // Widen the query so an occurrence that *started* before `range`
            // but still spans into it (a multi-day event) isn't missed.
            let widenedStart = calendar.date(byAdding: .day, value: -spanDays, to: range.lowerBound) ?? range.lowerBound

            return RecurrenceEngine.occurrences(
                of: schedule.recurrenceRule,
                anchorDate: schedule.startDate,
                in: widenedStart...range.upperBound,
                calendar: calendar
            ).compactMap { occurrenceStart -> ScheduleOccurrence? in
                let occurrenceEnd = calendar.date(byAdding: .day, value: spanDays, to: occurrenceStart) ?? occurrenceStart
                guard occurrenceEnd >= range.lowerBound, occurrenceStart <= range.upperBound else { return nil }
                return ScheduleOccurrence(schedule: schedule, date: occurrenceStart, endDate: occurrenceEnd)
            }
        }
    }

    func moveSchedule(id: UUID, sourceDate: Date, to newDate: Date) throws {
        let descriptor = FetchDescriptor<Schedule>(predicate: #Predicate { $0.id == id })
        guard let schedule = try context.fetch(descriptor).first else { return }

        let deltaDays = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: sourceDate),
            to: calendar.startOfDay(for: newDate)
        ).day ?? 0
        guard deltaDays != 0 else { return }

        schedule.startDate = calendar.date(byAdding: .day, value: deltaDays, to: schedule.startDate) ?? schedule.startDate
        if let end = schedule.endDate {
            schedule.endDate = calendar.date(byAdding: .day, value: deltaDays, to: end) ?? end
        }
        schedule.updatedAt = .now
        try context.save()
    }

    func duplicateSchedule(id: UUID, to newDate: Date) throws {
        guard let source = try fetchAll().first(where: { $0.id == id }) else { return }

        let day = calendar.startOfDay(for: newDate)
        var newEndDate: Date?
        if let end = source.endDate {
            let spanDays = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: source.startDate),
                to: calendar.startOfDay(for: end)
            ).day ?? 0
            newEndDate = calendar.date(byAdding: .day, value: spanDays, to: day)
        }

        let copy = Schedule(
            title: source.title,
            startDate: day,
            endDate: newEndDate,
            startTime: source.startTime,
            endTime: source.endTime,
            allDay: source.allDay,
            category: source.category,
            location: source.location,
            memo: source.memo,
            recurrenceRule: .none
        )
        try create(copy)
    }
}
