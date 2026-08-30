# Planting — Product Specification

> Version: 1.0  
> Product type: Personal productivity / calendar app  
> Primary platform: iOS  
> Status: MVP planning  
> This document is the source of truth for product behavior and design decisions.

---

## 1. Product Overview

### Product Name
**Planting**

### One-line Description
Planting is a personal productivity app that combines **calendar schedules, todos, and date-based notes** in one place, while visually accumulating completed work on the monthly calendar.

### Core Product Idea
The app should let users understand, from a single monthly calendar:

1. what they have scheduled,
2. what they still need to do,
3. how much they have completed.

Schedules and todos are shown together inside each date cell, but must remain visually distinguishable.

Todo completion is reflected by the background intensity of each calendar date, inspired by GitHub contribution activity, using a muted pastel-blue scale.

---

## 2. Product Goals

Planting should reduce the need to switch between separate calendar, todo, and memo apps.

The user should be able to open the app and immediately understand:

- what is happening this month,
- what needs to be done today,
- what has not yet been completed,
- how productive each day has been,
- what notes were written on a specific date.

The app should feel calm, organized, and practical rather than gamified or visually noisy.

---

## 3. Core Product Principles

### 3.1 Calendar-first experience
The monthly calendar is the main screen and the central product experience.

### 3.2 Schedule + Todo together
Schedules and todos appear inside the same date cell.

They must be distinguishable without splitting them into separate cards.

### 3.3 Unfinished todos persist until deadline
A todo with a start date and due date should continue to appear every day until it is completed or the due date passes.

Example:

- Start date: Aug 18
- Due date: Aug 21

If unfinished:

- Aug 18 → visible
- Aug 19 → visible
- Aug 20 → visible
- Aug 21 → visible

If completed on Aug 20, it should no longer appear as an unfinished todo after completion.

### 3.4 Completion becomes visual history
Daily todo completion should affect the calendar cell background.

The monthly calendar should become a visual record of completed work.

### 3.5 Date-centered data
Schedules, todos, and memos are all organized around dates.

Selecting a date should allow the user to view the schedule, todos, and related notes for that date.

---

## 4. Navigation

Bottom navigation contains exactly three primary tabs:

1. **Calendar**
2. **Todo**
3. **Memo**

Do not add unnecessary primary navigation items.

---

## 5. Screen Map

| ID | Screen | Purpose |
|---|---|---|
| S01 | Calendar Home | Monthly calendar with schedules, todos, and completion intensity |
| S02 | Date Detail | Full details for selected date |
| S03 | Schedule Create/Edit | Create or edit schedule |
| S04 | Todo Home | Today / All / Completed todos |
| S05 | Todo Create/Edit | Create or edit todo |
| S06 | Memo Home | Browse notes by date |
| S07 | Memo Create/Edit | Write or edit memo |
| S08 | Category Management | Create/edit/delete categories and colors |
| S09 | Settings | App preferences and security |
| S10 | Widget Settings | Configure supported iOS widgets |

---

# 6. Calendar Home — S01

## 6.1 Purpose
This is the main screen of Planting.

It must display, in one monthly view:

- schedules,
- todos,
- daily todo completion intensity.

## 6.2 Header

Example:

`August 2026`

Provide small previous / next month controls.

A Today action may be included if it does not clutter the layout.

Avoid oversized headings.

## 6.3 Monthly Calendar

Standard 7-column month grid.

Weekday header:

`SUN MON TUE WED THU FRI SAT`

Each date cell may contain:

1. date number,
2. schedule items,
3. todo items,
4. completion-level background.

## 6.4 Date Cell Example

```text
18

● Team meeting
✓ PPT revision
□ English study
```

### Schedule indicator
Schedules should use:

- a small category-colored dot or short color marker,
- schedule title.

Example:

`● Team meeting`

### Todo indicator
Todos should use checkbox-style indicators.

Examples:

`✓ PPT revision`

`□ English study`

Do not place schedule and todo sections inside separate cards within a date cell.

## 6.5 Overflow
When a date contains too many items to fit:

```text
18

● Team meeting
✓ PPT revision
□ English study
+3
```

Selecting `+3` or the date cell opens the full date detail.

The number of visible entries should be responsive to available screen space.

---

# 7. Date Detail — S02

Selecting a date opens or reveals the full information for that date.

Example:

```text
August 18, Tuesday

Schedule
● Team meeting
  14:00

● Dermatology
  17:30

TO DO
✓ PPT draft
□ English study
□ Application
```

Optional secondary information:

`4 / 5 completed`

or

`80% completed`

Completion numbers should not dominate the main calendar UI.

---

# 8. Todo Completion Calendar

## 8.1 Concept
Inspired by GitHub contribution intensity.

Do **not** create a separate GitHub-style grid.

