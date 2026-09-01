import SwiftUI
import SwiftData

/// S01 (PRODUCT_SPEC.md §6). Renders the month grid with schedules, todos,
/// and completion-intensity backgrounds inside each date cell.
struct CalendarHomeView: View {
    private enum QuickAddKind {
        case schedule, todo, memo
    }

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CalendarHomeViewModel?
    @State private var isPresentingQuickAdd = false
    @State private var isPresentingCreate = false
    @State private var pendingCreateKind: QuickAddKind?
    @State private var detailDate: Date?
    @State private var editingSchedule: Schedule?
    /// Drives which edge the month slides in/out from (PRODUCT_SPEC.md §22
    /// "natural month slide"). >0 = next month (slides in from the right),
    /// <0 = previous month (from the left), 0 = jump-to-today (no direction).
    @State private var monthNavigationDirection = 0

    private let baseCellHeight: CGFloat = 68
    private let barLaneHeight: CGFloat = 17

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel {
                    header(viewModel)
                    weekdayHeader(viewModel)
                    VStack(spacing: 0) {
                        dateGrid(viewModel)
                        CloverGrowthView(fullyCompletedWeeks: viewModel.fullyCompletedWeeksThisMonth)
                    }
                    .id(viewModel.visibleMonth)
                    .transition(monthTransition)
                    .clipped()
                }
                Spacer(minLength: 0)
            }
            .background(PlantingColor.background)
            .onAppear { viewModel?.loadMonthData() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(PlantingColor.primaryText)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingQuickAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(PlantingColor.primaryText)
                    }
                }
            }
            .task {
                guard viewModel == nil else { return }
                let vm = CalendarHomeViewModel(
                    scheduleRepository: SwiftDataScheduleRepository(context: modelContext),
                    todoRepository: SwiftDataTodoRepository(context: modelContext)
                )
                vm.loadMonthData()
                viewModel = vm
            }
            .sheet(
                isPresented: $isPresentingQuickAdd,
                onDismiss: { if pendingCreateKind != nil { isPresentingCreate = true } }
            ) {
                QuickAddSheet(
                    onSelectSchedule: { pendingCreateKind = .schedule; isPresentingQuickAdd = false },
                    onSelectTodo: { pendingCreateKind = .todo; isPresentingQuickAdd = false },
                    onSelectMemo: { pendingCreateKind = .memo; isPresentingQuickAdd = false }
                )
            }
            .sheet(
                isPresented: $isPresentingCreate,
                onDismiss: {
                    pendingCreateKind = nil
                    viewModel?.loadMonthData()
                }
            ) {
                switch pendingCreateKind {
                case .schedule: ScheduleEditView(initialDate: .now)
                case .todo: TodoEditView(initialDate: .now)
                case .memo: MemoEditView(initialDate: .now)
                case nil: EmptyView()
                }
            }
            .navigationDestination(item: $detailDate) { date in
                DateDetailView(date: date)
            }
            .sheet(item: $editingSchedule, onDismiss: { viewModel?.loadMonthData() }) { schedule in
                ScheduleEditView(existingSchedule: schedule)
            }
        }
    }

    private var monthTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: monthNavigationDirection < 0 ? .leading : .trailing),
            removal: .move(edge: monthNavigationDirection < 0 ? .trailing : .leading)
        )
    }

    private func goToPreviousMonth(_ viewModel: CalendarHomeViewModel) {
        monthNavigationDirection = -1
        withAnimation(.easeInOut(duration: 0.28)) { viewModel.goToPreviousMonth() }
    }

    private func goToNextMonth(_ viewModel: CalendarHomeViewModel) {
        monthNavigationDirection = 1
        withAnimation(.easeInOut(duration: 0.28)) { viewModel.goToNextMonth() }
    }

    private func goToToday(_ viewModel: CalendarHomeViewModel) {
        monthNavigationDirection = 0
        withAnimation(.easeInOut(duration: 0.28)) { viewModel.goToToday() }
    }

    private func header(_ viewModel: CalendarHomeViewModel) -> some View {
        HStack(spacing: PlantingSpacing.md) {
            HStack(spacing: 4) {
                Text(viewModel.monthTitle)
                    .font(PlantingFont.monthTitle)
                    .foregroundStyle(PlantingColor.primaryText)

                if viewModel.fullyCompletedWeeksThisMonth >= 4 {
                    Image("clover_stage4")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
            }

            Spacer()

            Button("Today") { goToToday(viewModel) }
                .font(PlantingFont.body(13))
                .foregroundStyle(PlantingColor.secondaryText)

            Button { goToPreviousMonth(viewModel) } label: {
                Image(systemName: "chevron.left")
            }
            Button { goToNextMonth(viewModel) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(PlantingColor.primaryText)
        .padding(.horizontal, PlantingSpacing.lg)
        .padding(.vertical, PlantingSpacing.sm)
    }

    private func weekdayHeader(_ viewModel: CalendarHomeViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(PlantingFont.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, PlantingSpacing.xs)
    }

    private func dateGrid(_ viewModel: CalendarHomeViewModel) -> some View {
        VStack(spacing: 0) {
            ForEach(weekChunks(viewModel.days), id: \.[0].id) { week in
                weekRow(viewModel, week: week)
            }
        }
    }

    private func weekChunks(_ days: [MonthGridDay]) -> [[MonthGridDay]] {
        stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    /// One grid row: date cells in a plain HStack, with multi-day schedule
    /// bars drawn as an absolutely-positioned overlay on top (see
    /// MultiDayBarView / CalendarHomeViewModel.MultiDayBar) — a LazyVGrid
    /// can't make a single item span multiple columns, so this row needs
    /// its own GeometryReader to compute each bar's pixel offset/width.
    private func weekRow(_ viewModel: CalendarHomeViewModel, week: [MonthGridDay]) -> some View {
        let bars = viewModel.multiDayBars(forWeekStarting: week[0].date)
        let laneCount = bars.map(\.lane).max().map { $0 + 1 } ?? 0
        let barsHeight = CGFloat(laneCount) * barLaneHeight
        let rowHeight = baseCellHeight + barsHeight

        // Per-column inset: only the days a bar actually crosses reserve
        // space for it, so a day with no bar over it doesn't get pushed
        // down just because a sibling in the same week has one.
        func topInset(forColumn column: Int) -> CGFloat {
            let maxLane = bars
                .filter { column >= $0.startColumn && column < $0.startColumn + $0.columnSpan }
                .map(\.lane)
                .max()
            guard let maxLane else { return 0 }
            return CGFloat(maxLane + 1) * barLaneHeight
        }

        return GeometryReader { geo in
            let columnWidth = geo.size.width / 7
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.element.id) { column, day in
                        DateCellView(
                            day: day,
                            isToday: viewModel.isToday(day.date),
                            content: viewModel.content(for: day.date),
                            hasClipboard: viewModel.copiedPayload != nil,
                            topInset: topInset(forColumn: column),
                            onOpen: { detailDate = day.date },
                            onMove: { payload in viewModel.moveItem(payload, to: day.date) },
                            onCopy: { payload in viewModel.copyItem(payload) },
                            onPaste: { viewModel.pasteItem(to: day.date) },
                            onToggleTodo: { item in viewModel.toggleTodoCompletion(item) },
                            onMoveTodoToTop: { item in viewModel.moveTodoToTop(item, on: day.date) }
                        )
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .frame(height: geo.size.height)

                ForEach(bars) { bar in
                    MultiDayBarView(
                        title: bar.occurrence.schedule.title,
                        color: bar.occurrence.schedule.category?.color ?? PlantingColor.primaryBlue,
                        onTap: { editingSchedule = bar.occurrence.schedule }
                    )
                    .frame(width: columnWidth * CGFloat(bar.columnSpan) - 3, height: 15)
                    .offset(
                        x: columnWidth * CGFloat(bar.startColumn) + 2,
                        y: 21 + CGFloat(bar.lane) * barLaneHeight
                    )
                }
            }
        }
        .frame(height: rowHeight)
    }
}

#Preview {
    CalendarHomeView()
        .modelContainer(PersistenceController.sharedContainer)
}
