import Foundation
import UniformTypeIdentifiers
import CoreTransferable

/// Carries just IDs across a drag/drop or copy/paste — the destination view
/// re-fetches the real model objects, since SwiftData model classes aren't
/// safe to hand across a Transferable boundary directly.
struct CalendarDragPayload: Codable, Transferable, Equatable {
    enum Kind: String, Codable {
        case todoOccurrence
        case schedule
    }

    let kind: Kind
    let id: UUID
    /// The date cell this item was showing on when the drag/copy started —
    /// used to compute the day delta to apply on drop/paste.
    let sourceDate: Date

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
