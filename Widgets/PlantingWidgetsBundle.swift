import WidgetKit
import SwiftUI

@main
struct PlantingWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        TodoWidget()
        CalendarWidget()
    }
}
