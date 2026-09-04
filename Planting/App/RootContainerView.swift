import SwiftUI

/// Gates between the signed-out (AuthGateView) and signed-in (RootTabView)
/// states. RootTabView itself stays untouched — exactly the 3 tabs
/// PRODUCT_SPEC.md calls a non-negotiable — this wraps it from outside
/// rather than adding a 4th tab or a modal.
struct RootContainerView: View {
    @State private var session = AppSession.shared

    var body: some View {
        Group {
            if session.isSignedIn {
                RootTabView()
            } else {
                AuthGateView()
            }
        }
    }
}
