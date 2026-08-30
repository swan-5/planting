import Foundation
import SwiftUI
import SwiftData

/// S08 (PRODUCT_SPEC.md §16). Every row — including the seeded defaults —
/// is renameable, recolorable, reorderable, and deletable.
struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CategoryListViewModel?
    @State private var editingCategory: Category?
    @State private var isPresentingNew = false

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.categories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        HStack(spacing: PlantingSpacing.sm) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 10, height: 10)
                            Text(category.name)
                                .font(PlantingFont.body())
                                .foregroundStyle(PlantingColor.primaryText)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onMove { viewModel.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { offsets in
                    for index in offsets { viewModel.delete(viewModel.categories[index]) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingNew = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = CategoryListViewModel(repository: SwiftDataCategoryRepository(context: modelContext))
            vm.load()
            viewModel = vm
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(
                editingID: category.id,
                initialName: category.name,
                initialColorHex: category.colorHex
            ) { name, colorHex in
                viewModel?.save(editingID: category.id, name: name, colorHex: colorHex)
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            CategoryEditSheet(
                editingID: nil,
                initialName: "",
                initialColorHex: String(format: "%06X", 0x6F9ED8)
            ) { name, colorHex in
                viewModel?.save(editingID: nil, name: name, colorHex: colorHex)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryManagementView()
    }
    .modelContainer(PersistenceController.sharedContainer)
}
