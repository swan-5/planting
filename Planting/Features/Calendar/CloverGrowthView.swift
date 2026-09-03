import SwiftUI

/// Not in the spec — the opposite of it, actually: PRODUCT_SPEC.md §1,
/// §20.1, and §22 explicitly ask for a calm, non-gamified feel, with no
/// decorative illustration. Added on direct request anyway: one leaf grows
/// per fully-completed calendar week in the visible month (see
/// CalendarHomeViewModel.fullyCompletedWeeksThisMonth). Only 4 art stages
/// exist (clover_stage1...4 in Assets.xcassets, from the user-provided
/// image), so growth caps at 4 completed weeks — a typical month has 4-6
/// grid weeks, so this reaches "full clover" a little before month end for
/// a perfect month. Resets automatically each month since it's derived
/// from that month's own data, not a persisted streak counter.
///
/// FortuneOfTheDay used to sit as a permanent caption underneath; on
/// request it's now tucked behind a tap on the clover itself, shown in a
/// small popover instead of always taking up space on screen.
struct CloverGrowthView: View {
    let fullyCompletedWeeks: Int

    @State private var isShowingFortune = false

    var level: Int { min(fullyCompletedWeeks, 4) }

    private var imageName: String? {
        level == 0 ? nil : "clover_stage\(level)"
    }

    /// clover_stage2 and clover_stage3 are both 3-leaf renders (stage3
    /// just fuller/at a different angle) — sized closer together than
    /// before so the jump between them reads as growth, not a size glitch,
    /// leaving stage4's 4-leaf reveal as the one big step up.
    private var size: CGFloat {
        [0, 48, 56, 64, 80][level]
    }

    var body: some View {
        Group {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .strokeBorder(PlantingColor.divider, lineWidth: 1)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text("오늘의\n운세")
                            .font(.system(size: 10))
                            .multilineTextAlignment(.center)
                            .lineSpacing(1)
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: level)
        .contentShape(Rectangle())
        .onTapGesture { isShowingFortune = true }
        .popover(isPresented: $isShowingFortune, arrowEdge: .bottom) {
            Text(FortuneOfTheDay.forToday())
                .font(PlantingFont.body())
                .foregroundStyle(PlantingColor.primaryText)
                .multilineTextAlignment(.center)
                .padding(PlantingSpacing.lg)
                .frame(maxWidth: 260)
                .presentationCompactAdaptation(.popover)
        }
        .frame(maxWidth: .infinity)
    }
}
