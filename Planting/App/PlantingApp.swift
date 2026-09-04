import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct PlantingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        FirebaseApp.configure()
        #if DEBUG
        // The iOS Simulator can never receive real APNs pushes, so Firebase
        // Phone Auth's silent-push app-verification step always fails there
        // regardless of app/entitlement setup — this is Firebase's own
        // documented flag for exactly that case (debug/simulator/CI), not a
        // general bypass; it never ships in a Release build.
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .onOpenURL { url in
                    _ = Auth.auth().canHandle(url)
                }
        }
        .modelContainer(PersistenceController.sharedContainer)
    }
}
