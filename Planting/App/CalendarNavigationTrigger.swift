import Observation

/// Lets RootTabView tell CalendarHomeView "jump to today" when the user taps
/// the already-selected Calendar tab again — not in the spec, added on
/// request. A plain counter rather than a Bool so repeated taps on the same
/// day still fire a change (SwiftUI's `onChange` needs the value to
/// actually differ).
@Observable
final class CalendarNavigationTrigger {
    private(set) var goToTodayCount = 0

    func goToToday() {
        goToTodayCount += 1
    }
}
