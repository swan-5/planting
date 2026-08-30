import SwiftUI

/// A continuous bar for a multi-day schedule, spanning its date range in
/// one piece rather than repeating the title in every day cell — not in
/// the spec, added on request to match how Apple/Google Calendar render
/// multi-day events in month view.
struct MultiDayBarView: View {
    let title: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(PlantingFont.itemLabel)
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}