Instead, apply the completion intensity directly to the background of each monthly calendar date cell.

## 8.2 Color Direction
Use a muted pastel-blue scale.

Recommended values:

| Level | Meaning | Color |
|---|---|---|
| 0 | No todos scheduled | `#FFFFFF` |
| 1 | Low completion | `#EEF5FC` |
| 2 | Moderate-low | `#DBEAF8` |
| 3 | Moderate-high | `#BDD8F1` |
| 4 | High | `#93BCE4` |
| 5 | Full completion | `#6F9ED8` |

These values may be adjusted slightly for accessibility, but the overall visual identity must remain muted pastel blue.

## 8.3 Completion Calculation

Recommended base logic:

```text
completionRate = completedTodosForDate / totalTodosForDate
```

Suggested levels:

- no todos → Level 0
- 0–25% → Level 1
- 26–50% → Level 2
- 51–75% → Level 3
- 76–99% → Level 4
- 100% → Level 5

A date with no todos must look different from a date with todos but zero completed.

Accessibility must take priority over strict color values.

---

# 9. Todo System

## 9.1 Todo Fields

Each todo should support:

- title
- start date
- due date
- category
- memo / description
- recurrence
- recurrence end condition
- completion state
- completion date/time

## 9.2 Visibility Logic

An unfinished todo should appear when:

```text
startDate <= currentDate <= dueDate
AND
todo is not completed
```

For repeating todos, visibility is based on each occurrence rather than the parent template.

## 9.3 Completion

When checked:

- occurrence becomes completed,
- completed timestamp is stored,
- unfinished list removes it,
- completion state contributes to that date's calendar intensity.

---

# 10. Todo Home — S04

Top-level views:

- **Today**
- **All**
- **Completed**

## Today
Show todos relevant to the current date.

Example:

```text
□ PPT revision
  School · D-1

□ English study
  Personal · Due today

□ Application
  Career · D-3
```

## All
Show all active unfinished todos.

## Completed
Show completed todo occurrences.

Example:

```text
✓ PPT draft
  Completed Aug 17
```

## Sorting
Support at least:

- due date
- creation date
- category

---

# 11. Todo Create / Edit — S05

Fields:

### Title
Required.

### Category
Optional or default category.

### Start Date
Required.

### Due Date
Required unless product behavior later explicitly supports open-ended todos.

### Repeat
Options:

- Does not repeat
- Daily
- Weekly
- Monthly
- Custom

### Weekly Repeat
Allow multiple weekday selection.

Example:

`Mon / Wed / Fri`

### Custom Repeat
Must support patterns such as:

- every 2 weeks on Monday
- every week on Monday and Thursday
- every month on the 15th
- last Friday of every month

### Repeat End
Options:

- Never
- On a specific date
- After a specific number of occurrences

### Memo
Optional.

---

# 12. Repeating Todo Behavior

Each repeat occurrence has an independent completion state.

Example:

Todo: `Workout`

Repeat:
Monday / Wednesday / Friday

```text
Monday     ✓ completed
Wednesday  □ incomplete
Friday     □ incomplete
```

Completing Monday must not complete Wednesday or Friday.

Recurring todos must be modeled so individual occurrences can be edited or completed independently.

---

# 13. Schedule System

Schedules support:

- title
- start date
- end date
- start time
- end time
- all-day option
- category
- memo
- recurrence
- recurrence end condition

---

# 14. Schedule Recurrence

Schedule repeat options:

- Does not repeat
- Daily
- Weekly
- Monthly
- Custom

Weekly repeat must allow weekday selection.

Custom repeat should support patterns such as:

- every 2 weeks on Thursday
- every month on the 1st
- last Friday of every month

Repeat end:

- Never
- Specific date
- After N occurrences

---

# 15. Schedule Create / Edit — S03

Fields:

### Title
Required.

### Date
Start date and optional end date.

### Time
Start and end time.

### All Day
Boolean.

### Category

### Repeat

### Repeat End

### Memo

### Save

Editing an existing schedule should allow deletion.

For repeating items, editing behavior should eventually support:

- this occurrence,
- this and future occurrences,
- entire series.

If this is too large for the first MVP build, structure the data model so this can be added later without rewriting the recurrence system.

---

# 16. Category System

Schedules and todos share the same category system.

Users can:

- create category,
- rename category,
- change color,
- reorder category,
- delete category.

Example default categories may include:

- School
- Personal
- Work
- Appointment

Do not force users to keep defaults.

Category color is independent from the pastel-blue completion scale.

---

# 17. Memo System

## 17.1 Purpose
Allow users to quickly record thoughts connected to a date.

A memo does not need to be a schedule or todo.

## 17.2 Memo Fields

- date
- optional title
- content
- locked state
- created timestamp
- updated timestamp

## 17.3 Memo Home — S06
Browse memos by date.

