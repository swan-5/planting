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
/// from that month's own data, not a persisted streak counter. The caption
/// below the mascot originally showed the week-count text; it now shows
/// FortuneOfTheDay instead (also on request), so the image is the only
/// remaining signal of monthly progress.
struct CloverGrowthView: View {
    let fullyCompletedWeeks: Int

    var level: Int { min(fullyCompletedWeeks, 4) }

    private var imageName: String? {
        level == 0 ? nil : "clover_stage\(level)"
    }

    private var size: CGFloat {
        [0, 50, 64, 78, 92][level]
    }

    var body: some View {
        VStack(spacing: PlantingSpacing.xs) {
            Group {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                } else {
                    Circle()
                        .strokeBorder(PlantingColor.divider, lineWidth: 1)
                        .frame(width: 28, height: 28)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: level)

            Text(FortuneOfTheDay.forToday())
                .font(PlantingFont.caption)
                .foregroundStyle(PlantingColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PlantingSpacing.xl)
        }
        .padding(.top, PlantingSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}
