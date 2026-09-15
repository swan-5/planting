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
    private var isRevealed: Bool { offset < 0 }

    var body: some View {
        content()
            .background(PlantingColor.background)
            .contentShape(Rectangle())
            .overlay {
                // Swallows a tap while revealed to close the row instead of
                // letting it also reach the row's own tap/button action.
                if isRevealed {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { close() }
                }
            }
            .offset(x: offset + dragTranslation)
            // `.background` sizes its content to exactly match the view
            // it's attached to (unlike a `ZStack`, which can size its
            // children ambiguously when one of them asks for
            // `maxHeight: .infinity` with no bounded proposal) — that's
            // what keeps this button's hit area pinned to the real row
            // instead of ballooning to cover neighboring rows.
            .background(alignment: .trailing) {
                Button(role: .destructive) {
                    onDelete()
                    close()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white)
                        .frame(width: buttonWidth)
                        .frame(maxHeight: .infinity)
                }
                .background(Color.red)
                .opacity(isRevealed ? 1 : 0)
                .allowsHitTesting(isRevealed)
            }
            .gesture(
                DragGesture(minimumDistance: 15)
                    .updating($dragTranslation) { value, state, _ in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        state = min(0, max(value.translation.width, revealedOffset - offset))
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        withAnimation(.snappy) {
                            offset = (offset + value.translation.width) < revealedOffset / 2 ? revealedOffset : 0
                        }
                    }
            )
    }

    private func close() {
        withAnimation(.snappy) { offset = 0 }
    }
}