Example:

```text
August 18

Service idea
Widget layout should be simpler...
19:21

Meeting thought
Review category UI.
14:32

🔒 Locked memo
```

## 17.4 Memo Lock
Individual memos can be locked.

Preferred authentication:

1. Face ID
2. Touch ID where supported
3. app passcode fallback if implemented

Use native iOS security APIs when possible.

---

# 18. Quick Add

Provide a `+` action from the calendar home or another unobtrusive location.

Selecting it opens a simple bottom sheet:

- Schedule
- Todo
- Memo

Do not design this as a large floating AI-style action menu.

---

# 19. iPhone Widgets

Planting should support iPhone widgets.

## Widget A — Today
Display:

- current date,
- today's schedules,
- today's todos.

## Widget B — Todo
Display today's active todos.

## Widget C — Calendar
Display a compact monthly or weekly calendar with schedule/completion hints.

## Sizes

### Small
- date
- 2–3 todos

### Medium
- today's schedule
- today's todos

### Large
- calendar
- schedules
- todos

## Visual Direction
The widget should feel visually lightweight and blend naturally with the user's home screen.

Do not depend on true transparency if iOS does not support it.

Use the closest native-supported visual treatment.

---

# 20. Design System

## 20.1 Overall Direction
Planting should look like a real, carefully designed iOS productivity app.

It must **not** look like:

- an AI-generated dashboard,
- a generic SaaS template,
- a landing page,
- a heavily gamified habit tracker.

Prioritize:

- clarity,
- restraint,
- readability,
- information density,
- consistent spacing.

---

## 20.2 Typography

Primary font:

**Pretendard**

Use Pretendard consistently for:

- Korean,
- English,
- numbers.

Recommended weights:

- body: 400
- emphasis: 500
- section heading: 600

Avoid unnecessary 700+ bold usage.

If a native iOS limitation makes Pretendard technically inappropriate in a specific system surface such as a widget or system-generated UI, preserve visual consistency as closely as possible and document the limitation before changing behavior.

---

## 20.3 Primary Colors

Primary blue:

`#6F9ED8`

Primary text:

`#202124`

Secondary text:

`#8A8D91`

Divider:

`#ECEDEF`

Background:

`#FFFFFF`

Todo completion colors are defined separately in Section 8.

---

## 20.4 UI Rules

### White Base
Primary screen background should remain white.

### Avoid Excessive Cards
Do not wrap every section in rounded cards.

Prefer:

- spacing,
- typography,
- subtle dividers.

### Border Radius
Use restraint.

Recommended:

- buttons: 8–10px
- text inputs: ~8px
- modal / bottom sheet: 16–20px

Calendar date cells should not look like individual rounded cards by default.

### Shadows
Default:

`no shadow`

Use only when required to communicate elevation.

### No Decorative Gradients
Avoid decorative gradients.

### No Glassmorphism
Do not use glass effects as a visual gimmick.

### Avoid Pill Overuse
Do not make every button, category, label, or filter a capsule.

### No Huge Hero Typography
This is an app interface, not a marketing page.

### Avoid Decorative Illustrations
Do not add illustration, emoji, or decorative artwork unless explicitly requested later.

### No Meaningless Badges
Only use badges when they communicate actual product state.

---

# 21. Iconography

Use one consistent thin-line icon system.

Recommended visual direction:

- Calendar
- CheckSquare
- FileText
- Plus
- ChevronLeft
- ChevronRight
- Lock
- Settings
- MoreHorizontal

If using a library, keep icon stroke weight consistent.

Do not mix filled, outlined, emoji, and illustration-style icons.

---

# 22. Motion

Motion should support usability, not decoration.

Good examples:

- subtle checkbox transition,
- short fade after completing a todo,
- natural month slide,
- native-feeling bottom sheet transition.

Avoid:

- bouncing,
- glowing,
- dramatic scale animation,
- excessive spring effects,
- celebratory confetti by default.

---

# 23. Data Model

The implementation does not need to use these exact names, but the data relationships must support the specified behavior.

## Schedule

```ts
Schedule {
  id
  title
  startDate
  endDate
  startTime
  endTime
  allDay
  categoryId
  memo
  recurrenceRule
  recurrenceEnd
  createdAt
  updatedAt
}
```

## Todo

```ts
Todo {
  id
  title
  startDate
  dueDate
  categoryId
  memo
  recurrenceRule
  recurrenceEnd
  createdAt
  updatedAt
}
```

## TodoOccurrence

```ts
TodoOccurrence {
  id
  todoId
  occurrenceDate
  completed
  completedAt
}
```

The occurrence model is required so repeated todos can have independent completion states.

## Memo

```ts
Memo {
  id
  title
  content
  date
  locked
  createdAt
  updatedAt
}
```

