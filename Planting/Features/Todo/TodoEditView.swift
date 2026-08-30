import SwiftUI
import SwiftData

/// S05 (PRODUCT_SPEC.md §11). Due date is required by this form even though
/// Todo.dueDate is optional at the model level (see Todo.swift) — the spec
/// notes open-ended todos may relax this later without a schema change.
struct TodoEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingTodo: Todo?

    @State private var title: String
    @State private var startDate: Date
    @State private var dueDate: Date
    @State private var categoryID: UUID?
    @State private var memo: String
    @State private var rule: RecurrenceRule
    @State private var categories: [Category] = []
    @State private var showingDeleteConfirmation = false

    init(existingTodo: Todo? = nil, initialDate: Date = .now) {
        self.existingTodo = existingTodo
        _title = State(initialValue: existingTodo?.title ?? "")
        _startDate = State(initialValue: existingTodo?.startDate ?? initialDate)
        _dueDate = State(initialValue: existingTodo?.dueDate ?? initialDate)
        _categoryID = State(initialValue: existingTodo?.category?.id)
        _memo = State(initialValue: existingTodo?.memo ?? "")
        _rule = State(initialValue: existingTodo?.recurrenceRule ?? .none)
    }

    private var isEditing: Bool { existingTodo != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(PlantingFont.body())
                }

                Section {
                    Picker("Category", selection: $categoryID) {
                        Text("None").tag(UUID?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                }

                Section {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Due date", selection: $dueDate, in: startDate..., displayedComponents: .date)
                }

                Section {
                    RecurrenceRuleEditor(rule: $rule)
                }

                Section {
                    TextField("Memo", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing {
                    Section {
                        Button("Delete Todo", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Todo" : "New Todo")
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
            .task { loadCategories() }
            .confirmationDialog(
                "Delete this todo?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: deleteTodo)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func loadCategories() {
        do {
            categories = try SwiftDataCategoryRepository(context: modelContext).fetchAll()
        } catch {
            print("Failed to load categories: \(error)")
        }
    }

    private func save() {
        let repository = SwiftDataTodoRepository(context: modelContext)
        let selectedCategory = categories.first { $0.id == categoryID }
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let existingTodo {
                existingTodo.title = trimmedTitle
                existingTodo.startDate = startDate
                existingTodo.dueDate = dueDate
                existingTodo.category = selectedCategory
                existingTodo.memo = trimmedMemo.isEmpty ? nil : trimmedMemo
                existingTodo.recurrenceRule = rule
                try repository.update(existingTodo)
            } else {
                let todo = Todo(
                    title: trimmedTitle,
                    startDate: startDate,
                    dueDate: dueDate,
                    category: selectedCategory,
                    memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
                    recurrenceRule: rule
                )
                try repository.create(todo)
            }
            dismiss()
        } catch {
            print("Failed to save todo: \(error)")
        }
    }

    private func deleteTodo() {
        guard let existingTodo else { return }
        do {
            try SwiftDataTodoRepository(context: modelContext).delete(existingTodo)
            dismiss()
        } catch {
            print("Failed to delete todo: \(error)")
        }
    }
}
