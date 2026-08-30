import SwiftUI

struct CategoryEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let editingID: UUID?
    @State private var name: String
    @State private var color: Color
    let onSave: (_ name: String, _ colorHex: String) -> Void

    init(
        editingID: UUID?,
        initialName: String,
        initialColorHex: String,
        onSave: @escaping (_ name: String, _ colorHex: String) -> Void
    ) {
        self.editingID = editingID
        self._name = State(initialValue: initialName)
        self._color = State(initialValue: Color(hexString: initialColorHex))
        self.onSave = onSave
    }

    private var isNew: Bool { editingID == nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $name)
                        .font(PlantingFont.body())
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                        .font(PlantingFont.body())
                }
            }
            .navigationTitle(isNew ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmedName, color.hexString)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(PlantingRadius.sheet)
    }
}
