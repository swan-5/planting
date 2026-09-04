import UIKit
import FirebaseAuth

/// A pure SwiftUI-lifecycle app has no UIApplicationDelegate by default, so
/// FirebaseAuth's own delegate swizzling has nothing to attach to — without
/// this, phone verification can't tell "no push token available" from a
/// real failure and surfaces a confusing error instead of falling back to
/// its built-in reCAPTCHA flow (the path this app uses until a paid Apple
/// Developer account adds real APNs-based silent verification).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Expected on the simulator, and on a device without a paid
        // Developer account's push capability — FirebaseAuth falls back to
        // reCAPTCHA verification on its own once this fires.
    }
}
