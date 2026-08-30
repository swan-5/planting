import SwiftUI

/// PRODUCT_SPEC.md §18 — a plain three-row bottom sheet, deliberately not a
/// large floating AI-style action menu.
struct QuickAddSheet: View {
    let onSelectSchedule: () -> Void
    let onSelectTodo: () -> Void
    let onSelectMemo: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(icon: "calendar", title: "Schedule", action: onSelectSchedule)
            Divider().overlay(PlantingColor.divider)
            row(icon: "checkmark.square", title: "Todo", action: onSelectTodo)
            Divider().overlay(PlantingColor.divider)
            row(icon: "doc.text", title: "Memo", action: onSelectMemo)
        }
        .padding(.vertical, PlantingSpacing.sm)
        .presentationDetents([.height(200)])
        .presentationCornerRadius(PlantingRadius.sheet)
        .presentationDragIndicator(.visible)
    }

    private func row(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PlantingSpacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(PlantingColor.primaryBlue)
                    .frame(width: 24)
                Text(title)
                    .font(PlantingFont.body())
                    .foregroundStyle(PlantingColor.primaryText)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, PlantingSpacing.lg)
            .padding(.vertical, PlantingSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
