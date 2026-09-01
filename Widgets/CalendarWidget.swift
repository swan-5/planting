import WidgetKit
import SwiftUI

struct CalendarWidgetEntry: TimelineEntry {
    let date: Date
    let days: [MonthGridDay]
    let summaries: [Date: WidgetDataProvider.DaySummary]
}

struct CalendarWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: .now, days: [], summaries: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarWidgetEntry>) -> Void) {
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [makeEntry()], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> CalendarWidgetEntry {
        let (days, summaries) = WidgetDataProvider.monthSummary(for: .now)
        return CalendarWidgetEntry(date: .now, days: days, summaries: summaries)
    }
}

/// PRODUCT_SPEC.md §19 Widget C. Medium shows the current week as a compact
/// strip; Large shows the full month grid with a schedule dot and a
/// todo-completion dot per day (no numbers/labels — meant as a glance
/// hint, not a replacement for opening the app). Same system-font note as
/// the other widgets.
struct CalendarWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalendarWidgetEntry
    private let calendar = MonthGridBuilder.calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(monthTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PlantingColor.secondaryText)

            if family == .systemLarge {
                monthGrid
            } else {
                weekStrip
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var currentWeek: [MonthGridDay] {
        let today = calendar.startOfDay(for: .now)
        guard let index = entry.days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) else {
            return Array(entry.days.prefix(7))
        }
        let weekStart = (index / 7) * 7
        return Array(entry.days[weekStart..<min(weekStart + 7, entry.days.count)])
    }

    private var weekStrip: some View {
        HStack(spacing: 4) {
            ForEach(currentWeek) { day in
                dayCell(day, size: 22)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(entry.days) { day in
                dayCell(day, size: 16)
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: .now)
    }

    @ViewBuilder
    private func dayCell(_ day: MonthGridDay, size: CGFloat) -> some View {
        let isToday = calendar.isDateInToday(day.date)
        let summary = entry.summaries[calendar.startOfDay(for: day.date)]

        VStack(spacing: 2) {
            Text(dayNumber(day.date))
                .font(.system(size: size * 0.55))
                .foregroundStyle(isToday ? .white : (day.isInCurrentMonth ? PlantingColor.primaryText : PlantingColor.secondaryText))
                .frame(width: size, height: size)
                .background(isToday ? PlantingColor.primaryBlue : Color.clear)
                .clipShape(Circle())

            HStack(spacing: 2) {
                if summary?.hasSchedule == true {
                    Circle().fill(PlantingColor.primaryBlue).frame(width: 3, height: 3)
                }
                if let summary, summary.todoTotal > 0 {
                    Circle()
                        .fill(summary.todoCompleted == summary.todoTotal ? PlantingColor.primaryBlue : PlantingColor.secondaryText)
                        .frame(width: 3, height: 3)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .opacity(day.isInCurrentMonth ? 1 : 0.3)
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct CalendarWidget: Widget {
    let kind = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarWidgetProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
                .containerBackground(PlantingColor.background, for: .widget)
        }
        .configurationDisplayName("Calendar")
        .description("Compact calendar with schedule and completion hints.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
