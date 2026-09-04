import SwiftUI
import SwiftData

/// S04 (PRODUCT_SPEC.md §10).
struct TodoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodoHomeViewModel?
    @State private var isPresentingNewTodo = false
    @State private var editingTodo: TodoItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel {
                    Picker("Section", selection: segmentBinding(viewModel)) {
                        ForEach(TodoHomeViewModel.Segment.allCases) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, PlantingSpacing.lg)
                    .padding(.vertical, PlantingSpacing.sm)

                    if viewModel.displayedItems.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(viewModel.displayedItems) { item in
                                TodoRow(
                                    item: item,
                                    dDayLabel: viewModel.dDayLabel(for: item),
                                    onToggle: { viewModel.toggleCompletion(item) },
                                    onTap: { editingTodo = item }
                                )
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(PlantingColor.background)
            .onAppear { viewModel?.load() }
            .searchable(text: searchBinding, prompt: "Search todos")
            .navigationTitle("Todo")
            .toolbar {
                if let viewModel {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Sort", selection: sortBinding(viewModel)) {
                                ForEach(TodoHomeViewModel.SortOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewTodo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                guard viewModel == nil else { return }
                let vm = TodoHomeViewModel(repository: SwiftDataTodoRepository(context: modelContext))
                vm.load()
                viewModel = vm
            }
            .sheet(isPresented: $isPresentingNewTodo, onDismiss: { viewModel?.load() }) {
                TodoEditView()
            }
            .sheet(item: $editingTodo, onDismiss: { viewModel?.load() }) { item in
                TodoEditView(existingTodo: item.todo, existingOccurrence: item.occurrence)
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Nothing here")
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func segmentBinding(_ viewModel: TodoHomeViewModel) -> Binding<TodoHomeViewModel.Segment> {
        Binding(
            get: { viewModel.segment },
            set: { viewModel.segment = $0; viewModel.load() }
        )
    }

    private func sortBinding(_ viewModel: TodoHomeViewModel) -> Binding<TodoHomeViewModel.SortOption> {
        Binding(
            get: { viewModel.sortOption },
            set: { viewModel.sortOption = $0; viewModel.sort() }
        )
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }
}

#Preview {
    TodoHomeView()
        .modelContainer(PersistenceController.sharedContainer)
}
