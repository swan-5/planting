import SwiftUI
import SwiftData

/// S01 (PRODUCT_SPEC.md §6). Renders the month grid with schedules, todos,
/// and completion-intensity backgrounds inside each date cell.
struct CalendarHomeView: View {
    private enum QuickAddKind {
        case schedule, todo, memo
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(CalendarNavigationTrigger.self) private var navigationTrigger
    @State private var viewModel: CalendarHomeViewModel?
    @State private var isPresentingQuickAdd = false
    @State private var isPresentingCreate = false
    @State private var pendingCreateKind: QuickAddKind?
    @State private var detailDate: Date?
    @State private var editingSchedule: ScheduleOccurrence?
    /// The month tapped via the header's "‹ September ⌄ ›" control — not
    /// necessarily `viewModel.visibleMonth` by the time the pushed screen
    /// reads it if the user then also flips months, so this is captured
    /// once at tap time and handed to MonthlyReflectionView directly.
    @State private var reflectionMonth: Date?
    /// Drives which edge the month slides in/out from (PRODUCT_SPEC.md §22
    /// "natural month slide"). >0 = next month (slides in from the right),
    /// <0 = previous month (from the left), 0 = jump-to-today (no direction).
    @State private var monthNavigationDirection = 0
    /// Toggled from Settings (not in the spec — added on request).
    @AppStorage("showHolidays") private var showHolidays = true

    private let baseCellHeight: CGFloat = 80
    private let barLaneHeight: CGFloat = 19

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel {
                    header(viewModel)
                    weekdayHeader(viewModel)
                    dateGrid(viewModel)
                        .id(viewModel.visibleMonth)
                        .transition(monthTransition)
                        .clipped()
                        .gesture(monthSwipeGesture(viewModel))

                    // Centered in whatever blank space is left below the
                    // grid (down to the tab bar), not pinned to the grid's
                    // bottom edge — on request.
                    Spacer(minLength: 0)
                    CloverGrowthView(fullyCompletedWeeks: viewModel.fullyCompletedWeeksThisMonth)
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .background(PlantingColor.background)
            .onAppear { viewModel?.loadMonthData() }
            .onChange(of: navigationTrigger.goToTodayCount) {
                if let viewModel { goToToday(viewModel) }
            }
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
                    todoRepository: SwiftDataTodoRepository(context: modelContext),
                    userProfileRepository: SwiftDataUserProfileRepository(context: modelContext)
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
            .navigationDestination(item: $reflectionMonth) { month in
                MonthlyReflectionView(month: month)
            }
            .sheet(item: $editingSchedule, onDismiss: { viewModel?.loadMonthData() }) { occurrence in
                ScheduleEditView(existingSchedule: occurrence.schedule, occurrenceDate: occurrence.date)
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

    /// Swipe left/right on the grid to change months (not in the spec,
    /// added on request). `minimumDistance` is kept fairly large so a quick
    /// horizontal flick doesn't fight the long-press-then-drag gesture
    /// `.draggable` already uses for rescheduling a todo/schedule.
    private func monthSwipeGesture(_ viewModel: CalendarHomeViewModel) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) > 60 else { return }
                if horizontal < 0 {
                    goToNextMonth(viewModel)
                } else {
                    goToPreviousMonth(viewModel)
                }
            }
    }

    /// "‹ September ⌄ ›" (not in the spec, added on request): the chevrons
    /// keep doing month-slide navigation exactly as before, and the month
    /// name itself is now a button that opens that month's Monthly
    /// Reflection — always the month currently on screen, so flipping to
    /// August first and then tapping "August ⌄" opens August's reflection.
    private func header(_ viewModel: CalendarHomeViewModel) -> some View {
        HStack(spacing: PlantingSpacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                Text(yearOnly(viewModel.visibleMonth))
                    .font(PlantingFont.caption)
                    .foregroundStyle(PlantingColor.secondaryText)

                Button {
                    reflectionMonth = viewModel.visibleMonth
                } label: {
                    HStack(spacing: 3) {
                        Text(monthNameOnly(viewModel.visibleMonth))
                            .font(PlantingFont.monthTitle)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(PlantingColor.primaryText)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            HStack(spacing: 6) {
                Button { goToPreviousMonth(viewModel) } label: {
                    Image(systemName: "chevron.left")
                }
                Button { goToNextMonth(viewModel) } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .foregroundStyle(PlantingColor.primaryText)
        .padding(.horizontal, PlantingSpacing.lg)
        .padding(.vertical, PlantingSpacing.sm)
    }

    private func monthNameOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = MonthGridBuilder.calendar
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: date)
    }

    private func yearOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = MonthGridBuilder.calendar
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter.string(from: date)
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

    /// One grid row: date cells in a plain HStack, with every schedule
    /// drawn as an absolutely-positioned category-colored bar overlay on
    /// top (see ScheduleBarView / CalendarHomeViewModel.ScheduleBar) — a
    /// LazyVGrid can't make a single item span multiple columns, so this
    /// row needs its own GeometryReader to compute each bar's pixel
    /// offset/width.
    private func weekRow(_ viewModel: CalendarHomeViewModel, week: [MonthGridDay]) -> some View {
        let bars = viewModel.scheduleBars(forWeekStarting: week[0].date)
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
                            isBirthday: viewModel.isBirthday(day.date),
                            holidayName: showHolidays ? KoreanHolidays.name(for: day.date) : nil,
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
                    ScheduleBarView(
                        title: bar.occurrence.schedule.title,
                        color: bar.occurrence.schedule.category?.color ?? PlantingColor.primaryBlue,
                        sourceDate: bar.occurrence.date,
                        scheduleID: bar.occurrence.schedule.id,
                        onTap: { editingSchedule = bar.occurrence },
                        onCopy: { payload in viewModel.copyItem(payload) }
                    )
                    .frame(width: columnWidth * CGFloat(bar.columnSpan) - 3, height: 17)
                    .offset(
                        x: columnWidth * CGFloat(bar.startColumn) + 2,
                        y: 24 + CGFloat(bar.lane) * barLaneHeight
                    )
                }
            }
        }
        .frame(height: rowHeight)
    }
}

#Preview {
    CalendarHomeView()
        .environment(CalendarNavigationTrigger())
        .modelContainer(PersistenceController.sharedContainer)
}
