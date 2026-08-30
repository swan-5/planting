import SwiftUI

/// PRODUCT_SPEC.md §10 row format: title, then "Category · D-1" / "Category
/// · Due today", or "Completed Aug 17" once done.
struct TodoRow: View {
    let item: TodoItem
    let dDayLabel: String
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: PlantingSpacing.sm) {
            Button(action: onToggle) {
                Image(systemName: item.occurrence.completed ? "checkmark.square" : "square")
                    .foregroundStyle(item.occurrence.completed ? PlantingColor.primaryBlue : PlantingColor.secondaryText)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.todo.title)
                    .font(PlantingFont.body())
                    .foregroundStyle(PlantingColor.primaryText)
                Text(subtitle)
                    .font(PlantingFont.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, PlantingSpacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let categoryName = item.todo.category?.name { parts.append(categoryName) }
        if item.occurrence.completed, let completedAt = item.occurrence.completedAt {
            parts.append("Completed \(Self.dateFormatter.string(from: completedAt))")
        } else {
            parts.append(dDayLabel)
        }
        return parts.joined(separator: " · ")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}
