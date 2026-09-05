import SwiftUI

/// S09 — minimal for MVP: the one real preference (categories) plus app
/// info. Security toggles (§17.4 app-wide lock, etc.) are Future Features
/// (PRODUCT_SPEC.md §26), not part of this pass.
struct SettingsView: View {
    /// Not in the spec — added on request, read by CalendarHomeView.
    @AppStorage("showHolidays") private var showHolidays = true

    var body: some View {
        List {
            Section {
                if let phoneNumber = AppSession.shared.phoneNumber {
                    HStack {
                        Text("Phone")
                            .font(PlantingFont.body())
                        Spacer()
                        Text(phoneNumber)
                            .font(PlantingFont.body())
                            .foregroundStyle(PlantingColor.secondaryText)
                    }
                }
                Button("Sign Out", role: .destructive) {
                    try? AppSession.shared.signOut()
                }
                .font(PlantingFont.body())
            }

            Section {
                NavigationLink("Category") {
                    CategoryManagementView()
                }
                .font(PlantingFont.body())
            }

            Section {
                Toggle("Show Holidays", isOn: $showHolidays)
                    .font(PlantingFont.body())
            }

            Section {
                HStack {
                    Text("Version")
                        .font(PlantingFont.body())
                    Spacer()
                    Text(Self.appVersion)
                        .font(PlantingFont.body())
                        .foregroundStyle(PlantingColor.secondaryText)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PersistenceController.sharedContainer)
}
