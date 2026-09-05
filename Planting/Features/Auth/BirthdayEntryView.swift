import SwiftUI
import SwiftData

/// Shown once per account right after sign-in, before RootTabView — not in
/// PRODUCT_SPEC.md, added on request so the calendar can mark the user's
/// birthday every year. Skippable; either path creates the UserProfile row
/// (see UserProfileRepository) so this screen never shows again for the
/// same account.
struct BirthdayEntryView: View {
    @Environment(\.modelContext) private var modelContext
    let onDone: () -> Void

    @State private var birthday = Date.now

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PlantingSpacing.xl) {
                VStack(alignment: .leading, spacing: PlantingSpacing.xs) {
                    Text("When's your birthday?")
                        .font(PlantingFont.sectionHeading(22))
                        .foregroundStyle(PlantingColor.primaryText)
                    Text("Planting marks it on your calendar every year.")
                        .font(PlantingFont.body())
                        .foregroundStyle(PlantingColor.secondaryText)
                }

                DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .font(PlantingFont.body())

                Button {
                    save(birthday: birthday)
                } label: {
                    Text("Continue")
                        .font(PlantingFont.emphasis())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PlantingSpacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(PlantingColor.primaryBlue)

                Button {
                    save(birthday: nil)
                } label: {
                    Text("Skip")
                        .font(PlantingFont.body(13))
                        .foregroundStyle(PlantingColor.secondaryText)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(PlantingSpacing.lg)
            .background(PlantingColor.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func save(birthday: Date?) {
        do {
            try SwiftDataUserProfileRepository(context: modelContext).save(birthday: birthday)
        } catch {
            print("Failed to save birthday: \(error)")
        }
        onDone()
    }
}
