import SwiftUI

/// Trailing swipe-to-delete for rows that live outside a `List` (where the
/// native `.swipeActions` modifier isn't available) — used by DateDetailView's
/// hand-built schedule/todo rows. TodoHomeView's rows are already inside a
/// `List` and use `.swipeActions` directly instead.
struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0

    private let buttonWidth: CGFloat = 74
    private var revealedOffset: CGFloat { -buttonWidth }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
            }
            .background(Color.red)

            content()
                .background(PlantingColor.background)
                .overlay {
                    // Closes the swipe on tap instead of letting it reach
                    // the row's own tap/button action underneath.
                    if offset != 0 {
                        Color.black.opacity(0.001)
                            .contentShape(Rectangle())
                            .onTapGesture { close() }
                    }
                }
                .offset(x: offset + dragTranslation)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .updating($dragTranslation) { value, state, _ in
                            state = min(0, max(value.translation.width, revealedOffset - offset))
                        }
                        .onEnded { value in
                            withAnimation(.snappy) {
                                offset = (offset + value.translation.width) < revealedOffset / 2 ? revealedOffset : 0
                            }
                        }
                )
        }
        .clipShape(Rectangle())
    }

    private func close() {
        withAnimation(.snappy) { offset = 0 }
    }
}
