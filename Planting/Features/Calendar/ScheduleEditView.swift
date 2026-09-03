import SwiftUI
import SwiftData

/// S03 (PRODUCT_SPEC.md §15).
struct ScheduleEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingSchedule: Schedule?

    @State private var title: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var allDay: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var categoryID: UUID?
    @State private var location: String
    @State private var memo: String
    @State private var rule: RecurrenceRule
    @State private var categories: [Category] = []
    @State private var showingDeleteConfirmation = false

    init(existingSchedule: Schedule? = nil, initialDate: Date = .now) {
        self.existingSchedule = existingSchedule
        _title = State(initialValue: existingSchedule?.title ?? "")
        _startDate = State(initialValue: existingSchedule?.startDate ?? initialDate)
        _hasEndDate = State(initialValue: existingSchedule?.endDate != nil)
        _endDate = State(initialValue: existingSchedule?.endDate ?? existingSchedule?.startDate ?? initialDate)
        _allDay = State(initialValue: existingSchedule?.allDay ?? false)
        _startTime = State(initialValue: existingSchedule?.startTime ?? initialDate)
        _endTime = State(initialValue: existingSchedule?.endTime ?? initialDate)
        _categoryID = State(initialValue: existingSchedule?.category?.id)
        _location = State(initialValue: existingSchedule?.location ?? "")
        _memo = State(initialValue: existingSchedule?.memo ?? "")
        _rule = State(initialValue: existingSchedule?.recurrenceRule ?? .none)
    }

    private var isEditing: Bool { existingSchedule != nil }
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
                    Toggle("All day", isOn: $allDay)
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    if !allDay {
                        DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                    Toggle("Multi-day", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section {
                    RecurrenceRuleEditor(rule: $rule)
                }

                Section {
                    TextField("Location (optional)", text: $location)
                        .font(PlantingFont.body())
                }

                Section {
                    TextField("Memo", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing {
                    Section {
                        Button("Delete Schedule", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "New Schedule")
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
                "Delete this schedule?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: deleteSchedule)
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
        let repository = SwiftDataScheduleRepository(context: modelContext)
        let selectedCategory = categories.first { $0.id == categoryID }
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let existingSchedule {
                existingSchedule.title = trimmedTitle
                existingSchedule.startDate = startDate
                existingSchedule.endDate = hasEndDate ? endDate : nil
                existingSchedule.allDay = allDay
                existingSchedule.startTime = allDay ? nil : startTime
                existingSchedule.endTime = allDay ? nil : endTime
                existingSchedule.category = selectedCategory
                existingSchedule.location = trimmedLocation.isEmpty ? nil : trimmedLocation
                existingSchedule.memo = trimmedMemo.isEmpty ? nil : trimmedMemo
                existingSchedule.recurrenceRule = rule
                try repository.update(existingSchedule)
            } else {
                let schedule = Schedule(
                    title: trimmedTitle,
                    startDate: startDate,
                    endDate: hasEndDate ? endDate : nil,
                    startTime: allDay ? nil : startTime,
                    endTime: allDay ? nil : endTime,
                    allDay: allDay,
                    category: selectedCategory,
                    location: trimmedLocation.isEmpty ? nil : trimmedLocation,
                    memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
                    recurrenceRule: rule
                )
                try repository.create(schedule)
            }
            dismiss()
        } catch {
            print("Failed to save schedule: \(error)")
        }
    }

    private func deleteSchedule() {
        guard let existingSchedule else { return }
        do {
            try SwiftDataScheduleRepository(context: modelContext).delete(existingSchedule)
            dismiss()
        } catch {
            print("Failed to delete schedule: \(error)")
        }
    }
}
