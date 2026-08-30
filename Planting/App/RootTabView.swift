import SwiftUI

/// Bottom navigation: exactly three primary tabs, nothing more
/// (PRODUCT_SPEC.md §4, non-negotiable #10).
struct RootTabView: View {
    var body: some View {
        TabView {
            CalendarHomeView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            TodoHomeView()
                .tabItem { Label("Todo", systemImage: "checkmark.square") }

            MemoHomeView()
                .tabItem { Label("Memo", systemImage: "doc.text") }
        }
        .tint(PlantingColor.primaryBlue)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PersistenceController.sharedContainer)
}
