import SwiftUI
import SwiftData

/// S07 (PRODUCT_SPEC.md §17.2). When editing an existing locked memo,
/// MemoHomeView already required authentication before presenting this
/// sheet, so no additional gate is needed here.
struct MemoEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingMemo: Memo?

    @State private var title: String
    @State private var content: String
    @State private var date: Date
    @State private var locked: Bool
    @State private var categoryID: UUID?
    @State private var categories: [Category] = []
    @State private var showingDeleteConfirmation = false

    init(existingMemo: Memo? = nil, initialDate: Date = .now) {
        self.existingMemo = existingMemo
        _title = State(initialValue: existingMemo?.title ?? "")
        _content = State(initialValue: existingMemo?.content ?? "")
        _date = State(initialValue: existingMemo?.date ?? initialDate)
        _locked = State(initialValue: existingMemo?.locked ?? false)
        _categoryID = State(initialValue: existingMemo?.category?.id)
    }

    private var isEditing: Bool { existingMemo != nil }
    private var trimmedContent: String { content.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section {
                    TextField("Title (optional)", text: $title)
                }
                Section {
                    CategoryPickerRow(categories: $categories, categoryID: $categoryID, kind: .memo)
                }
                Section {
                    TextField("Write something...", text: $content, axis: .vertical)
                        .lineLimit(6...12)
                }
                Section {
                    Toggle("Lock this memo", isOn: $locked)
                }
                if isEditing {
                    Section {
                        Button("Delete Memo", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Memo" : "New Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedContent.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this memo?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: deleteMemo)
                Button("Cancel", role: .cancel) {}
            }
            .task { loadCategories() }
        }
    }

    private func loadCategories() {
        do {
            categories = try SwiftDataCategoryRepository(context: modelContext).fetchAll(kind: .memo)
        } catch {
            print("Failed to load categories: \(error)")
        }
    }

    private func save() {
        let repository = SwiftDataMemoRepository(context: modelContext)
        let selectedCategory = categories.first { $0.id == categoryID }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let existingMemo {
                existingMemo.title = trimmedTitle.isEmpty ? nil : trimmedTitle
                existingMemo.content = trimmedContent
                existingMemo.date = date
                existingMemo.locked = locked
                existingMemo.category = selectedCategory
                try repository.update(existingMemo)
            } else {
                let memo = Memo(
                    title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                    content: trimmedContent,
                    date: date,
                    locked: locked,
                    category: selectedCategory
                )
                try repository.create(memo)
            }
            dismiss()
        } catch {
            print("Failed to save memo: \(error)")
        }
    }

    private func deleteMemo() {
        guard let existingMemo else { return }
        do {
            try SwiftDataMemoRepository(context: modelContext).delete(existingMemo)
            dismiss()
        } catch {
            print("Failed to delete memo: \(error)")
        }
    }
}
