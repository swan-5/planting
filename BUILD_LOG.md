# Planting — Feature Specification & Build Log

_As of 2026-09-04 · 10 commits · 57 Swift files · SwiftUI + SwiftData, iOS 17+_

What actually shipped against `PRODUCT_SPEC.md`, plus everything added or changed live during
development that the spec doesn't cover — kept as one running record instead of scattered
across the build history.

---

## 1. P0 — Core MVP

Every item in `PRODUCT_SPEC.md §24` is built. Screen IDs match the spec's own screen map (§5).

### Calendar

- **✓ S01 — Calendar Home**: month grid, header nav with slide transition, schedules and todos
  rendered together inside date cells. Weekday header fixed SUN→SAT regardless of device region.
- **✓ S02 — Date Detail**: full schedule/todo list for one date, reached from a cell tap or its
  "+N" overflow. "N / M completed" shown as secondary text, not a headline number.
- **✓ S03 — Schedule Create / Edit**: title, date/time, all-day, category, location, recurrence,
  memo, delete.

### Todo

- **✓ S04 — Todo Home**: Today / All / Completed, sortable by due date, created date, or category.
- **✓ S05 — Todo Create / Edit**: start/due date, category, recurrence, memo. Independent
  completion per occurrence, per §12.

### Category

- **✓ S08 — Category Management**: create, rename, recolor, reorder, delete; four seeded
  defaults the user is never forced to keep.

### Memo

- **✓ S06 — Memo Home**: browse by date, locked entries collapsed to a lock icon until unlocked.
- **✓ S07 — Memo Create / Edit**: optional title, content, per-memo lock toggle.

### Shell

- **✓ S09 — Settings**: category entry point, app version.
- **✓ Quick Add**: plain three-row bottom sheet (Schedule / Todo / Memo) from the calendar's "+".
- **✓ Recurrence engine**: daily / weekly (multi-weekday) / monthly (fixed day or nth-weekday) /
  custom intervals, shared by Schedule and Todo.
- **✓ Memo lock**: Face ID → Touch ID → passcode, via `LocalAuthentication`.

---

## 2. P1 — iPhone widgets

One `PlantingWidgets` extension target, reading the app's SwiftData store from a shared App
Group container. Widgets never write to it — a repeating todo only appears once the app itself
has materialized that occurrence.

| Widget | Sizes | What it shows |
|---|---|---|
| **Today** | Small · Medium | Current date, today's schedules, today's todos — checked and unchecked alike. |
| **Todo** | Small · Medium | Active todos only, no schedules. Small shows 3, Medium shows 6 with a "+N more" tail. |
| **Calendar** | Medium · Large | Medium: the current week as a compact strip. Large: the full month, each day carrying a schedule dot and a todo-completion dot. |

---

## 3. Beyond the spec

Requested live against the running app, in order. Two of these — the growth mascot and the
completion background removal — run against explicit non-negotiables in
`§1 / §20.1 / §22 / §28`; both were confirmed before building.

1. **Removed the pastel-blue completion background.** §8's GitHub-style intensity shading on
   date cells was dropped; cells stay flat white regardless of completion rate. Strikethrough on
   completed todo titles was dropped in the same pass.

2. **Clover growth mascot.** One leaf per fully-completed calendar week, four art stages sourced
   from a user-supplied image, capped at a full four-leaf clover. Recomputed from the visible
   month's own data, so it resets on its own each month rather than tracking a persisted streak.

3. **Daily fortune.** Replaced the mascot's progress caption with one of 200 pre-written lines,
   picked deterministically by calendar day so it holds steady until midnight.

4. **Drag, copy, and manual reorder on the grid.** Long-press drag reschedules a todo or
   schedule to another date, preserving its span. Copy duplicates it elsewhere as a plain
   one-off. "Move to Top" reorders same-day todos by hand.

5. **Multi-day schedules, fixed and then generalized.** Multi-day schedules had only ever
   rendered on their start day — a latent bug, fixed by expanding each occurrence across its
   full span. Then generalized further on request: every schedule, single-day included, now
   renders as one category-colored bar instead of a dot-and-text row, with the same drag/copy
   support.

6. **Schedule location.** Optional field, shown under the time in Date Detail.

7. **Completed-todo display, fixed twice.** A multi-day todo's checkmark now lands on its due
   date only, not the day it happened to be tapped — the first version anchored to the real
   completion timestamp, which made items appear to jump to whichever day they were checked off
   from.

8. **Month-slide navigation.** Previous/next now slides in the direction of travel, per §22's
   own "natural month slide" example — this one was already spec-aligned, just not built yet.

9. **Legibility pass, tuned twice.** Cells and numerals sized up first for readability; item
   text then sized back down to 10pt after that made titles truncate harder — a calendar column
   is ~50pt wide regardless, so keeping ~4 characters visible costs more than it gains in font
   size.

10. **Monthly Reflection.** A new screen reached by tapping the month name in the calendar
    header (`September ⌄`): auto-aggregated stats recomputed fresh every time it opens
    (completion rate, best week, category breakdown, incomplete todos) plus a hand-written
    3-question reflection that's the only part actually persisted (`MonthlyReflection`, one row
    per year+month). The three questions are themselves editable in place — defaulting to the
    built-in wording but rewritable to fit how the user actually wants to reflect — and shared
    app-wide via `UserDefaults` rather than per month. A "Best Day" section shipped and was then
    removed on request, along with its now-unused aggregation logic.

