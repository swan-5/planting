import WidgetKit
import SwiftUI

struct CalendarWidgetEntry: TimelineEntry {
    let date: Date
    let days: [MonthGridDay]
    let details: [Date: WidgetDataProvider.DayDetail]
}

struct CalendarWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: .now, days: [], details: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarWidgetEntry>) -> Void) {
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [makeEntry()], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> CalendarWidgetEntry {
        let (days, details) = WidgetDataProvider.monthDetail(for: .now)
        return CalendarWidgetEntry(date: .now, days: days, details: details)
    }
}

/// PRODUCT_SPEC.md §19 Widget C. Medium shows the current week as a compact
/// strip; Large shows a simplified version of the app's own month grid —
/// weekday header, date numbers, one schedule bar and one todo per day
/// (whichever is most relevant; a widget cell has nowhere near the room
/// the app's own date cell does) — filling the widget's full bounds rather
/// than sitting at a fixed size with empty space below (on request).
struct CalendarWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalendarWidgetEntry
    private let calendar = MonthGridBuilder.calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(monthTitle)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PlantingColor.primaryText)

            if family == .systemLarge {
                weekdayHeader
                monthGrid
            } else {
                weekStrip
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol.prefix(3).uppercased())
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(PlantingColor.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
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
                simpleDayCell(day, size: 22)
            }
        }
    }

    /// Fills every bit of space left under the weekday header — both the
    /// column width (already the case before) and, now, the row height —
    /// so the grid reaches the widget's actual bottom edge instead of
    /// leaving empty space there.
    private var monthGrid: some View {
        GeometryReader { geo in
            let rows = ceil(Double(entry.days.count) / 7)
            let rowHeight = geo.size.height / rows
            VStack(spacing: 0) {
                ForEach(0..<Int(rows), id: \.self) { rowIndex in
                    HStack(spacing: 1) {
                        ForEach(weekRow(rowIndex)) { day in
                            detailedDayCell(day)
                                .frame(width: geo.size.width / 7, height: rowHeight)
                        }
                    }
                }
            }
        }
    }

    private func weekRow(_ index: Int) -> [MonthGridDay] {
        let start = index * 7
        return Array(entry.days[start..<min(start + 7, entry.days.count)])
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: .now)
    }

    /// The medium week-strip cell — unchanged, dot-based glance only.
    @ViewBuilder
    private func simpleDayCell(_ day: MonthGridDay, size: CGFloat) -> some View {
        let isToday = calendar.isDateInToday(day.date)
        let detail = entry.details[calendar.startOfDay(for: day.date)]

        VStack(spacing: 2) {
            Text(dayNumber(day.date))
                .font(.system(size: size * 0.55))
                .foregroundStyle(isToday ? .white : (day.isInCurrentMonth ? PlantingColor.primaryText : PlantingColor.secondaryText))
                .frame(width: size, height: size)
                .background(isToday ? PlantingColor.primaryBlue : Color.clear)
                .clipShape(Circle())

            HStack(spacing: 2) {
                if detail?.scheduleTitle != nil {
                    Circle().fill(PlantingColor.primaryBlue).frame(width: 3, height: 3)
                }
                if let detail, detail.todoCount > 0 {
                    Circle()
                        .fill(detail.todoCompleted ? PlantingColor.primaryBlue : PlantingColor.secondaryText)
                        .frame(width: 3, height: 3)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .opacity(day.isInCurrentMonth ? 1 : 0.3)
    }

    /// The large month-grid cell — a scaled-down echo of the app's own
    /// DateCellView + ScheduleBarView (not reused directly: widgets can't
    /// use `.draggable`/`.contextMenu`/`.onTapGesture`, so this is a plain
    /// static redraw of just the visual layer).
    @ViewBuilder
    private func detailedDayCell(_ day: MonthGridDay) -> some View {
        let isToday = calendar.isDateInToday(day.date)
        let detail = entry.details[calendar.startOfDay(for: day.date)]
        let isHoliday = detail?.holidayName != nil

        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 1) {
                Text(dayNumber(day.date))
                    .font(.system(size: 9, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(numberColor(isToday: isToday, isHoliday: isHoliday, isInCurrentMonth: day.isInCurrentMonth))
                if detail?.isBirthday == true {
                    Text("🎂").font(.system(size: 7))
                }
            }

            if let holidayName = detail?.holidayName {
                Text(holidayName)
                    .font(.system(size: 6))
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }

            if let scheduleTitle = detail?.scheduleTitle {
                Text(scheduleTitle)
                    .font(.system(size: 7))
                    .foregroundStyle(scheduleTextColor(on: detail?.scheduleColor))
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(detail?.scheduleColor ?? PlantingColor.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }

            if let todoTitle = detail?.todoTitle {
                HStack(spacing: 1) {
                    Image(systemName: detail?.todoCompleted == true ? "checkmark.square" : "square")
                        .font(.system(size: 6))
                        .foregroundStyle(PlantingColor.secondaryText)
                    Text(todoTitle)
                        .font(.system(size: 7))
                        .foregroundStyle(PlantingColor.primaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .opacity(day.isInCurrentMonth ? 1 : 0.35)
    }

    private func numberColor(isToday: Bool, isHoliday: Bool, isInCurrentMonth: Bool) -> Color {
        if isHoliday { return .red }
        if isToday { return PlantingColor.primaryBlue }
        return isInCurrentMonth ? PlantingColor.primaryText : PlantingColor.secondaryText
    }

    private func scheduleTextColor(on background: Color?) -> Color {
        guard let background else { return .white }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(background).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.75 ? PlantingColor.primaryText : .white
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
        .description("A simplified month view with schedules and todos.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
