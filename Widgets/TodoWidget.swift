import WidgetKit
import SwiftUI

struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

struct TodoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(date: .now, todos: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [makeEntry()], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> TodoWidgetEntry {
        let data = WidgetDataProvider.todayData()
        let active = data.todos.filter { !$0.occurrence.completed }
        return TodoWidgetEntry(date: .now, todos: active)
    }
}

/// PRODUCT_SPEC.md §19 Widget B — today's active (unfinished) todos only,
/// no schedules. Same system-font note as TodayWidget.
struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoWidgetEntry

    private var maxRows: Int { family == .systemSmall ? 3 : 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Todo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PlantingColor.secondaryText)

            if entry.todos.isEmpty {
                Text("All done today")
                    .font(.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
            } else {
                ForEach(entry.todos.prefix(maxRows)) { item in
                    HStack(spacing: 5) {
                        Image(systemName: "square")
                            .font(.system(size: 10))
                            .foregroundStyle(PlantingColor.secondaryText)
                        Text(item.todo.title)
                            .font(.caption)
                            .foregroundStyle(PlantingColor.primaryText)
                            .lineLimit(1)
                    }
                }
                if entry.todos.count > maxRows {
                    Text("+\(entry.todos.count - maxRows) more")
                        .font(.system(size: 10))
                        .foregroundStyle(PlantingColor.secondaryText)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TodoWidget: Widget {
    let kind = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoWidgetProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(PlantingColor.background, for: .widget)
        }
        .configurationDisplayName("Todo")
        .description("Today's active todos.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
