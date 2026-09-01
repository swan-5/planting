import WidgetKit
import SwiftUI

struct TodayEntry: TimelineEntry {
    let date: Date
    let schedules: [ScheduleOccurrence]
    let todos: [TodoItem]
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, schedules: [], todos: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [makeEntry()], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> TodayEntry {
        let data = WidgetDataProvider.todayData()
        return TodayEntry(date: .now, schedules: data.schedules, todos: data.todos)
    }
}

/// PRODUCT_SPEC.md §19 Widget A. Uses system fonts rather than Pretendard —
/// a widget extension is a separate bundle and would need its own copy of
/// the font files plus its own UIAppFonts registration to use them, which
/// this first pass skips (§20.2 explicitly anticipates this kind of
/// system-surface limitation). Colors still come from PlantingColor.
struct TodayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.dateFormatter.string(from: entry.date))
                .font(.caption.weight(.semibold))
                .foregroundStyle(PlantingColor.secondaryText)

            if family == .systemMedium {
                HStack(alignment: .top, spacing: 16) {
                    column(title: "SCHEDULE", rows: scheduleRows)
                    column(title: "TO DO", rows: todoRows)
                }
            } else {
                let combined = Array((scheduleRows + todoRows).prefix(4))
                if combined.isEmpty {
                    emptyLabel
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(combined.indices, id: \.self) { combined[$0] }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyLabel: some View {
        Text("No items today")
            .font(.caption)
            .foregroundStyle(PlantingColor.secondaryText)
    }

    private func column(title: String, rows: [AnyView]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(PlantingColor.secondaryText)
            if rows.isEmpty {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
            } else {
                ForEach(rows.prefix(4).indices, id: \.self) { rows[$0] }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var scheduleRows: [AnyView] {
        entry.schedules.map { occurrence in
            AnyView(
                HStack(spacing: 4) {
                    Circle()
                        .fill(occurrence.schedule.category?.color ?? PlantingColor.primaryBlue)
                        .frame(width: 5, height: 5)
                    Text(occurrence.schedule.title)
                        .font(.caption)
                        .foregroundStyle(PlantingColor.primaryText)
                        .lineLimit(1)
                }
            )
        }
    }

    private var todoRows: [AnyView] {
        entry.todos.map { item in
            AnyView(
                HStack(spacing: 4) {
                    Image(systemName: item.occurrence.completed ? "checkmark.square" : "square")
                        .font(.system(size: 10))
                        .foregroundStyle(item.occurrence.completed ? PlantingColor.primaryBlue : PlantingColor.secondaryText)
                    Text(item.todo.title)
                        .font(.caption)
                        .foregroundStyle(PlantingColor.primaryText)
                        .lineLimit(1)
                }
            )
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("Md EEEE")
        return formatter
    }()
}

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetEntryView(entry: entry)
                .containerBackground(PlantingColor.background, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's schedule and todos.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
