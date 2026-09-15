import SwiftUI

/// Up to 3 small "title / D-n" chips shown beside the clover on the
/// Calendar tab, nearest-to-today first; a 4th "…" chip opens the full list
/// (DDayListView) when there are more than 3.
struct DDayChipRow: View {
    let dDays: [DDay]
    let onTapChip: (DDay) -> Void
    let onTapMore: () -> Void

    private var visible: [DDay] { Array(dDays.prefix(3)) }
    private var hasMore: Bool { dDays.count > 3 }

    var body: some View {
        if !dDays.isEmpty {
            HStack(spacing: PlantingSpacing.xs) {
                ForEach(visible) { dDay in
                    chip(title: dDay.title, value: dDay.label()) {
                        onTapChip(dDay)
                    }
                }
                if hasMore {
                    chip(title: nil, value: "…", action: onTapMore)
                }
            }
        }
    }

    private func chip(title: String?, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if let title {
                    Text(title)
                        .font(.system(size: 9))
                        .lineLimit(1)
                        .foregroundStyle(PlantingColor.secondaryText)
                }
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PlantingColor.primaryText)
            }
            .padding(.horizontal, PlantingSpacing.sm)
            .padding(.vertical, 4)
            .background(PlantingColor.divider.opacity(0.6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
