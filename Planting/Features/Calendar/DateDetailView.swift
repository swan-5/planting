import SwiftUI
import SwiftData

/// S02 (PRODUCT_SPEC.md §7). Full schedule/todo detail for one date, reached
/// by tapping a date cell or its "+N" overflow indicator.
struct DateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let date: Date

    @State private var schedules: [ScheduleOccurrence] = []
    @State private var todos: [TodoItem] = []
    @State private var editingSchedule: Schedule?
    @State private var editingTodo: Todo?
    @State private var isPresentingNewSchedule = false
    @State private var isPresentingNewTodo = false

    private var completion: DailyCompletionSummary {
        DailyCompletionSummary(completed: todos.filter(\.occurrence.completed).count, total: todos.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlantingSpacing.md) {
                header

                if !schedules.isEmpty {
                    sectionHeader("Schedule")
                    ForEach(schedules) { occurrence in
                        scheduleRow(occurrence)
                    }
                }

                if !todos.isEmpty {
                    sectionHeader("TO DO")
                    ForEach(todos) { item in
                        todoRow(item)
                    }
                }

                if schedules.isEmpty && todos.isEmpty {
                    Text("Nothing scheduled")
                        .font(PlantingFont.body())
                        .foregroundStyle(PlantingColor.secondaryText)
                        .padding(.top, PlantingSpacing.sm)
                }
            }
            .padding(PlantingSpacing.lg)
        }
        .background(PlantingColor.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add Schedule") { isPresentingNewSchedule = true }
                    Button("Add Todo") { isPresentingNewTodo = true }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { load() }
        .sheet(isPresented: $isPresentingNewSchedule, onDismiss: load) {
            ScheduleEditView(initialDate: date)
        }
        .sheet(isPresented: $isPresentingNewTodo, onDismiss: load) {
            TodoEditView(initialDate: date)
        }
        .sheet(item: $editingSchedule, onDismiss: load) { schedule in
            ScheduleEditView(existingSchedule: schedule)
        }
        .sheet(item: $editingTodo, onDismiss: load) { todo in
            TodoEditView(existingTodo: todo)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.headerFormatter.string(from: date))
                .font(PlantingFont.sectionHeading(18))
                .foregroundStyle(PlantingColor.primaryText)
            if completion.total > 0 {
                Text("\(completion.completed) / \(completion.total) completed")
                    .font(PlantingFont.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(PlantingFont.emphasis(12))
            .foregroundStyle(PlantingColor.secondaryText)
            .padding(.top, PlantingSpacing.sm)
    }

    private func scheduleRow(_ occurrence: ScheduleOccurrence) -> some View {
        Button {
            editingSchedule = occurrence.schedule
        } label: {
            HStack(alignment: .top, spacing: PlantingSpacing.sm) {
                Circle()
                    .fill(occurrence.schedule.category?.color ?? PlantingColor.secondaryText)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)
                VStack(alignment: .leading, spacing: 2) {
                    Text(occurrence.schedule.title)
                        .font(PlantingFont.body())
                        .foregroundStyle(PlantingColor.primaryText)
                    if !occurrence.schedule.allDay, let time = occurrence.schedule.startTime {
                        Text(Self.timeFormatter.string(from: time))
                            .font(PlantingFont.caption)
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
                    if let location = occurrence.schedule.location, !location.isEmpty {
                        Text(location)
                            .font(PlantingFont.caption)
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: PlantingSpacing.sm) {
            Button {
                toggle(item)
            } label: {
                Image(systemName: item.occurrence.completed ? "checkmark.square" : "square")
                    .foregroundStyle(item.occurrence.completed ? PlantingColor.primaryBlue : PlantingColor.secondaryText)
            }
            .buttonStyle(.plain)

            Text(item.todo.title)
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.primaryText)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { editingTodo = item.todo }
    }

    private func load() {
        let calendar = MonthGridBuilder.calendar
        let day = calendar.startOfDay(for: date)
        do {
            schedules = try SwiftDataScheduleRepository(context: modelContext).occurrences(in: day...day)
            todos = try SwiftDataTodoRepository(context: modelContext).items(in: day...day)
                .filter { TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: day, calendar: calendar) }
                .sorted {
                    $0.occurrence.order != $1.occurrence.order
                        ? $0.occurrence.order < $1.occurrence.order
                        : $0.todo.createdAt < $1.todo.createdAt
                }
        } catch {
            print("Failed to load date detail: \(error)")
        }
    }

    private func toggle(_ item: TodoItem) {
        do {
            try SwiftDataTodoRepository(context: modelContext).setCompleted(
                item.occurrence,
                completed: !item.occurrence.completed,
                at: .now
            )
            load()
        } catch {
            print("Failed to toggle todo: \(error)")
        }
    }

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, EEEE"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
