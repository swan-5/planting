import SwiftData

enum PersistenceController {
    static let sharedContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            Schedule.self,
            Todo.self,
            TodoOccurrence.self,
            Memo.self,
        ])
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