## Category

```ts
Category {
  id
  name
  color
  order
}
```

---

# 24. MVP Scope

## P0 — Required for core MVP

### Calendar
- monthly calendar
- schedule display inside date cells
- todo display inside date cells
- date selection
- date detail
- completion-based pastel-blue date background

### Schedule
- create
- edit
- delete
- date/time
- all-day
- category
- repeat
- custom repeat

### Todo
- create
- edit
- delete
- start date
- due date
- persistent unfinished visibility
- completion
- recurring todo
- weekday repeat
- custom repeat
- independent occurrence completion

### Category
- create
- rename
- change color
- delete

### Memo
- create
- edit
- delete
- date-based organization
- individual memo lock

### Navigation
- Calendar
- Todo
- Memo

---

# 25. P1

Add after or near first release if not included in the initial MVP:

- iPhone widgets
- Face ID integration
- todo sorting
- completed todo archive
- due-date notifications
- repeat end settings
- monthly completion summary

---

# 26. Future Features

Not part of the first implementation unless explicitly requested:

- iCloud sync
- app-wide lock
- search
- advanced reminders
- multiple widget themes
- app themes
- external calendar integration
- backup / restore
- monthly statistics
- streaks
- collaboration / shared calendars

Do not implement these automatically.

---

# 27. Core User Flows

## Schedule

```text
Calendar
→ Select date
→ Add
→ Schedule
→ Enter title
→ Set date/time
→ Set category
→ Set recurrence
→ Save
→ Show in monthly calendar
```

## Todo

```text
Calendar or Todo
→ Add
→ Todo
→ Enter title
→ Set start date
→ Set due date
→ Set category
→ Set recurrence
→ Save
→ Keep visible until completed or deadline
→ Check complete
→ Save completion occurrence
→ Update calendar completion intensity
```

## Memo

```text
Memo
→ Select date
→ Add
→ Write content
→ Optional lock
→ Save
```

---

# 28. Non-Negotiable Product Behaviors

The following behaviors must not be changed unless explicitly requested:

1. **Schedule and todo must appear together inside the monthly calendar.**
2. **Schedule and todo must remain visually distinguishable.**
3. **Unfinished todos persist until their deadline.**
4. **Todo completion is visualized through pastel-blue calendar-cell intensity.**
5. **Schedules and todos both support recurrence.**
6. **Weekly recurrence supports selectable weekdays.**
7. **Custom recurrence is supported.**
8. **Repeating todo occurrences have independent completion states.**
9. **Memo entries can be associated with dates and individually locked.**
10. **Bottom navigation remains Calendar / Todo / Memo.**
11. **Pretendard is the default product font.**
12. **The design must avoid generic AI-generated dashboard aesthetics.**

---

# 29. Instructions for Claude Code

Treat this document as the product source of truth.

Do not silently remove, reinterpret, or simplify core requirements.

Before implementing a major feature:

1. read the relevant section of this specification,
2. inspect the existing codebase,
3. preserve established architecture and design system,
4. avoid redesigning unrelated screens,
5. do not add features not requested,
6. call out genuine technical limitations before replacing specified behavior.

When asked to implement one feature, implement that feature without unnecessarily rebuilding the whole app.

The app should evolve incrementally while preserving consistency.

---

# 30. Recommended Initial Claude Prompt

Use this after placing this file in the project:

```text
Read PRODUCT_SPEC.md completely before making changes.

Planting is an iOS productivity app and PRODUCT_SPEC.md is the source of truth for product behavior and design.

Before writing implementation code, inspect the current project and propose:

1. app architecture,
2. technology stack,
3. screen structure,
4. persistence/data model,
5. recurrence architecture for schedules and todos,
6. TodoOccurrence handling,
7. monthly calendar completion-color logic,
8. iOS widget approach,
9. development order.

Do not implement the entire app yet.

Do not reinterpret or remove core requirements.

Follow the design system strictly:
- Pretendard
- white base
- muted pastel blue
- minimal cards
- no decorative gradients
- no glassmorphism
- minimal shadow
- restrained border radius
- consistent thin-line icons
- no generic AI dashboard aesthetic

The final UI should look like a carefully designed real iOS productivity app, not an AI-generated template.
```

---

# 31. Recommended First Implementation Prompt

After the architecture is agreed:

```text
Now implement the first functional slice of Planting based on PRODUCT_SPEC.md.

Scope:
- base app structure
- bottom navigation
- Calendar Home
- monthly calendar
- schedules and todos rendered together inside date cells
- clear visual distinction between schedules and todos
- date selection
- pastel-blue calendar-cell background based on todo completion level

Do not implement Memo, widgets, advanced notifications, or unrelated future features yet.

Do not redesign the specification.

Preserve the Planting design system and avoid generic AI-generated UI patterns.
```
