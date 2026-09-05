import SwiftUI

/// Bottom navigation: exactly three primary tabs, nothing more
/// (PRODUCT_SPEC.md §4, non-negotiable #10).
struct RootTabView: View {
    private enum Tab {
        case calendar, todo, memo
    }

    @State private var selectedTab: Tab = .calendar
    @State private var navigationTrigger = CalendarNavigationTrigger()

    /// Tapping the Calendar tab while it's already selected jumps back to
    /// today (not in the spec — added on request) — the setter still runs
    /// even when the tapped tab matches the current selection, which is
    /// what lets this detect a "re-tap" rather than a switch-to.
    private var tabSelection: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == .calendar && selectedTab == .calendar {
                    navigationTrigger.goToToday()
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            CalendarHomeView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)

            TodoHomeView()
                .tabItem { Label("Todo", systemImage: "checkmark.square") }
                .tag(Tab.todo)

            MemoHomeView()
                .tabItem { Label("Memo", systemImage: "doc.text") }
                .tag(Tab.memo)
        }
        .environment(navigationTrigger)
        .tint(PlantingColor.primaryBlue)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PersistenceController.sharedContainer)
}
