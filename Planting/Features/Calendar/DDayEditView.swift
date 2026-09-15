import SwiftUI
import SwiftData

/// Not in PRODUCT_SPEC.md — added on request. Create/edit form for a
/// standalone D-day counter (see DDayChipRow / DDayListView).
struct DDayEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingDDay: DDay?

    @State private var title: String
    @State private var targetDate: Date
    @State private var showingDeleteConfirmation = false

    init(existingDDay: DDay? = nil, initialDate: Date = .now) {
        self.existingDDay = existingDDay
        _title = State(initialValue: existingDDay?.title ?? "")
        _targetDate = State(initialValue: existingDDay?.targetDate ?? initialDate)
    }

    private var isEditing: Bool { existingDDay != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(PlantingFont.body())
                }
                Section {
                    DatePicker("Date", selection: $targetDate, displayedComponents: .date)
                }

                if isEditing {
                    Section {
                        Button("Delete D-day", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit D-day" : "New D-day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this D-day?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: delete)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let repository = SwiftDataDDayRepository(context: modelContext)
        do {
            if let existingDDay {
                existingDDay.title = trimmedTitle
                existingDDay.targetDate = targetDate
                try repository.update(existingDDay)
            } else {
                try repository.create(DDay(title: trimmedTitle, targetDate: targetDate))
            }
            dismiss()
        } catch {
            print("Failed to save D-day: \(error)")
        }
    }

    private func delete() {
        guard let existingDDay else { return }
        do {
            try SwiftDataDDayRepository(context: modelContext).delete(existingDDay)
            dismiss()
        } catch {
            print("Failed to delete D-day: \(error)")
        }
    }
}
