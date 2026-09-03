import SwiftUI
import SwiftData

/// Not in PRODUCT_SPEC.md — added on request. Reached by tapping the
/// month name in Calendar Home's header (`‹ September ⌄ ›`). All the
/// auto-aggregated sections are recomputed from live data every time this
/// opens, for the visible month or any past/future one; only the
/// hand-written reflection text at the bottom is actually stored
/// (MonthlyReflection, one row per year+month).
struct MonthlyReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    let month: Date

    @State private var viewModel: MonthlyReflectionViewModel?
    @State private var saveTask: Task<Void, Never>?
    @State private var detailDate: Date?
    @State private var editingTodo: Todo?

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.calendar = MonthGridBuilder.calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: month)
    }

    var body: some View {
        ScrollView {
            if let viewModel, let data = viewModel.data {
                VStack(alignment: .leading, spacing: PlantingSpacing.xl) {
                    summarySection(data)
                    Divider().overlay(PlantingColor.divider)
                    growthSection(data)
                    if !data.categoryBreakdown.isEmpty {
                        Divider().overlay(PlantingColor.divider)
                        categorySection(data)
                    }
                    if let bestDay = data.bestDay {
                        Divider().overlay(PlantingColor.divider)
                        bestDaySection(bestDay)
                    }
                    if !data.incompleteTodos.isEmpty {
                        Divider().overlay(PlantingColor.divider)
                        incompleteSection(data)
                    }
                    Divider().overlay(PlantingColor.divider)
                    reflectionSection(viewModel)
                }
                .padding(PlantingSpacing.lg)
            }
        }
        .background(PlantingColor.background)
        .navigationTitle("\(monthName) Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel == nil else { return }
            let vm = MonthlyReflectionViewModel(
                monthDate: month,
                scheduleRepository: SwiftDataScheduleRepository(context: modelContext),
                todoRepository: SwiftDataTodoRepository(context: modelContext),
                memoRepository: SwiftDataMemoRepository(context: modelContext),
                reflectionRepository: SwiftDataMonthlyReflectionRepository(context: modelContext)
            )
            vm.load()
            viewModel = vm
        }
        .onDisappear { viewModel?.saveReflection() }
        .navigationDestination(item: $detailDate) { date in
            DateDetailView(date: date)
        }
        .sheet(item: $editingTodo, onDismiss: { viewModel?.load() }) { todo in
            TodoEditView(existingTodo: todo)
        }
    }

    // MARK: Summary

    private func summarySection(_ data: MonthlyReflectionData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Summary")
            Text("\(data.completedTodos) Todos Completed")
                .font(PlantingFont.emphasis(16))
                .foregroundStyle(PlantingColor.primaryText)
            Text("\(Int((data.completionRate * 100).rounded()))% Completion")
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.secondaryText)
            Text("\(data.scheduleCount) Schedules")
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.secondaryText)
            Text("\(data.memoCount) Memos")
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.secondaryText)
        }
    }

    // MARK: Growth

    private func growthSection(_ data: MonthlyReflectionData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                sectionHeader("\(monthName) Growth")
                Text("☘️").font(.system(size: 14))
            }
            Text("\(data.fullyCompletedWeeks) of \(data.totalWeeksInMonth) weeks completed")
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.primaryText)

            if let bestWeek = data.bestWeek {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best Week")
                        .font(PlantingFont.emphasis(13))
                        .foregroundStyle(PlantingColor.secondaryText)
                        .padding(.top, PlantingSpacing.xs)
                    Text(weekRangeString(bestWeek))
                        .font(PlantingFont.body())
                        .foregroundStyle(PlantingColor.primaryText)
                    Text("\(bestWeek.completed) / \(bestWeek.total) todos completed")
                        .font(PlantingFont.caption)
                        .foregroundStyle(PlantingColor.secondaryText)
                }
            }
        }
    }

    // MARK: Category

    private func categorySection(_ data: MonthlyReflectionData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("By Category")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.categoryBreakdown) { summary in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(summary.category?.color ?? PlantingColor.secondaryText)
                            .frame(width: 7, height: 7)
                        Text(summary.name)
                            .font(PlantingFont.body())
                            .foregroundStyle(PlantingColor.primaryText)
                        Spacer(minLength: 0)
                        Text("\(summary.count)")
                            .font(PlantingFont.emphasis(14))
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: Best day

    private func bestDaySection(_ bestDay: MonthlyReflectionData.DaySummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Best Day")
            Text(dayString(bestDay.date))
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.primaryText)
            Text("\(bestDay.completed) / \(bestDay.total) completed")
                .font(PlantingFont.caption)
                .foregroundStyle(PlantingColor.secondaryText)
            Button("View Day") { detailDate = bestDay.date }
                .font(PlantingFont.emphasis(13))
                .foregroundStyle(PlantingColor.primaryBlue)
                .padding(.top, 2)
        }
    }

    // MARK: Incomplete todos

    private func incompleteSection(_ data: MonthlyReflectionData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Still Growing")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.incompleteTodos) { item in
                    Button {
                        editingTodo = item.todo
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square")
                                .foregroundStyle(PlantingColor.secondaryText)
                            Text(item.todo.title)
                                .font(PlantingFont.body())
                                .foregroundStyle(PlantingColor.primaryText)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Written reflection

    private func reflectionSection(_ viewModel: MonthlyReflectionViewModel) -> some View {
        VStack(alignment: .leading, spacing: PlantingSpacing.lg) {
            sectionHeader("Reflection")

            reflectionQuestion(
                "What went well this month?",
                text: Binding(
                    get: { viewModel.wentWell },
                    set: { viewModel.wentWell = $0; scheduleSave(viewModel) }
                )
            )
            reflectionQuestion(
                "What could have been better?",
                text: Binding(
                    get: { viewModel.couldImprove },
                    set: { viewModel.couldImprove = $0; scheduleSave(viewModel) }
                )
            )
            reflectionQuestion(
                "What do I want to focus on next month?",
                text: Binding(
                    get: { viewModel.nextMonthFocus },
                    set: { viewModel.nextMonthFocus = $0; scheduleSave(viewModel) }
                )
            )
        }
    }

    private func reflectionQuestion(_ question: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(PlantingFont.emphasis(14))
                .foregroundStyle(PlantingColor.primaryText)
            TextEditor(text: text)
                .font(PlantingFont.body())
                .scrollContentBackground(.hidden)
                .frame(minHeight: 90)
                .padding(8)
                .background(PlantingColor.divider.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: PlantingRadius.textField))
        }
    }

    private func scheduleSave(_ viewModel: MonthlyReflectionViewModel) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            viewModel.saveReflection()
        }
    }

    // MARK: Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(PlantingFont.sectionHeading(15))
            .foregroundStyle(PlantingColor.primaryText)
    }

    private func weekRangeString(_ week: MonthlyReflectionData.WeekSummary) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: week.startDate)) – \(formatter.string(from: week.endDate))"
    }

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}
