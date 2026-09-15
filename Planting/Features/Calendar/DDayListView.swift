import SwiftUI
import SwiftData

/// Full D-day list, reached from DDayChipRow's "…" overflow chip when there
/// are more than 3. Loads/reloads its own data so it stays correct across
/// edits/deletes made from inside it.
struct DDayListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onChanged: () -> Void

    @State private var dDays: [DDay] = []
    @State private var editingDDay: DDay?

    private var sorted: [DDay] {
        dDays.sorted { abs($0.daysFromToday()) < abs($1.daysFromToday()) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sorted) { dDay in
                    Button {
                        editingDDay = dDay
                    } label: {
                        HStack {
                            Text(dDay.title)
                                .foregroundStyle(PlantingColor.primaryText)
                            Spacer()
                            Text(dDay.label())
                                .foregroundStyle(PlantingColor.secondaryText)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(dDay)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("D-day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { load() }
            .sheet(item: $editingDDay, onDismiss: load) { dDay in
                DDayEditView(existingDDay: dDay)
            }
        }
    }

    private func load() {
        do {
            dDays = try SwiftDataDDayRepository(context: modelContext).fetchAll()
            onChanged()
        } catch {
            print("Failed to load D-days: \(error)")
        }
    }

    private func delete(_ dDay: DDay) {
        do {
            try SwiftDataDDayRepository(context: modelContext).delete(dDay)
            load()
        } catch {
            print("Failed to delete D-day: \(error)")
        }
    }
}
