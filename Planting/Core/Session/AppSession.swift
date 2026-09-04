import Foundation
import Observation
import FirebaseAuth

/// The app's one auth/identity source of truth, wrapping Firebase Auth
/// directly rather than a separate SwiftData `User` model — Auth already
/// persists uid/phone number across launches on its own, so a local mirror
/// would just be a second source of truth for the same handful of fields.
///
/// `Core/Persistence` (shared with the PlantingWidgets extension) never
/// imports this file or FirebaseAuth — it reads the cached uid this class
/// writes into the shared App Group's UserDefaults suite instead (see
/// `PersistenceController.currentUserID`), so the widget never needs a live
/// auth session of its own.
@Observable
final class AppSession {
    static let shared = AppSession()

    private(set) var currentUserID: String?
    private(set) var phoneNumber: String?
    var isSignedIn: Bool { currentUserID != nil }

    private let sharedDefaults = UserDefaults(suiteName: PersistenceController.appGroupIdentifier)
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        currentUserID = Auth.auth().currentUser?.uid
        phoneNumber = Auth.auth().currentUser?.phoneNumber
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            let wasSignedIn = self.currentUserID != nil
            self.currentUserID = user?.uid
            self.phoneNumber = user?.phoneNumber
            self.sharedDefaults?.set(user?.uid, forKey: "currentUserID")

            if !wasSignedIn, user != nil {
                self.seedDefaultsForNewSignIn()
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    /// Runs once per fresh sign-in (transitioning signed-out → signed-in).
    /// Once M2 scopes `CategoryRepository.fetchAll()` by `ownerID`, this
    /// naturally reseeds defaults for any user who has none yet, rather
    /// than only ever running once globally on first app launch.
    private func seedDefaultsForNewSignIn() {
        Task { @MainActor in
            let repository = SwiftDataCategoryRepository(context: PersistenceController.sharedContainer.mainContext)
            do {
                try CategorySeeder.seedIfNeeded(repository: repository)
            } catch {
                print("Category seeding failed: \(error)")
            }
        }
    }
}
