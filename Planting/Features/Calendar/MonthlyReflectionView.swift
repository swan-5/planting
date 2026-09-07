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
    @State private var editingTodo: TodoItem?

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
        .onDisappear {
            viewModel?.saveReflection()
            viewModel?.saveQuestions()
        }
        .sheet(item: $editingTodo, onDismiss: { viewModel?.load() }) { item in
            TodoEditView(existingTodo: item.todo, existingOccurrence: item.occurrence)
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

            heatmap(data)
                .padding(.top, PlantingSpacing.sm)
        }
    }

    /// GitHub-contribution-style grid, one square per day this month —
    /// not in the spec, added on request. Shaded by that day's todo
    /// completion rate rather than a raw count, since a typical day here
    /// only has a handful of todos.
    private func heatmap(_ data: MonthlyReflectionData) -> some View {
        let gridDays = MonthGridBuilder.days(for: data.monthDate)
        let completionByDay = Dictionary(
            uniqueKeysWithValues: data.dailyCompletion.map { ($0.date, $0) }
        )
        let weeks = stride(from: 0, to: gridDays.count, by: 7)
            .map { Array(gridDays[$0..<min($0 + 7, gridDays.count)]) }

        return VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 3) {
                    ForEach(week) { day in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatmapColor(for: day, completionByDay: completionByDay))
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
    }

    private func heatmapColor(
        for day: MonthGridDay,
        completionByDay: [Date: MonthlyReflectionData.DayCompletion]
    ) -> Color {
        guard day.isInCurrentMonth else { return .clear }
        guard let entry = completionByDay[MonthGridBuilder.calendar.startOfDay(for: day.date)],
              entry.total > 0
        else {
            return PlantingColor.divider.opacity(0.6)
        }
        let rate = Double(entry.completed) / Double(entry.total)
        switch rate {
        case 0: return PlantingColor.primaryBlue.opacity(0.15)
        case ..<0.5: return PlantingColor.primaryBlue.opacity(0.4)
        case ..<1.0: return PlantingColor.primaryBlue.opacity(0.7)
        default: return PlantingColor.primaryBlue
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

    // MARK: Incomplete todos

    private func incompleteSection(_ data: MonthlyReflectionData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Still Growing")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.incompleteTodos) { item in
                    Button {
                        editingTodo = item
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
                question: Binding(
                    get: { viewModel.wentWellQuestion },
                    set: { viewModel.wentWellQuestion = $0; scheduleSave(viewModel) }
                ),
                text: Binding(
                    get: { viewModel.wentWell },
                    set: { viewModel.wentWell = $0; scheduleSave(viewModel) }
                )
            )
            reflectionQuestion(
                question: Binding(
                    get: { viewModel.couldImproveQuestion },
                    set: { viewModel.couldImproveQuestion = $0; scheduleSave(viewModel) }
                ),
                text: Binding(
                    get: { viewModel.couldImprove },
                    set: { viewModel.couldImprove = $0; scheduleSave(viewModel) }
                )
            )
            reflectionQuestion(
                question: Binding(
                    get: { viewModel.nextMonthFocusQuestion },
                    set: { viewModel.nextMonthFocusQuestion = $0; scheduleSave(viewModel) }
                ),
                text: Binding(
                    get: { viewModel.nextMonthFocus },
                    set: { viewModel.nextMonthFocus = $0; scheduleSave(viewModel) }
                )
            )
        }
    }

    /// The question label is a plain TextField (rather than static Text) so
    /// it's editable in place — defaults to the built-in prompt, on request.
    private func reflectionQuestion(question: Binding<String>, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Question", text: question, axis: .vertical)
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
            viewModel.saveQuestions()
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
}