11. **Todo search.** Plain substring match on title, added to Todo Home's existing filter/sort
    controls.

12. **Clover mascot, settled.** The daily-fortune caption moved from a permanent line under the
    clover to a tap-to-reveal popover on the clover itself; the clover was recentered in the
    blank space below the grid; the empty (pre-growth) state is now a plain circle labeled
    "오늘의 운세" instead of blank, so there's always something to tap.

13. **Calendar header, reshuffled.** The `‹ September ⌄ ›` layout (item 10 above introduced the
    tappable month name) put month-navigation chevrons on either side of that button; moved back
    to sit next to "Today" on the right, matching the header's original layout, with the month
    name standing alone on the left. A year label was added above the month name, and the
    ≥4-completed-weeks clover badge that used to sit next to it was dropped (the clover under
    the grid already shows this).

14. **Category-colored checkboxes.** Todo checkboxes (Todo Home, Date Detail, and the calendar's
    date-cell rows) now render in the todo's category color instead of a fixed blue/gray, so a
    day's todos read at a glance the same way schedule bars already do. The Category picker in
    the Schedule/Todo edit forms was rebuilt as a custom `CategoryPickerRow` for the same
    reason — a stock SwiftUI `Picker` always renders its selected value in the system accent
    color with no way to recolor it, so the picker itself couldn't show the category color it
    was about to set.

15. **Date Detail: day navigation and tap-to-add.** `‹ ›` chevrons beside the date title step
    one day at a time without leaving the screen. Tapping any blank space below the schedule/todo
    list opens the same "Add Schedule / Add Todo" choice as the toolbar's "+" — built as a small
    bottom sheet (matching `QuickAddSheet`'s style) rather than `confirmationDialog`, since
    iOS 26's redesigned action-sheet presentation anchors as a floating card near the tap point
    and would otherwise land on top of the header or list it was just triggered from.

16. **Recurrence-aware delete.** Deleting a repeating Schedule or Todo now asks which occurrences
    to affect — "This Event/Todo Only", "This and Future", or "All" — matching Apple Calendar's
    own pattern. Schedule occurrences are virtual (expanded on demand, never persisted per-date),
    so "only this one" is a new `excludedDates: [Date]` list `RecurrenceEngine` filters out, and
    "this and future" just truncates `recurrenceRule.end` to the day before. Todo occurrences
    *are* persisted rows (`TodoOccurrence`), so "only this one" instead flips a new `isSkipped`
    flag rather than deleting the row outright — deleting it would only have had lazy
    materialization silently recreate it the next time that date range was queried — and "this
    and future" deletes every occurrence row from that date on top of the same `end` truncation.
    Every read path (Todo Home, Date Detail, Monthly Reflection, both widgets) now filters
    `isSkipped` rows out.

17. **Swipe to change months.** A left/right drag on the calendar grid now moves to the
    next/previous month, alongside the existing header chevrons — kept to a fairly large
    `minimumDistance` so a quick horizontal flick doesn't fight the long-press-then-drag gesture
    `.draggable` already uses for rescheduling a todo/schedule onto another date.

---

## 4. Known limitations

- **No accounts or login.** Raised, scoped to three options (app lock / Sign in with Apple /
  email+password), then put on hold pending a decision on what it's actually for.
- **No cross-device sync.** SwiftData's CloudKit integration would cover this, but a real
  container needs a paid Apple Developer account — this environment only has ad hoc local
  signing.
- **Personal-device installs only.** Automatic code signing is wired up for a free Apple ID;
  TestFlight and the App Store both need the paid Developer Program — not yet enrolled. App
  Store submission prep has started ahead of that: the 1024×1024 app icon is confirmed
  compliant, a privacy policy page is live at `swan-5.github.io/planting/privacy.html` (via
  GitHub Pages, `docs/`), and a first draft of the store listing copy (name, subtitle,
  description, keywords) exists outside this repo. `project.yml` now pins `DEVELOPMENT_TEAM`
  explicitly — it had been set by hand in Xcode's Signing & Capabilities editor, which
  `xcodegen generate` silently discards on every regeneration since that setting never lived in
  `project.yml` to begin with.
- **Widgets can miss upcoming repeating todos.** They read the shared store but never
  materialize new occurrences themselves, so the app has to open at least once first.
- **Pretendard doesn't reach the widgets.** A widget extension is a separate bundle; it falls
  back to the system font rather than carrying its own copy of the typeface.

---

## 5. Architecture & stack

| | |
|---|---|
| **UI** | SwiftUI, MVVM, `@Observable` view models |
| **Persistence** | SwiftData, stored in an App Group container shared with the widget extension |
| **Project** | XcodeGen (`project.yml`) — two targets, `Planting` and `PlantingWidgets` |
| **Recurrence** | Hand-rolled engine, an RFC5545 subset — no third-party RRule dependency |
| **Security** | `LocalAuthentication` for per-memo lock |
| **Widgets** | `WidgetKit`, three widget kinds, timeline refresh every 30–60 min |

---

_github.com/swan-5/planting · HEAD 68a854a · 2026-09-04_
