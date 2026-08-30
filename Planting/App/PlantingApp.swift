import SwiftUI

@main
struct PlantingApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task { seedDefaultsIfNeeded() }
        }
        .modelContainer(PersistenceController.sharedContainer)
    }

    private func seedDefaultsIfNeeded() {
        let repository = SwiftDataCategoryRepository(context: PersistenceController.sharedContainer.mainContext)
        do {
            try CategorySeeder.seedIfNeeded(repository: repository)
        } catch {
            print("Category seeding failed: \(error)")
        }
    }
}
