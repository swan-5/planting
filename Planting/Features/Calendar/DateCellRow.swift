import Foundation

enum DateCellRow: Identifiable {
    case schedule(ScheduleOccurrence)
    case todo(TodoItem)

    var id: String {
        switch self {
        case .schedule(let occurrence): return "s-\(occurrence.id)"
        case .todo(let item): return "t-\(item.id)"
        }
    }
}
