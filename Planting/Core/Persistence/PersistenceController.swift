import Foundation
import SwiftData

/// The store lives in the App Group container (not the app's private
/// container) so the widget extension can read it too. Both the app and
/// PlantingWidgets targets declare the `group.com.planting.app` entitlement.
enum PersistenceController {
    static let appGroupIdentifier = "group.com.planting.app"

    static let sharedContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            Schedule.self,
            Todo.self,
            TodoOccurrence.self,
            Memo.self,
            MonthlyReflection.self,
            UserProfile.self,
        ])

        let configuration: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            configuration = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("Planting.sqlite"))
        } else {
            // Falls back to the app's private container — e.g. if the App
            // Group entitlement isn't provisioned. The widget won't see
            // data in this case, but the app itself still works.
            configuration = ModelConfiguration(schema: schema)
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// The signed-in Firebase uid, read from the shared App Group's
    /// UserDefaults suite — deliberately Foundation-only (no FirebaseAuth
    /// import) so both the app's repositories and the PlantingWidgets
    /// extension (which cannot hold a live auth session of its own) can use
    /// the same accessor. AppSession is the only writer of this key.
    static var currentUserID: String {
        UserDefaults(suiteName: appGroupIdentifier)?.string(forKey: "currentUserID") ?? ""
    }
}
