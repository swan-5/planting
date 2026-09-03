import SwiftUI

/// A Form row for picking a Category — styled like SwiftUI's native
/// Picker(.menu) row, but with the selected name colored to match that
/// category (added on request; a plain Picker always renders its trailing
/// value in the system accent color, with no way to override it).
struct CategoryPickerRow: View {
    let categories: [Category]
    @Binding var categoryID: UUID?

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
    }
}
