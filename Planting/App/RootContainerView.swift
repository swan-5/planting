import SwiftUI
import SwiftData

/// Gates between signed-out (AuthGateView), needs-profile-setup
/// (BirthdayEntryView), and signed-in (RootTabView). RootTabView itself
/// stays untouched — exactly the 3 tabs PRODUCT_SPEC.md calls a
/// non-negotiable — this wraps it from outside rather than adding a 4th tab
/// or a modal.
struct RootContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var session = AppSession.shared
    @State private var needsProfileSetup = false

    var body: some View {
        Group {
            if session.isSignedIn {
                if needsProfileSetup {
                    BirthdayEntryView(onDone: { needsProfileSetup = false })
                } else {
                    RootTabView()
                }
            } else {
                AuthGateView()
            }
        }
        .task(id: session.currentUserID) {
            checkProfileSetup()
        }
    }

    private func checkProfileSetup() {
        guard session.isSignedIn else { return }
        let profile = try? SwiftDataUserProfileRepository(context: modelContext).fetch()
        needsProfileSetup = (profile == nil)
    }
}
