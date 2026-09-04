import SwiftUI
import SwiftData

/// S05 (PRODUCT_SPEC.md §11). Due date is required by this form even though
/// Todo.dueDate is optional at the model level (see Todo.swift) — the spec
/// notes open-ended todos may relax this later without a schema change.
struct TodoEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingTodo: Todo?
    /// The specific occurrence this edit was opened from — needed for
    /// delete scope (see RecurrenceDeleteScope). Every call site that edits
    /// an existing todo has a TodoItem on hand and passes it; nil only when
    /// creating a new todo.
    private let existingOccurrence: TodoOccurrence?

    @State private var title: String
    @State private var startDate: Date
    @State private var dueDate: Date
    @State private var categoryID: UUID?
    @State private var memo: String
    @State private var rule: RecurrenceRule
    @State private var categories: [Category] = []
    @State private var showingDeleteConfirmation = false

    init(existingTodo: Todo? = nil, existingOccurrence: TodoOccurrence? = nil, initialDate: Date = .now) {
        self.existingTodo = existingTodo
        self.existingOccurrence = existingOccurrence
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
                    CategoryPickerRow(categories: categories, categoryID: $categoryID)
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
                if existingTodo?.recurrenceRule.frequency != .none, existingOccurrence != nil {
                    Button("Delete This Todo Only", role: .destructive) {
                        deleteTodo(scope: .onlyThisOccurrence)
                    }
                    Button("Delete This and Future Todos", role: .destructive) {
                        deleteTodo(scope: .thisAndFuture)
                    }
                    Button("Delete All Todos", role: .destructive) {
                        deleteTodo(scope: .entireSeries)
                    }
                } else {
                    Button("Delete", role: .destructive) {
                        deleteTodo(scope: .entireSeries)
                    }
                }
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

    private func deleteTodo(scope: RecurrenceDeleteScope) {
        guard let existingTodo else { return }
        do {
            let repository = SwiftDataTodoRepository(context: modelContext)
            if let existingOccurrence {
                try repository.deleteOccurrence(TodoItem(todo: existingTodo, occurrence: existingOccurrence), scope: scope)
            } else {
                try repository.delete(existingTodo)
            }
            dismiss()
        } catch {
            print("Failed to delete todo: \(error)")
        }
    }
}
