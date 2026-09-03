import SwiftUI
import UIKit

/// A continuous, category-colored background bar for a schedule — on
/// request, every schedule renders this way now, not just multi-day ones
/// (matches how Apple/Google Calendar render events in month view). Same
/// drag/copy affordances the old inline row had: draggable to reschedule,
/// long-press to Copy.
struct ScheduleBarView: View {
    let title: String
    let color: Color
    let sourceDate: Date
    let scheduleID: UUID
    let onTap: () -> Void
    let onCopy: (CalendarDragPayload) -> Void

    var body: some View {
        Text(title)
            .font(PlantingFont.itemLabel)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .draggable(CalendarDragPayload(kind: .schedule, id: scheduleID, sourceDate: sourceDate))
            .contextMenu {
                Button {
                    onCopy(CalendarDragPayload(kind: .schedule, id: scheduleID, sourceDate: sourceDate))
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
    }

    /// Category colors are user-chosen and can be any lightness, so pick
    /// whichever of black/white actually reads against this one rather
    /// than assuming white always works. Threshold sits high (0.75, not
    /// the more textbook-common ~0.5-0.6) because the app's muted-pastel
    /// category colors (§16) are mid-toned enough that white reads better
    /// on nearly all of them — confirmed on a ~0.64-luminance sage green
    /// that looked wrong with black. Only genuinely pale colors fall back
    /// to black text.
    private var textColor: Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.75 ? PlantingColor.primaryText : .white
    }
}
