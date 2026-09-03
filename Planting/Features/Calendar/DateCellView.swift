import SwiftUI

/// PRODUCT_SPEC.md §6.4, §6.5, §20.4. Schedules render as category-colored
/// bars drawn above this cell (see CalendarHomeView.weekRow /
/// ScheduleBarView) — not in the spec, added on request so every schedule
/// (not just multi-day ones) gets the same background-bar treatment. This
/// view now only lists todos; a fixed row cap keeps the cell from growing
/// unboundedly, with "+N" for the remainder — an approximation of
/// "responsive to available space" that avoids a full GeometryReader-based
/// dynamic-fit for the MVP. The §8 completion-intensity background was
/// removed on request — the cell background stays flat white regardless
/// of completion rate.
///
/// Drag-and-drop / copy-paste / manual reorder (not in the spec — added on
/// request): each todo row is draggable, the cell is a drop target, and
/// long-pressing offers Copy + Move to Top, or Paste on empty cell space.
/// The checkbox is its own Button so tapping it toggles completion
/// directly, without opening Date Detail. Tap-to-open uses `onOpen` rather
/// than wrapping this view in a NavigationLink, so the drag gesture on
/// inner rows doesn't fight the link's own tap gesture.
struct DateCellView: View {
    let day: MonthGridDay
    let isToday: Bool
    let content: CalendarHomeViewModel.CellContent
    let hasClipboard: Bool
    /// Blank space reserved below the date number so this cell's own rows
    /// don't sit under the schedule bars drawn as an overlay above the
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

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(dayNumber)
                .font(isToday ? PlantingFont.emphasis(14) : PlantingFont.dateNumber)
                .foregroundStyle(numberColor)

            if topInset > 0 {
                Color.clear.frame(height: topInset)
            }

            ForEach(content.todos.prefix(maxVisibleRows)) { item in
                todoRow(item)
                    .draggable(CalendarDragPayload(kind: .todoOccurrence, id: item.occurrence.id, sourceDate: day.date))
                    .contextMenu {
                        Button {
                            onCopy(CalendarDragPayload(kind: .todoOccurrence, id: item.occurrence.id, sourceDate: day.date))
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Button {
                            onMoveTodoToTop(item)
                        } label: {
                            Label("Move to Top", systemImage: "arrow.up.to.line")
                        }
                    }
            }

            if content.todos.count > maxVisibleRows {
                Text("+\(content.todos.count - maxVisibleRows)")
                    .font(PlantingFont.caption)
                    .foregroundStyle(PlantingColor.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(PlantingSpacing.xs)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
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

    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 2) {
            Button {
                onToggleTodo(item)
            } label: {
                Image(systemName: item.occurrence.completed ? "checkmark.square" : "square")
                    .font(.system(size: 8))
                    .foregroundStyle(item.todo.category?.color ?? PlantingColor.secondaryText)
            }
            .buttonStyle(.plain)
            Text(item.todo.title)
                .font(PlantingFont.itemLabel)
                .foregroundStyle(PlantingColor.primaryText)
                .lineLimit(1)
        }
    }

    private var numberColor: Color {
        if isToday { return PlantingColor.primaryBlue }
        return day.isInCurrentMonth ? PlantingColor.primaryText : PlantingColor.secondaryText
    }
}
