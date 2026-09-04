import SwiftUI

/// Shown by RootContainerView whenever AppSession.isSignedIn is false.
struct AuthGateView: View {
    var body: some View {
        NavigationStack {
            PhoneLoginView()
        }
    }
}
