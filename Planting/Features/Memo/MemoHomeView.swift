import SwiftUI
import SwiftData

/// S06 (PRODUCT_SPEC.md §17.3). Locked memos hide title/content behind a
/// biometric/passcode gate (§17.4) until unlocked for this session.
struct MemoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MemoHomeViewModel?
    @State private var isPresentingNew = false
    @State private var editingMemo: Memo?
    @State private var unlockedMemoIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                if let viewModel {
                    ForEach(viewModel.groups) { group in
                        Section {
                            ForEach(group.memos) { memo in
                                memoRow(memo)
                            }
                        } header: {
                            Text(Self.dateFormatter.string(from: group.date))
                                .font(PlantingFont.emphasis(12))
                                .foregroundStyle(PlantingColor.secondaryText)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(PlantingColor.background)
            .onAppear { viewModel?.load() }
            .navigationTitle("Memo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                guard viewModel == nil else { return }
                let vm = MemoHomeViewModel(repository: SwiftDataMemoRepository(context: modelContext))
                vm.load()
                viewModel = vm
            }
            .sheet(isPresented: $isPresentingNew, onDismiss: { viewModel?.load() }) {
                MemoEditView(initialDate: .now)
            }
            .sheet(item: $editingMemo, onDismiss: { viewModel?.load() }) { memo in
                MemoEditView(existingMemo: memo)
            }
        }
    }

    private func memoRow(_ memo: Memo) -> some View {
        let isLocked = memo.locked && !unlockedMemoIDs.contains(memo.id)
        return Button {
            if isLocked {
                unlock(memo)
            } else {
                editingMemo = memo
            }
        } label: {
            HStack(alignment: .top, spacing: PlantingSpacing.sm) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(PlantingColor.secondaryText)
                    Text("Locked memo")
                        .font(PlantingFont.body())
                        .foregroundStyle(PlantingColor.secondaryText)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        if let title = memo.title, !title.isEmpty {
                            Text(title)
                                .font(PlantingFont.emphasis())
                                .foregroundStyle(PlantingColor.primaryText)
                        }
                        Text(memo.content)
                            .font(PlantingFont.body())
                            .foregroundStyle(PlantingColor.primaryText)
                            .lineLimit(2)
                        Text(Self.timeFormatter.string(from: memo.updatedAt))
                            .font(PlantingFont.caption)
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
                    if memo.locked {
                        Image(systemName: "lock.open")
                            .font(.caption)
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func unlock(_ memo: Memo) {
        Task {
            if await BiometricAuthenticator.authenticate(reason: "Unlock memo") {
                unlockedMemoIDs.insert(memo.id)
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    MemoHomeView()
        .modelContainer(PersistenceController.sharedContainer)
}
