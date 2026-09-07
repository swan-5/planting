import SwiftUI

/// A Form row for picking a Category — styled like SwiftUI's native
/// Picker(.menu) row, but with the selected name colored to match that
/// category (added on request; a plain Picker always renders its trailing
/// value in the system accent color, with no way to override it).
///
/// Also lets the user create a brand-new category right from this menu
/// (added on request) — `categories` is a Binding rather than a plain
/// array so the newly created one can be appended straight into the
/// caller's own list and selected immediately, with no separate reload.
struct CategoryPickerRow: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var categories: [Category]
    @Binding var categoryID: UUID?
    var kind: CategoryKind = .event

    @State private var isPresentingNewCategory = false

    private var selectedCategory: Category? {
        categories.first { $0.id == categoryID }
    }

    var body: some View {
        Menu {
            Button("None") { categoryID = nil }
            ForEach(categories) { category in
                Button {
                    categoryID = category.id
                } label: {
                    if categoryID == category.id {
                        Label(category.name, systemImage: "checkmark")
                    } else {
                        Text(category.name)
                    }
                }
            }
            Divider()
            Button {
                isPresentingNewCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        } label: {
            HStack {
                Text("Category")
                    .foregroundStyle(PlantingColor.primaryText)
                Spacer()
                Text(selectedCategory?.name ?? "None")
                    .foregroundStyle(selectedCategory?.color ?? PlantingColor.secondaryText)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PlantingColor.secondaryText)
            }
        }
        .sheet(isPresented: $isPresentingNewCategory) {
            CategoryEditSheet(editingID: nil, initialName: "", initialColorHex: "6F9ED8") { name, colorHex in
                do {
                    let newCategory = try SwiftDataCategoryRepository(context: modelContext).create(name: name, colorHex: colorHex, kind: kind)
                    categories.append(newCategory)
                    categoryID = newCategory.id
                } catch {
                    print("Failed to create category: \(error)")
                }
            }
        }
    }
}
