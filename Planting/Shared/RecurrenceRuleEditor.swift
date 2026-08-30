import SwiftUI

/// Shared by Todo (§11) and Schedule (§14) create/edit forms. "Weekly" and
/// "Monthly" are simple presets with interval fixed at 1; "Custom" adds an
/// interval multiplier on top of the same weekday / day-of-month / nth-weekday
/// building blocks — matching the §11/§14 custom examples ("every 2 weeks on
/// Monday", "last Friday of every month"). Intended for use inside a Form Section.
struct RecurrenceRuleEditor: View {
    @Binding var rule: RecurrenceRule

    private enum CustomUnit { case week, month }
    private enum EndMode { case never, onDate, afterCount }

    var body: some View {
        Picker("Repeat", selection: frequencyBinding) {
            Text("Does not repeat").tag(RecurrenceFrequency.none)
            Text("Daily").tag(RecurrenceFrequency.daily)
            Text("Weekly").tag(RecurrenceFrequency.weekly)
            Text("Monthly").tag(RecurrenceFrequency.monthly)
            Text("Custom").tag(RecurrenceFrequency.custom)
        }

        switch rule.frequency {
        case .none, .daily:
            EmptyView()
        case .weekly:
            weekdaySelector
        case .monthly:
            monthlyFields
        case .custom:
            customUnitPicker
            intervalStepper
            if customUnit == .week {
                weekdaySelector
            } else {
                monthlyFields
            }
        }

        if rule.frequency != .none {
            repeatEndFields
        }
    }

    // MARK: Frequency

    private var frequencyBinding: Binding<RecurrenceFrequency> {
        Binding(
            get: { rule.frequency },
            set: { newValue in
                var updated = RecurrenceRule(frequency: newValue)
                switch newValue {
                case .weekly:
                    updated.weekdays = rule.weekdays?.isEmpty == false ? rule.weekdays : [.monday]
                case .monthly:
                    updated.dayOfMonth = rule.dayOfMonth ?? 1
                case .custom:
                    updated.interval = max(rule.interval, 2)
                    updated.weekdays = rule.weekdays?.isEmpty == false ? rule.weekdays : [.monday]
                default:
                    break
                }
                rule = updated
            }
        )
    }

    // MARK: Custom unit + interval

    private var customUnit: CustomUnit {
        rule.weekdays != nil ? .week : .month
    }

    private var customUnitPicker: some View {
        Picker("Every", selection: Binding(
            get: { customUnit },
            set: { unit in
                switch unit {
                case .week:
                    rule.weekdays = rule.weekdays?.isEmpty == false ? rule.weekdays : [.monday]
                    rule.dayOfMonth = nil
                    rule.weekOfMonthOrdinal = nil
                    rule.weekOfMonthWeekday = nil
                case .month:
                    rule.weekdays = nil
                    rule.dayOfMonth = rule.dayOfMonth ?? 1
                }
            }
        )) {
            Text("Weeks").tag(CustomUnit.week)
            Text("Months").tag(CustomUnit.month)
        }
    }

    private var intervalStepper: some View {
        Stepper(
            "Every \(rule.interval) \(customUnit == .week ? "week(s)" : "month(s)")",
            value: $rule.interval,
            in: 1...52
        )
    }

    // MARK: Weekday selector

    private var weekdaySelector: some View {
        HStack(spacing: PlantingSpacing.xs) {
            ForEach(Weekday.allCases) { weekday in
                weekdayToggle(weekday)
            }
        }
    }

    private func weekdayToggle(_ weekday: Weekday) -> some View {
        let isSelected = rule.weekdays?.contains(weekday) ?? false
        return Button {
            var set = rule.weekdays ?? []
            if isSelected { set.remove(weekday) } else { set.insert(weekday) }
            rule.weekdays = set
        } label: {
            Text(Self.shortSymbol(weekday))
                .font(PlantingFont.caption)
                .frame(width: 28, height: 28)
                .background(isSelected ? PlantingColor.primaryBlue : PlantingColor.divider)
                .foregroundStyle(isSelected ? .white : PlantingColor.primaryText)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Monthly pattern (day-of-month vs nth-weekday)

    private var monthlyFields: some View {
        let isDayMode = rule.dayOfMonth != nil
        return VStack(alignment: .leading, spacing: PlantingSpacing.sm) {
            Picker("Pattern", selection: Binding(
                get: { isDayMode },
                set: { useDay in
                    if useDay {
                        rule.dayOfMonth = rule.dayOfMonth ?? 1
                        rule.weekOfMonthOrdinal = nil
                        rule.weekOfMonthWeekday = nil
                    } else {
                        rule.dayOfMonth = nil
                        rule.weekOfMonthOrdinal = rule.weekOfMonthOrdinal ?? -1
                        rule.weekOfMonthWeekday = rule.weekOfMonthWeekday ?? .friday
                    }
                }
            )) {
                Text("Day of month").tag(true)
                Text("Day of week").tag(false)
            }
            .pickerStyle(.segmented)

            if isDayMode {
                Stepper(
                    "Day \(rule.dayOfMonth ?? 1)",
                    value: Binding(get: { rule.dayOfMonth ?? 1 }, set: { rule.dayOfMonth = $0 }),
                    in: 1...31
                )
            } else {
                Picker("Ordinal", selection: Binding(
                    get: { rule.weekOfMonthOrdinal ?? -1 },
                    set: { rule.weekOfMonthOrdinal = $0 }
                )) {
                    Text("First").tag(1)
                    Text("Second").tag(2)
                    Text("Third").tag(3)
                    Text("Fourth").tag(4)
                    Text("Last").tag(-1)
                }
                Picker("Weekday", selection: Binding(
                    get: { rule.weekOfMonthWeekday ?? .friday },
                    set: { rule.weekOfMonthWeekday = $0 }
                )) {
                    ForEach(Weekday.allCases) { weekday in
                        Text(Self.fullSymbol(weekday)).tag(weekday)
                    }
                }
            }
        }
    }

    // MARK: Repeat end

    private var repeatEndFields: some View {
        let mode: EndMode = {
            switch rule.end {
            case .never: return .never
            case .onDate: return .onDate
            case .afterCount: return .afterCount
            }
        }()

        return VStack(alignment: .leading, spacing: PlantingSpacing.sm) {
            Picker("Ends", selection: Binding(
                get: { mode },
                set: { newMode in
                    switch newMode {
                    case .never: rule.end = .never
                    case .onDate: rule.end = .onDate(.now)
                    case .afterCount: rule.end = .afterCount(10)
                    }
                }
            )) {
                Text("Never").tag(EndMode.never)
                Text("On date").tag(EndMode.onDate)
                Text("After count").tag(EndMode.afterCount)
            }

            if case .onDate(let date) = rule.end {
                DatePicker(
                    "End date",
                    selection: Binding(get: { date }, set: { rule.end = .onDate($0) }),
                    displayedComponents: .date
                )
            }
            if case .afterCount(let count) = rule.end {
                Stepper(
                    "After \(count) occurrences",
                    value: Binding(get: { count }, set: { rule.end = .afterCount($0) }),
                    in: 1...365
                )
            }
        }
    }

    // MARK: Symbols

    private static func shortSymbol(_ weekday: Weekday) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][weekday.rawValue - 1]
    }

    private static func fullSymbol(_ weekday: Weekday) -> String {
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][weekday.rawValue - 1]
    }
}
