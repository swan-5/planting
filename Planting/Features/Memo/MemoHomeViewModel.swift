import Foundation
import Observation

@Observable
final class MemoHomeViewModel {
    struct DateGroup: Identifiable {
        let date: Date
        let memos: [Memo]
        var id: Date { date }
    }

    private(set) var groups: [DateGroup] = []
    private let repository: MemoRepository
    private let calendar: Calendar

    init(repository: MemoRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func load() {
        do {
            let all = try repository.fetchAll()
            let grouped = Dictionary(grouping: all) { calendar.startOfDay(for: $0.date) }
            groups = grouped.keys.sorted(by: >).map { date in
                DateGroup(date: date, memos: grouped[date, default: []].sorted { $0.createdAt > $1.createdAt })
            }
        } catch {
            print("Failed to load memos: \(error)")
        }
    }
}
