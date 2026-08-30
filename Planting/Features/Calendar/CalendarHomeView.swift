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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel {
                    header(viewModel)
                    weekdayHeader(viewModel)
                    dateGrid(viewModel)
                    CloverGrowthView(fullyCompletedWeeks: viewModel.fullyCompletedWeeksThisMonth)
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
        }
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

            Button("Today") { viewModel.goToToday() }
                .font(PlantingFont.body(13))
                .foregroundStyle(PlantingColor.secondaryText)

            Button { viewModel.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
            }
            Button { viewModel.goToNextMonth() } label: {
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
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(viewModel.days) { day in
                DateCellView(
                    day: day,
                    isToday: viewModel.isToday(day.date),
                    content: viewModel.content(for: day.date),
                    hasClipboard: viewModel.copiedPayload != nil,
                    onOpen: { detailDate = day.date },
                    onMove: { payload in viewModel.moveItem(payload, to: day.date) },
                    onCopy: { payload in viewModel.copyItem(payload) },
                    onPaste: { viewModel.pasteItem(to: day.date) },
                    onToggleTodo: { item in viewModel.toggleTodoCompletion(item) },
                    onMoveTodoToTop: { item in viewModel.moveTodoToTop(item, on: day.date) }
                )
            }
        }
    }
}

#Preview {
    CalendarHomeView()
        .modelContainer(PersistenceController.sharedContainer)
}
