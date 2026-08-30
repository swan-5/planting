import Foundation

/// Backs the "N / M completed" text (PRODUCT_SPEC.md §7). The §8.3
/// completion-intensity level was removed on request along with the
/// pastel-blue background it fed.
struct DailyCompletionSummary {
    let completed: Int
    let total: Int

    /// nil when there are no todos for the date.
    var rate: Double? {
        total == 0 ? nil : Double(completed) / Double(total)
    }
}
