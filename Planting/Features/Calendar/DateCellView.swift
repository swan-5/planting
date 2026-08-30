import SwiftUI

/// PRODUCT_SPEC.md §6.4, §6.5, §20.4: schedules (color dot) and todos
/// (checkbox) render together in one list, never split into separate cards;
/// a fixed row cap keeps the cell from growing unboundedly, with "+N" for
/// the remainder — an approximation of "responsive to available space"
/// that avoids a full GeometryReader-based dynamic-fit for the MVP.
/// The §8 completion-intensity background was removed on request — the
/// cell background stays flat white regardless of completion rate.
///
/// Drag-and-drop / copy-paste / manual reorder (not in the spec — added on
/// request): each row is draggable, the cell is a drop target, and
/// long-pressing offers Copy (+ Move to Top for todos) on a row, or Paste
/// on empty cell space. The todo checkbox is its own Button so tapping it
/// toggles completion directly, without opening Date Detail. Tap-to-open
/// uses `onOpen` rather than wrapping this view in a NavigationLink, so the
/// drag gesture on inner rows doesn't fight the link's own tap gesture.
struct DateCellView: View {
    let day: MonthGridDay
    let isToday: Bool
    let content: CalendarHomeViewModel.CellContent
    let hasClipboard: Bool
    /// Blank space reserved below the date number so this cell's own rows
    /// don't sit under the multi-day bars drawn as an overlay above the
    /// whole week row (see CalendarHomeView.weekRow).
    let topInset: CGFloat
    let onOpen: () -> Void
    let onMove: (CalendarDragPayload) -> Void
    let onCopy: (CalendarDragPayload) -> Void
    let onPaste: () -> Void
    let onToggleTodo: (TodoItem) -> Void
    let onMoveTodoToTop: (TodoItem) -> Void

    private let maxVisibleRows = 3

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.calendar = MonthGridBuilder.calendar
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }

    private var rows: [DateCellRow] {
        content.schedules.map(DateCellRow.schedule) + content.todos.map(DateCellRow.todo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(dayNumber)
                .font(isToday ? PlantingFont.emphasis(13) : PlantingFont.dateNumber)
                .foregroundStyle(numberColor)

            if topInset > 0 {
                Color.clear.frame(height: topInset)
            }

            ForEach(rows.prefix(maxVisibleRows)) { row in
                rowView(row)
                    .draggable(row.dragPayload(sourceDate: day.date))
                    .contextMenu {
                        Button {
                            onCopy(row.dragPayload(sourceDate: day.date))
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        if case .todo(let item) = row {
                            Button {
                                onMoveTodoToTop(item)
                            } label: {
                                Label("Move to Top", systemImage: "arrow.up.to.line")
                            }
                        }
                    }
            }

            if rows.count > maxVisibleRows {
                Text("+\(rows.count - maxVisibleRows)")
                    .font(PlantingFont.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(PlantingSpacing.xs)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        .background(PlantingColor.background)
        .overlay {
            Rectangle().strokeBorder(PlantingColor.divider, lineWidth: 0.5)
        }
        .opacity(day.isInCurrentMonth ? 1 : 0.35)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .dropDestination(for: CalendarDragPayload.self) { payloads, _ in
            guard let payload = payloads.first else { return false }
            onMove(payload)
            return true
        }
        .contextMenu {
            if hasClipboard {
                Button {
                    onPaste()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: DateCellRow) -> some View {
        switch row {
        case .schedule(let occurrence):
            HStack(spacing: 3) {
                Circle()
                    .fill(occurrence.schedule.category?.color ?? PlantingColor.secondaryText)
                    .frame(width: 5, height: 5)
                Text(occurrence.schedule.title)
                    .font(PlantingFont.itemLabel)
                    .foregroundStyle(PlantingColor.primaryText)
                    .lineLimit(1)
            }
        case .todo(let item):
            HStack(spacing: 3) {
                Button {
                    onToggleTodo(item)
                } label: {
                    Image(systemName: item.occurrence.completed ? "checkmark.square" : "square")
                        .font(.system(size: 9))
                        .foregroundStyle(item.occurrence.completed ? PlantingColor.primaryBlue : PlantingColor.secondaryText)
                }
                .buttonStyle(.plain)
                Text(item.todo.title)
                    .font(PlantingFont.itemLabel)
                    .foregroundStyle(PlantingColor.primaryText)
                    .lineLimit(1)
            }
        }
    }

    private var numberColor: Color {
        if isToday { return PlantingColor.primaryBlue }
        return day.isInCurrentMonth ? PlantingColor.primaryText : PlantingColor.secondaryText
    }
}
