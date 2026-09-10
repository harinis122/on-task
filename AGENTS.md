# AGENTS.md

## 1. Purpose of This File

This file defines the persistent product, architecture, engineering, and development rules for **OnTask**.

Coding agents working in this repository should read this file before making changes.

Treat this file as the durable project contract.

Individual prompts may ask for a specific incremental implementation task. Those prompts determine **what to work on right now**, while this file determines **how the project should be designed and how OnTask should behave overall**.

Do not attempt to implement the entire product unless explicitly asked.

Prefer small, understandable, independently testable changes.

---

# 2. Product Overview

**OnTask** is a menu-bar-first native macOS focus application that keeps the user's current task visible while they work.

The core problem OnTask solves is simple:

> **What am I supposed to be doing right now?**

Users often:

* lose track of what they were doing,
* lose their train of thought,
* switch between tasks without consciously deciding to,
* multitask unnecessarily,
* become unclear about what they are supposed to accomplish,
* or spend a long time on a task without realizing how much time has passed.

OnTask keeps one current task visible in the macOS menu bar so the user remains aware of their intended focus.

The application should encourage:

* one task at a time,
* intentional work,
* awareness of the current objective,
* reduced mindless context switching,
* and awareness of time spent on the current task.

OnTask is intentionally small and unobtrusive.

It should not itself become a distraction.

---

# 3. MVP Product Philosophy

OnTask is **not** a task-management system.

It is not intended to replace:

* Todoist,
* Notion,
* Reminders,
* project-management software,
* calendars,
* productivity dashboards,
* or other planning tools.

The MVP represents exactly one concept:

> **What am I doing right now?**

There may be zero or one current task.

There is never more than one active task in the MVP.

A task may be timed with either:

* a **Stopwatch**, which counts active time upward, or
* a **Timer**, which counts active time down from a configured duration.

Stopwatch and Timer are two timing modes for the same focus session. They are not separate task concepts.

The application should favor simplicity over feature richness.

When choosing between:

* a simple native implementation, and
* a more flexible but significantly more complicated implementation,

prefer the simpler implementation unless the requirements clearly demand otherwise.

---

# 4. Current MVP Requirements

## 4.1 Menu Bar Presence

OnTask lives in the macOS menu bar while the application is running.

The app should not require a traditional permanent application window for normal use.

### No Current Task

When OnTask is running and no task is set:

* show a small OnTask menu bar icon,
* do not display placeholder task text,
* clicking the icon opens the OnTask menu.

Conceptually:

```text
◎
```

The exact icon may change, so icon-specific assumptions should not be spread throughout the code.

Use the asset system or centralized configuration where appropriate.

### Current Task Exists

When a task is active:

* the menu bar should display the current task,
* the task should remain visible while the user works in other applications,
* the menu bar label must remain short enough not to consume excessive menu bar space.

Task text should be truncated when necessary.

The display limit should be centralized rather than hard-coded throughout the UI.

Target approximately **5-20 visible characters** for the menu bar representation.

Example:

```text
Finish database...
```

Do not let long task names consume excessive menu bar width.

The menu bar should not permanently display elapsed or remaining time unless explicitly requested. Detailed timing information belongs inside the menu.

---

# 5. Menu Behavior

Clicking the OnTask menu bar item opens the application's menu interface.

The menu-bar popup is the application's primary user experience.

OnTask should not have a traditional main application window unless a future feature creates a clear product need for one.

Keep the existing AppKit-based menu-bar architecture:

* `NSStatusItem` creates and manages the menu-bar item,
* `NSPopover` provides the menu-bar popup,
* `NSHostingController` hosts the SwiftUI `MenuView`,
* `MenuView.swift` remains the primary focus-session UI.

Do **not** replace this architecture with SwiftUI `MenuBarExtra` unless explicitly requested.

The main MVP UI belongs in:

```text
Views/MenuView.swift
```

Do not create unnecessary additional views until the UI is complicated enough to justify them.

For the current MVP, `MenuView` may contain the complete active-use OnTask interface.

---

# 6. No-Task UI and Timing Choice

When there is no current task, `MenuView` should provide a minimal interface for creating one.

The user enters:

* task text,
* timing mode.

The timing modes should appear side-by-side:

```text
[ Stopwatch ] [ Timer ]
```

Stopwatch is selected by default.

If Timer is selected, reveal a field below the selector:

```text
How many minutes?
[ 25 ]
```

Switching back to Stopwatch hides the minutes field.

Do not create another setup screen.

Conceptually:

```text
┌─────────────────────────┐
│ What are you doing?     │
│                         │
│ [____________________]  │
│                         │
│ [ Stopwatch ] [ Timer ] │
│                         │
│ How many minutes?       │
│ [ 25 ]                  │
│                         │
│       Start Task        │
│                         │
│       Quit OnTask       │
└─────────────────────────┘
```

The exact visual layout may evolve, but the experience should remain:

1. obvious,
2. fast,
3. minimal,
4. native-feeling.

Starting a task should require very little interaction.

Do not introduce unnecessary configuration before the task can be started.

---

# 7. Active-Task UI

When a current task exists, the menu should display:

* the full task name,
* displayed time,
* timing state,
* pause/resume control,
* restart control,
* rename/change-task control,
* done/clear control,
* quit control,
* link/button to Settings when needed.

Displayed time means:

* elapsed active time for Stopwatch,
* remaining active time for Timer.

Conceptually:

```text
┌─────────────────────────────┐
│ Finish FastAPI assignment   │
│                             │
│          00:27:14           │
│                             │
│      Pause     Restart      │
│                             │
│      Rename      Done       │
│                             │
│          Quit               │
└─────────────────────────────┘
```

The exact styling is not part of the architecture contract.

Behavior is more important than exact placement.

---

# 8. Settings Architecture

OnTask has a dedicated SwiftUI settings view:

```text
Views/SettingsView.swift
```

`OnTaskApp.swift` should expose it through the SwiftUI Settings scene:

```swift
Settings {
    SettingsView()
}
```

Settings should **not** automatically open when OnTask launches.

Users should be able to open Settings from the menu-bar popup when needed.

Persistent or infrequently changed options should live in Settings rather than making `MenuView` bulky.

Use lightweight persistence such as `@AppStorage` / `UserDefaults` for simple preferences unless requirements later justify something more complex.

Examples of settings that belong in `SettingsView` include:

* focus check-in alerts enabled,
* check-in interval,
* default Timer duration,
* sound preferences,
* calendar sync preferences.

Do not move core timer functionality into `SettingsView`.

---

# 9. Task Semantics

The application may have:

```text
0 current tasks
```

or:

```text
1 current task
```

Never model the MVP as a list of tasks.

Do not introduce:

* task arrays,
* queues,
* backlogs,
* project lists,
* task histories,

unless explicitly requested in a future product change.

The current focus session should conceptually contain enough information to represent:

```text
task text
selected TimingMode
configured Timer duration when applicable
SessionClock state
Timer expiration state when applicable
```

The exact internal representation may vary if a cleaner implementation exists.

---

# 10. Session Lifetime

A focus session exists only while OnTask is running.

Current task and timing state are **in-memory session state**.

The MVP does not persist an active focus session between application launches.

Conceptually:

```text
Launch OnTask
      ↓
New empty FocusSession
      ↓
Set task and choose timing mode
      ↓
Work on task
      ↓
Quit OnTask
      ↓
FocusSession ends
      ↓
Launch OnTask again
      ↓
New empty FocusSession
```

A fresh application launch should begin with:

```text
currentTask = none
TimingMode = default Stopwatch for the next task entry
SessionClock = inactive
expirationState = not expired
```

Do not restore the previous task, timing mode, configured duration, elapsed time, remaining time, or expiration state when the app relaunches.

---

# 11. Starting a Task

Starting a task should:

1. validate that meaningful task text exists,
2. validate Timer minutes if Timer mode is selected,
3. set the task text as the current task,
4. set the selected `TimingMode`,
5. start a fresh `SessionClock`,
6. update the menu bar label.

Whitespace-only task names should not become valid tasks.

Avoid unnecessary validation beyond what is useful for this small app.

---

# 12. Timer Input

Timer mode requires a positive whole number of minutes.

Reject:

* empty input,
* zero,
* negative values,
* non-numeric values.

Keep validation simple.

Do not add advanced duration parsing unless explicitly requested.

---

# 13. TimingMode

`TimingMode` describes how `SessionClock` elapsed time is interpreted.

Conceptually:

```swift
enum TimingMode {
    case stopwatch
    case timer(duration: TimeInterval)
}
```

Exact Swift syntax is not required by this document.

For Stopwatch:

```text
displayedTime = activeElapsedTime
```

For Timer:

```text
displayedTime = max(configuredDuration - activeElapsedTime, 0)
```

This is why both modes can share `SessionClock`.

`TimingMode` should not own low-level timestamp mechanics.

---

# 14. SessionClock

`SessionClock` owns reusable timekeeping mechanics.

Its main question is:

> **How much active time has passed?**

Responsibilities include:

* current run/start timestamp,
* accumulated active elapsed duration,
* running/paused state,
* start,
* pause,
* resume,
* restart,
* elapsed-time calculation.

`SessionClock` does **not** know whether it is being used as a Stopwatch or Timer.

Example:

```text
Start at 2:00
Pause at 2:10
Active elapsed = 10 minutes

Remain paused until 2:30
Active elapsed remains 10 minutes

Resume at 2:30
Current time = 2:35
Active elapsed = 15 minutes
```

Do **not** design the clock around incrementing a permanent counter every second.

Avoid making timekeeping conceptually:

```text
421
422
423
424
425
```

with every UI tick treated as a business-state mutation.

Instead, use timestamps and accumulated active elapsed duration.

Conceptually:

```text
elapsed duration before current run
+
(current time - current run start time)
```

The UI may refresh frequently enough to display a natural time readout.

Reusable timestamp and elapsed-time mechanics belong in `SessionClock`, not duplicated independently in `FocusSession` or `MenuView`.

---

# 15. Stopwatch Behavior

Stopwatch counts upward from zero.

When a task starts in Stopwatch mode:

```text
displayedTime = 00:00
```

Stopwatch supports:

* start,
* pause,
* resume,
* restart.

Restart resets active elapsed time to zero and immediately runs again.

---

# 16. Countdown Timer Behavior

Timer counts downward from the configured duration.

Example:

```text
Configured: 25:00
Active elapsed: 07:00
Displayed remaining: 18:00
```

Conceptually:

```text
remainingTime = max(configuredDuration - activeElapsedTime, 0)
```

Timer supports:

* start,
* pause,
* resume,
* restart.

Remaining time must not decrease while paused.

Timer must never display below:

```text
00:00
```

Restart restores the original configured duration and starts running immediately.

---

# 17. Pause Semantics

When the timing mode is running and the user pauses it:

1. calculate active elapsed time accumulated during the current run,
2. add that duration to previously accumulated active elapsed time,
3. mark the `SessionClock` as paused,
4. stop increasing active elapsed time.

While paused, wall-clock time should not increase active task time.

Example:

```text
8:00 start
8:10 pause

Active elapsed = 10 minutes

8:10-8:30 remains paused

Active elapsed at 8:30 = still 10 minutes
```

For Timer mode, remaining time should stay frozen while paused.

---

# 18. Resume Semantics

Resuming a paused focus session should:

1. preserve already accumulated active elapsed time,
2. record the new resume/start timestamp,
3. mark the `SessionClock` as running,
4. continue accumulating active elapsed time from that point.

Resume must not reset Stopwatch elapsed time or Timer remaining time.

---

# 19. Restart Semantics

Restarting keeps the same current task, resets active elapsed time to zero, and begins timing immediately.

Stopwatch example:

```text
elapsed = 17:00
Restart
→ SessionClock elapsed = 0
→ display = 00:00
→ running
```

25-minute Timer example:

```text
elapsed = 17:00
remaining = 08:00
Restart
→ SessionClock elapsed = 0
→ remaining = 25:00
→ running
```

Restart keeps the same current task.

Restart also stops an active expiration alarm.

Keep restart semantics centralized in `FocusSession`, with elapsed-time mechanics delegated to `SessionClock`.

---

# 20. Timer Expiration

When Timer reaches `00:00`:

* remain at `00:00`,
* mark Timer expired,
* play an audible alarm,
* keep the current task active,
* do not clear the task,
* do not start another Timer,
* do not start a break,
* do not implement Pomodoro.

Expiration must work even when the menu popup is closed.

Timer expiration state belongs to the current focus session, coordinated by `FocusSession`.

Low-level elapsed-time mechanics still belong to `SessionClock`.

---

# 21. AlarmSoundService

`AlarmSoundService` has one narrow responsibility:

* start alarm playback,
* stop alarm playback.

Use native Apple/macOS APIs where reasonable.

Do not add third-party audio dependencies.

The alarm should repeat until stopped.

Restart must:

* stop alarm,
* restore the configured Timer duration,
* begin counting down again.

Done/Clear must also stop the alarm.

Do not put audio implementation in `MenuView`, `FocusSession`, or `SessionClock`.

`FocusSession` may coordinate with `AlarmSoundService`, but the service owns the direct audio behavior.

---

# 22. Renaming a Task

Renaming changes the description of the current task.

It does **not** create a new task session.

Most importantly:

> **Renaming a task must not reset timing state.**

Example:

```text
Before:
"Work on homework"
Displayed time: 18:42

Rename to:
"Finish ICS homework"

After:
"Finish ICS homework"
Displayed time: 18:42
```

Renaming should preserve:

* `TimingMode`,
* configured Timer duration,
* elapsed/remaining displayed time,
* running/paused state,
* accumulated active elapsed duration,
* current run/start timestamp,
* Timer expiration state,
* alarm playback state.

Do not implement rename by clearing the task and creating a new one.

---

# 23. Completing / Clearing a Task

For the MVP, marking the task as done and clearing the current task lead to the same resulting focus state:

```text
No Current Task
```

Clearing/completing should reset:

* task,
* `TimingMode`,
* configured Timer duration,
* `SessionClock`,
* expiration state,
* alarm playback,
* menu bar task text.

After clearing:

```text
currentTask = none
TimingMode = default Stopwatch for the next task entry
SessionClock = inactive
expirationState = not expired
alarmPlayback = stopped
```

Do not retain a task history in the MVP.

---

# 24. Quit Semantics

Quitting OnTask intentionally ends the current application session.

Because current task and timing state are not persisted, quitting while a task exists would destroy that focus session.

Therefore Quit has two behaviors.

## 24.1 Quit With No Current Task

If no current task exists:

```text
User selects Quit
      ↓
OnTask quits immediately
```

No confirmation is necessary.

## 24.2 Quit With an Active Task

If a current task exists, whether its Stopwatch or Timer is running, paused, or expired:

```text
User selects Quit
      ↓
Confirmation required
```

The user must be clearly warned that quitting will lose the current task and timing state.

Conceptually:

```text
┌────────────────────────────────────────┐
│ Quit OnTask?                           │
│                                        │
│ Your current task and timing state     │
│ will be cleared when OnTask quits.     │
│                                        │
│          Cancel        Quit            │
└────────────────────────────────────────┘
```

The exact wording may change, but it must clearly communicate data/session loss.

### Cancel

If the user chooses Cancel:

* do not quit,
* preserve the task,
* preserve `TimingMode`,
* preserve configured Timer duration,
* preserve `SessionClock`,
* preserve expiration state,
* preserve alarm playback state.

### Confirm Quit

If the user confirms:

* terminate OnTask,
* remove its menu bar presence,
* allow all in-memory focus-session state to disappear.

A later application launch begins with a new empty session.

---

# 25. No Persistence in the MVP

The MVP intentionally does **not** persist the active focus session.

Do not persist:

* task,
* timing mode,
* Timer duration,
* elapsed time,
* remaining time,
* paused/running state,
* expiration state,
* alarm playback state.

Do not add:

* `UserDefaults` session storage,
* SwiftData,
* Core Data,
* SQLite,
* files for task-session storage,
* cloud storage,
* remote databases,

for the current task or timing state.

Task and timing information should exist only in application memory while OnTask is running.

Simple user preferences may persist through Settings when explicitly implemented.

This is a deliberate product decision, not a missing feature.

Fresh launch means:

```text
currentTask = none
TimingMode = default Stopwatch for task entry
SessionClock = inactive
expirationState = not expired
```

---

# 26. Architecture Overview

The current application architecture is menu-bar first and AppKit-backed:

```text
OnTaskApp
├── NSStatusItem
│   └── menu-bar icon/task label
├── NSPopover
│   └── NSHostingController
│       └── MenuView
└── SwiftUI Settings scene
    └── SettingsView
```

Do **not** replace this with SwiftUI `MenuBarExtra` unless explicitly requested.

The primary focus-session model architecture is:

```text
                    ┌────────────────┐
                    │  FocusSession  │
                    │    (Model)     │
                    └───────┬────────┘
                         ▲   │ owns/coordinates
                         │   ▼
                    ┌────────────────┐
                    │   TimingMode   │
                    │    (Model)     │
                    └────────────────┘
                         │
                         ▼
                    ┌────────────────┐
                    │  SessionClock  │
                    │    (Model)     │
                    └────────────────┘
                         │
                         ▼
                    ┌────────────────────┐
                    │ AlarmSoundService  │
                    │ service-like Model │
                    └────────────────────┘
```

The primary runtime interaction loop is:

```text
User
  ↓
MenuView
  ↓
FocusSession
  ↓
state changes
  ↓
MenuView reflects new state
  ↓
User
```

`OnTaskApp` sits above this loop and:

* launches the menu-bar application,
* creates the shared `FocusSession`,
* configures `NSStatusItem`,
* configures `NSPopover`,
* hosts `MenuView` in `NSHostingController`,
* exposes `SettingsView` through the SwiftUI Settings scene,
* handles top-level application wiring.

`FocusSession` remains the single source of truth for the current focus session.

Conceptually:

```text
FocusSession
├── current task
├── TimingMode
│   ├── Stopwatch
│   └── Timer(duration)
└── SessionClock
    └── active elapsed time
```

Active session state remains in-memory only. Simple user preferences may be persisted through Settings when explicitly implemented.

---

# 27. Repository / Source Structure

The current intended source structure is approximately:

```text
OnTask/
├── Views/
│   ├── MenuView.swift
│   └── SettingsView.swift
├── Models/
│   ├── FocusSession.swift
│   ├── TimingMode.swift
│   ├── SessionClock.swift
│   └── AlarmSoundService.swift
│   └── FocusAlertService.swift
├── OnTaskApp.swift
└── Assets.xcassets/
```

The current Xcode project safely synchronizes `Models/` and `Views/`.

Do not introduce new top-level folders such as `Services/` if doing so requires unsafe or manual Xcode project-file editing.

Service-like classes may remain under `Models/` for now when that is the safest way to preserve target membership.

Do not add folders merely because they might theoretically be useful someday.

Add new files or directories only when they have an actual responsibility.

---

# 28. File Responsibilities

## `OnTaskApp.swift`

The application entry point.

Responsibilities:

* configure the macOS menu-bar application,
* create shared `FocusSession` state,
* configure `NSStatusItem`, `NSPopover`, and `NSHostingController`,
* connect the root menu UI to that state,
* expose `SettingsView` through the SwiftUI `Settings` scene,
* manage top-level application lifecycle concerns.

Keep this file small.

It should primarily wire components together.

Do not place timing algorithms, task business logic, or alarm audio implementation here.

## `Views/MenuView.swift`

The primary/root UI for the MVP.

Responsibilities include displaying:

* task input when no task exists,
* Stopwatch/Timer selector,
* Timer minutes field when Timer is selected,
* current task,
* displayed Stopwatch elapsed time or Timer remaining time,
* timing controls,
* rename controls,
* done/clear controls,
* quit control,
* quit confirmation UI when appropriate,
* link/button to open Settings when needed.

`MenuView` may collect user input and invoke model behavior.

It should remain focused on active use:

* task entry,
* Stopwatch/Timer selection,
* duration selection,
* start,
* pause/resume,
* end session,
* current elapsed/remaining time,
* access to Settings.

It should not own underlying focus-session rules.

Do not duplicate timing calculations here if they belong in `FocusSession`, `TimingMode`, or `SessionClock`.

Do not play looping alarm audio directly from `MenuView`.

Do not move persistent or infrequently changed configuration into `MenuView` when it belongs in `SettingsView`.

## `Views/SettingsView.swift`

The dedicated SwiftUI settings UI.

Responsibilities include persistent or infrequently changed preferences such as:

* focus check-in alerts enabled,
* check-in interval,
* default Timer duration,
* sound preferences,
* calendar sync preferences.

Settings should not automatically open at launch.

Settings should be reachable from the menu-bar popup when needed.

Do not move core active-session controls or timing behavior into `SettingsView`.

## `Models/FocusSession.swift`

The primary model and single source of truth for the current focus session.

Responsibilities include state and behavior related to:

* current task,
* selected `TimingMode`,
* configured Timer duration,
* the current `SessionClock`,
* timer expiration state,
* starting a session,
* pause/resume/restart semantics,
* rename,
* clear/complete,
* coordination with alarm behavior.

`FocusSession` should use `SessionClock` rather than duplicating timestamp and elapsed-time algorithms.

Example:

```text
User presses Pause
        ↓
MenuView receives click
        ↓
FocusSession.pause()
        ↓
SessionClock records accumulated active elapsed time
        ↓
FocusSession publishes updated state
        ↓
MenuView reflects the updated state
```

Do not make `MenuView` independently implement pause logic.

## `Models/TimingMode.swift`

Describes whether the current focus session uses Stopwatch or Timer behavior.

Responsibilities include:

* representing Stopwatch mode,
* representing Timer mode with a configured duration,
* interpreting `SessionClock` active elapsed time for display.

It should not own task text, run timestamps, pause/resume state, or alarm playback.

## `Models/SessionClock.swift`

Owns reusable active-time mechanics.

Responsibilities include:

* start timestamp,
* accumulated active elapsed duration,
* running/paused state,
* start,
* pause,
* resume,
* restart,
* active elapsed-time calculation.

It should not know whether elapsed time is displayed upward as Stopwatch time or downward as Timer remaining time.

## `Models/AlarmSoundService.swift`

Owns direct alarm playback behavior.

Responsibilities include:

* start repeating alarm playback,
* stop alarm playback.

It should not own task state, timing mode, elapsed-time math, or menu UI.

## `Assets.xcassets/`

Stores application visual assets such as:

* app icon,
* menu-bar icon,
* colors,
* images,
* alarm audio assets if native resource storage is needed.

Do not place Swift source code in the asset catalog.

---

# 29. Views vs Models and Service-Like Types

Use these definitions consistently.

## Views

Views answer:

> **What does the user see and interact with?**

Examples:

* labels,
* text fields,
* Stopwatch/Timer buttons,
* minutes field,
* displayed time,
* controls,
* menu sections,
* formatting,
* layout,
* alerts and confirmations,
* Settings controls.

Views may detect an event such as a click.

Views should delegate the meaning of task and timing actions to the model.

`SettingsView` may read/write simple persisted preferences, but it should not own active focus-session state.

## Models

Models answer:

> **What does the application know, and what are the rules around that state?**

Examples:

```text
current task
selected TimingMode
configured Timer duration
active elapsed time
is the clock paused?
when was the clock resumed?
what does restart mean?
what happens when a task is cleared?
has the Timer expired?
```

Models own application state and state transitions.

## Service-Like Types

Service-like types answer:

> **How does the app interact with a narrow operating-system or external facility?**

Current and planned examples include:

```text
AlarmSoundService
FocusAlertService
CalendarService
```

Given current Xcode folder constraints, these may live under `Models/` for now.

Do not introduce broad service layers or manager objects.

---

# 30. Root UI Philosophy

`MenuView` is the root/master UI container for active focus use.

`SettingsView` is a dedicated settings surface, not a replacement main app UI.

For the MVP there is no need for:

```text
MainView.swift
FocusView.swift
```

because focus functionality is currently the entire menu-bar popup.

Do not create additional UI abstraction merely for symmetry.

If the UI eventually becomes complex enough to justify separate feature views, `MenuView` may compose them.

Current:

```text
MenuView
└── MVP focus UI
```

Potentially later:

```text
MenuView
├── FocusView
├── another feature view
└── another feature view
```

Do not build those future modules until explicitly requested.

---

# 31. No Master Model for the MVP

Do not introduce a generic:

```text
MainView
MasterModel
AppModel
AppState
RootModel
ViewModels everywhere
repository layers
feature-module folders
```

for the current MVP unless an actual coordination problem requires it.

Currently:

```text
MenuView
    ↕
FocusSession
```

is sufficient.

Avoid unnecessary layers such as:

```text
MenuView
    ↓
AppModel
    ↓
FocusSession
```

when `AppModel` provides no meaningful behavior.

If multiple independent feature models eventually require coordination, a coordinator may be introduced then.

Do not preemptively build it.

---

# 32. Extensibility Philosophy

The architecture should remain easy to extend without implementing extensions prematurely.

Potential future concepts may include:

* Pomodoro functionality,
* macOS notifications,
* launch-at-login,
* calendar connections,
* task-management integrations,
* other application integrations.

These are **not part of the MVP** unless explicitly requested.

Current code should avoid unnecessarily preventing such additions.

The correct approach is:

> **Build clean boundaries now, not unused future infrastructure.**

Good:

```text
MenuView ↔ FocusSession
FocusSession → TimingMode
FocusSession → SessionClock
FocusSession → AlarmSoundService
```

because the UI, focus-session rules, reusable clock mechanics, and alarm playback each have clear responsibilities.

Bad:

```text
MenuView.swift

contains UI
contains timestamp algorithms
contains countdown expiration rules
contains looping audio implementation
contains integrations
contains system services
contains everything
```

---

# 33. Integration Philosophy

If OnTask later communicates with external applications or services, that integration should generally not be embedded directly in `MenuView`, `FocusSession`, `TimingMode`, or `SessionClock`.

A future integration might conceptually look like:

```text
External Service
      ↓
Integration / Service
      ↓
Application Model or FocusSession coordination
      ↓
View
```

Do not implement integrations unless explicitly requested.

`AlarmSoundService` is allowed because Timer expiration creates a narrow native audio responsibility.

---

# 34. Focus Check-In Alerts

OnTask should support optional alerts every X minutes during an active focus session.

The goal is to:

* remind the user what they are currently working on,
* ask whether they are still on task,
* help interrupt accidental distraction or zoning out.

The enable/disable preference and interval should live in `SettingsView` and persist with lightweight storage such as `@AppStorage` / `UserDefaults`.

When implemented, prefer a small dedicated type such as:

```text
FocusAlertService.swift
```

Do not put notification scheduling logic directly into `MenuView`.

Given current Xcode folder constraints, `FocusAlertService.swift` may live under `Models/`.

Do not implement focus check-in alerts unless explicitly requested.

---

# 35. Future Calendar Integration

OnTask should eventually support optionally adding completed focus sessions to the user's Apple Calendar.

The goal is for focused time to appear alongside the user's existing schedule.

Prefer native macOS calendar integration through EventKit/system calendars initially. This can include Google calendars already configured on the Mac.

Avoid building an OnTask-specific calendar/history UI unless explicitly requested.

`FocusSession` should remain a clean representation of a completed focus session and should be usable by future calendar integration.

A future dedicated type may own EventKit/calendar interaction:

```text
CalendarService.swift
```

Given current Xcode folder constraints, `CalendarService.swift` may live under `Models/`.

Do not implement calendar integration unless explicitly requested.

---

# 36. Pomodoro Extensibility

Do not add Pomodoro functionality in the MVP.

Do not implement:

* work/break cycles,
* automatic breaks,
* cycle counts,
* Pomodoro settings,
* Pomodoro history,
* `PomodoroSession.swift`.

If Pomodoro is added later, it should not require rewriting the core focus-session architecture.

`SessionClock` should be reusable enough that a future Pomodoro feature could use the same active-time mechanics.

Do not combine hypothetical Pomodoro behavior into `FocusSession` now.

---

# 37. UI Design Principles

OnTask should feel:

* native to macOS,
* minimal,
* calm,
* lightweight,
* unobtrusive,
* fast.

Avoid:

* large permanent windows,
* excessive animation,
* unnecessary colors,
* visual clutter,
* dashboards,
* complicated navigation,
* multiple steps to set a task.

The application exists to reduce distraction.

Its own UI should therefore demand as little attention as reasonably possible.

---

# 38. Menu-Bar Design Principles

Menu-bar space is scarce.

Therefore:

* keep labels short,
* truncate long task names,
* avoid displaying unnecessary status text,
* do not permanently display elapsed or remaining time in the menu-bar label unless explicitly requested,
* avoid menu-bar UI that expands significantly.

The menu bar's main job is:

> **Keep the current task visible.**

Detailed timing information belongs inside the menu.

---

# 39. Native macOS First

Prefer native Apple APIs and SwiftUI where reasonable.

Primary technology:

```text
Swift
SwiftUI
macOS APIs
```

Use AppKit only when necessary to accomplish behavior that SwiftUI does not cleanly provide.

Use native Apple/macOS audio APIs for alarm playback where reasonable.

Do not introduce:

* Electron,
* React,
* web views,
* Node.js,
* Python runtimes,
* backend frameworks,

for functionality that can be implemented cleanly with the native macOS stack.

---

# 40. Dependencies

Prefer standard Apple frameworks.

Do not add third-party dependencies unless:

1. the task explicitly requires one, or
2. implementing the behavior natively would be disproportionately difficult.

If considering a new dependency:

* explain why it is needed,
* prefer maintained and narrow dependencies,
* avoid dependencies for trivial functionality.

For the MVP, the expected third-party dependency count is:

```text
0
```

---

# 41. State Ownership Rule

One of the most important architectural rules:

> **There should be one source of truth for focus-session state.**

That source should be `FocusSession`.

Avoid duplicated state such as:

```text
MenuView.currentTask
FocusSession.currentTask
OnTaskApp.currentTask
```

where each can independently diverge.

Prefer:

```text
FocusSession.currentTask
FocusSession.timingMode
FocusSession.sessionClock
```

with other components reading or presenting that state.

`SessionClock` may own reusable clock mechanics, but it is part of the focus-session model graph coordinated by `FocusSession`.

---

# 42. Keep Views Thin

A view may:

* display state,
* format state for presentation,
* collect user input,
* call model actions,
* show confirmation UI.

A view should generally not:

* calculate session semantics,
* implement active-time algorithms,
* independently calculate countdown expiration,
* decide how restart works,
* decide how pause accumulation works,
* play looping alarm audio directly.

If logic becomes difficult to describe as purely UI behavior, it likely belongs elsewhere.

---

# 43. Keep Models Focused

`FocusSession` should represent focus-session behavior.

Do not turn it into a universal dumping ground.

It should not eventually become responsible for:

* Google authentication,
* notification permissions,
* arbitrary integrations,
* unrelated settings,
* menu layout,
* app icons,
* direct audio playback implementation.

When a responsibility is genuinely different, introduce an appropriate component when there is an actual requirement.

For Timer expiration alarm playback, that component is `AlarmSoundService`.

# 44. Quit Confirmation Responsibility

The decision about whether quitting would destroy an active session depends on focus-session state.

The application should determine:

```text
Does a current task exist?
```

If no:

```text
Quit immediately
```

If yes:

```text
Ask for confirmation
```

Quit confirmation is a UI responsibility.

If a current task exists, show a confirmation dialog before terminating the app.

Do not save or restore the session as part of this flow; the confirmation exists only to prevent accidental loss of the current in-memory task and timing state.

---

# 45. Error Handling Philosophy

This is a small local application.

Error handling should be proportional to the risk.

Avoid unnecessary complexity.

Important failures should:

* fail safely,
* avoid inconsistent state,
* avoid crashing where reasonably possible.

Do not introduce large error-management frameworks for the MVP.

Timer input validation should stay simple and user-facing.

Alarm playback failure should not corrupt task or timing state.

---

# 46. Naming

Prefer descriptive names.

Good examples:

```text
FocusSession
TimingMode
SessionClock
AlarmSoundService
elapsedTime
remainingTime
isPaused
resume()
restart()
clearTask()
renameTask()
```

Avoid vague names such as:

```text
Manager
Handler
Thing
Data
Helper
Utils
Master
```

unless the responsibility is genuinely clear from context.

Use Swift naming conventions.

---

# 47. Code Readability

Optimize for code that a developer relatively new to Swift can follow.

Prefer:

* straightforward Swift,
* clear names,
* small functions,
* explicit responsibilities,
* comments explaining non-obvious reasoning.

Avoid clever abstractions for their own sake.

Do not compress understandable logic into difficult one-liners merely to reduce line count.

---

# 48. Comments

Comments should explain **why**, especially when behavior is not obvious.

Good:

```swift
// Store accumulated elapsed time when pausing so wall-clock time
// during the paused period does not count toward the session.
```

Less useful:

```swift
// Set isPaused to true
isPaused = true
```

Do not over-comment self-explanatory Swift syntax.

---

# 49. Incremental Development Rule

This repository should be developed incrementally.

When given a small implementation request:

> **Implement only the requested increment.**

Do not automatically continue into later milestones.

For example, if asked:

> Add `TimingMode`.

Do not also implement:

* alarm audio,
* Pomodoro,
* integrations,
* storage,
* unrelated UI redesigns.

Small commits and understandable milestones are preferred.

---

# 50. Before Editing

Before making meaningful changes:

1. read `README.md`,
2. read `AGENTS.md`,
3. inspect relevant existing source files,
4. understand the current architecture,
5. preserve existing working behavior unless the task requires changing it.

Do not assume the repository still exactly matches an earlier prompt.

The repository is the current source of truth for implementation state.

---

# 51. Existing Code First

Before creating a new abstraction:

* inspect whether an appropriate type already exists,
* extend existing responsibilities when appropriate,
* avoid duplicate implementations.

Do not create multiple objects representing the same concept, such as:

```text
StopwatchManager
TimerManager
TimerFactory
ClockStrategyFactory
SessionTimer
```

Keep the architecture coherent.

The intended timing refactor is limited to:

```text
TimingMode
SessionClock
AlarmSoundService
```

Do not introduce a master model above `FocusSession`.

---

# 52. Changes to Project Structure

Do not reorganize the project casually.

The intended MVP baseline is:

```text
Views/
Models/
```

plus:

```text
OnTaskApp.swift
Assets.xcassets/
```

If a new folder is justified by actual code and can be added safely through Xcode, it may be introduced.

Do not add empty folders for hypothetical future use.

Do not introduce a new top-level `Services/` folder if doing so requires unsafe or manual `.pbxproj` editing while Xcode is open.

When moving Swift files, preserve Xcode project references and ensure the project builds.

---

# 53. Build Validation

After implementation changes, build the app.

At minimum, ensure the project compiles successfully.

The Xcode project is:

```text
OnTask.xcodeproj
```

The expected scheme is:

```text
OnTask
```

When command-line validation is appropriate, a command similar to the following may be used:

```bash
xcodebuild \
  -project OnTask.xcodeproj \
  -scheme OnTask \
  -configuration Debug \
  build
```

If repository configuration differs, inspect the project rather than blindly assuming command arguments.

Fix compilation errors introduced by the change before considering the task complete.

Documentation-only changes do not require a build unless the prompt explicitly asks for one.

---

# 54. Runtime Validation

For UI behavior, compilation alone is insufficient.

When feasible, verify the relevant behavior in the running macOS application.

Examples:

* menu-bar item appears,
* no-task state displays correctly,
* task can be entered,
* task label updates,
* Stopwatch is selected by default,
* Timer reveals minutes input,
* Stopwatch hides minutes input,
* invalid Timer input is rejected,
* Stopwatch starts at `00:00`,
* Stopwatch counts up,
* Timer starts at configured duration,
* Timer counts down,
* pause freezes Stopwatch elapsed time,
* pause freezes Timer remaining time,
* resume continues from prior active elapsed time,
* restart resets Stopwatch display to `00:00`,
* restart restores Timer to original configured duration,
* Timer stops at `00:00`,
* Timer never goes negative,
* alarm plays on Timer expiration,
* expiration works with popup closed,
* restart stops alarm,
* Done/Clear stops alarm,
* rename preserves timing state,
* clear returns to icon-only state,
* Quit with no task exits immediately,
* Quit with an active Stopwatch requires confirmation,
* Quit with running, paused, or expired Timer requires confirmation,
* Cancel on the quit confirmation preserves the session,
* confirmed Quit removes the menu-bar presence,
* relaunch starts with an empty focus session.

Only validate behavior relevant to the current implementation stage.

---

# 55. Testing Philosophy

Prefer tests for behavior with meaningful logic, especially timing state transitions.

Potential model-level scenarios include:

```text
start Stopwatch → running
start Timer with valid duration → running
start Timer with invalid duration → rejected
running → pause
pause → resume
running Stopwatch → restart
running Timer → restart
paused Timer → restart
Timer elapsed calculation clamps remaining time at 00:00
Timer expiration state is set once remaining time reaches 00:00
rename preserves TimingMode and SessionClock state
clear removes task and resets timing state
Done/Clear stops alarm coordination
```

Do not create excessive testing infrastructure before there is meaningful logic to test.

Timing logic should be structured so it can be tested without requiring the actual UI.

Where useful, avoid hard dependencies on `Date.now` throughout business logic if doing so makes deterministic timing tests difficult.

Do not overengineer testability prematurely, but keep deterministic logic in mind.

---

# 56. Source Control

Do not remove or rewrite repository-level project files without need.

Files expected to remain tracked include:

```text
README.md
AGENTS.md
.gitignore
OnTask.xcodeproj/
OnTask/
```

Generated/user-specific files should remain excluded according to `.gitignore`.

Do not commit:

* `.DS_Store`,
* `DerivedData`,
* user-specific Xcode state,
* build output,
* secrets.

---

# 57. Privacy

OnTask's MVP is local and session-based.

Task text and timing state exist only inside the running application process.

Do not:

* transmit task text,
* add analytics,
* add telemetry,
* call external services,
* introduce tracking,

unless explicitly required by a future product decision.

No user account is required.

---

# 58. Security

The MVP handles low-risk local productivity data.

Still follow basic safety principles:

* do not log sensitive task text unnecessarily,
* do not introduce network access without a product requirement,
* do not store secrets because the MVP has no need for them,
* do not request unnecessary macOS permissions.

Use the minimum system privileges required.

Alarm playback should use normal local audio capabilities and should not require extra permissions beyond what native playback requires.

---

# 59. Performance

OnTask should be lightweight.

It spends most of its time idle in the menu bar.

Avoid:

* aggressive polling,
* unnecessary background processing,
* unnecessary networking,
* unnecessary CPU work.

A visible Stopwatch or Timer may refresh frequently enough for a natural display, but the underlying architecture should remain efficient.

Timer expiration must still work when the menu popup is closed, so any background timing check should be proportional and lightweight.

---

# 60. Accessibility

Use standard SwiftUI controls where possible.

Do not sacrifice accessibility for custom visuals.

Buttons and icons should have understandable labels where appropriate.

The application should remain usable without relying solely on ambiguous iconography.

The Stopwatch/Timer selector should be understandable to VoiceOver users.

The Timer minutes field should have a clear label.

Confirmation dialogs should clearly identify the destructive action.

---

# 61. Avoid Premature Features

Do not independently add:

* Pomodoro,
* work/break cycles,
* automatic breaks,
* task history,
* productivity scores,
* analytics,
* streaks,
* achievements,
* tags,
* subtasks,
* projects,
* reminders,
* notifications,
* calendar integrations,
* website blocking,
* application blocking,
* AI features,
* cloud synchronization,
* account systems,
* onboarding flows,
* settings dashboards,
* focus-session persistence.

Even if such a feature seems useful, it is outside the current MVP unless explicitly requested.

---

# 62. Avoid Premature Infrastructure

Do not independently introduce:

```text
backend services
REST APIs
GraphQL
SQLite
SwiftData
Core Data
UserDefaults session persistence
PostgreSQL
cloud storage
authentication
dependency injection frameworks
large coordinator hierarchies
complex repositories/data-source layers
```

The current architecture does not require them.

Introduce infrastructure only when an actual requirement creates the need.

`SessionClock`, `TimingMode`, and `AlarmSoundService` are narrow product-driven abstractions for the Timer feature, not permission to create broad infrastructure.

---

# 63. Do Not One-Shot the Project

Even though the overall MVP is documented here, do not interpret this document as an instruction to implement everything at once.

If the current prompt asks only for:

```text
Refactor Stopwatch logic into SessionClock
```

implement only that.

If a later prompt asks for:

```text
Add Timer expiration alarm
```

implement that separately.

The purpose of this document is to ensure each incremental change fits the same architecture.

---

# 64. Current MVP Development Status

The following core behaviors have already been implemented or are considered part of the established MVP design:

```text
1. Native AppKit menu-bar application shell
2. NSStatusItem / NSPopover / NSHostingController menu-bar popup
3. MenuView active focus-session UI
4. SettingsView exposed through the SwiftUI Settings scene
5. FocusSession task state
6. Set / display current task
7. Clear / complete current task
8. Stopwatch timing
9. Countdown Timer timing
10. TimingMode
11. SessionClock shared timing mechanics
12. AlarmSoundService for Timer completion sound
13. Pause / resume
14. Restart
15. Rename
16. Time visibility control
```

Do not reimplement working functionality unnecessarily.

The following work is planned direction and should not be marked as implemented until confirmed in the repository:

```text
1. Persistent Settings options beyond any current basics
2. Focus check-in alerts
3. FocusAlertService
4. Optional calendar sync for completed sessions
5. CalendarService
```

Active focus-session persistence remains intentionally out of scope.

---

# 65. Incremental Future Development Path

Future work should be implemented in small, reviewable steps.

Reasonable future increments include:

1. Add Settings controls for a specific preference.
2. Persist that preference with `@AppStorage` / `UserDefaults`.
3. Add focus check-in alert scheduling behind a persisted enable/interval preference.
4. Extract `FocusAlertService` only when check-in scheduling is implemented.
5. Add optional calendar export for completed sessions.
6. Extract `CalendarService` only when EventKit/calendar interaction is implemented.
7. Test and polish the requested increment.

Do **not** implement these steps merely because they are documented here.

Only implement the step explicitly requested by the current prompt.

---

# 66. Architecture Decision Rule

When unsure where code belongs, ask:

### Is this about what the user sees?

Put it in:

```text
Views/
```

### Is this about task/timing state or focus-session behavior?

Put it in:

```text
Models/
```

### Is this about narrow interaction with macOS or external facilities?

Put it in:

```text
Models/ for now, unless the project safely supports another synchronized folder
```

### Is this about application startup and top-level wiring?

Put it in:

```text
OnTaskApp.swift
```

Examples:

```text
Menu layout                       → MenuView
Stopwatch/Timer selector UI       → MenuView
Timer minutes text field          → MenuView
Current task text                 → FocusSession
TimingMode                        → TimingMode
Elapsed active-time calculation   → SessionClock
Countdown remaining-time display  → TimingMode / FocusSession coordination
Timer expiration state            → FocusSession
Alarm audio playback              → AlarmSoundService under Models/ for now
Settings UI                       → SettingsView
Simple persisted preference       → SettingsView / @AppStorage
Focus check-in scheduling         → FocusAlertService under Models/ for now
Calendar/EventKit interaction     → future CalendarService under Models/ for now
Menu-bar label wiring             → OnTaskApp
```

---

# 67. Example Event Flow: Pause

A correct pause flow looks like:

```text
User clicks Pause
      ↓
MenuView invokes FocusSession.pause()
      ↓
FocusSession delegates active-time mechanics to SessionClock
      ↓
SessionClock stores accumulated active elapsed time
      ↓
FocusSession publishes updated state
      ↓
MenuView reflects paused state
```

`MenuView` should not calculate what pause means.

---

# 68. Example Event Flow: Timer Expiration

A correct Timer expiration flow looks like:

```text
SessionClock reports active elapsed time
      ↓
FocusSession interprets elapsed time through TimingMode.timer(duration)
      ↓
remainingTime reaches 00:00
      ↓
FocusSession marks Timer expired
      ↓
FocusSession coordinates AlarmSoundService.startAlarm()
      ↓
MenuView reflects expired Timer when opened
```

Expiration should not require the menu popup to be open.

Expiration should not clear the task or start Pomodoro behavior.

---

# 69. Example Event Flow: Quit

A correct quit flow looks like:

```text
User clicks Quit
      ↓
MenuView checks whether FocusSession has a current task
      ↓
No task: terminate immediately
Task exists: show confirmation
      ↓
Cancel: preserve FocusSession unchanged
Confirm: terminate application
```

Quit confirmation is temporary UI state, not focus-session state.

---

# 70. Central Engineering Principle

The central rule for OnTask is:

> **Keep the app small, native, and focused on one current task.**

That means:

* one current task,
* one `FocusSession`,
* one selected `TimingMode` per session,
* one reusable `SessionClock` for active-time mechanics,
* one narrow `AlarmSoundService` for alarm playback,
* Settings for persistent or infrequently changed preferences,
* no task lists,
* no active focus-session persistence,
* no Pomodoro until explicitly requested,
* no broad infrastructure without a concrete requirement.

---

# 71. Definition of a Good Change

A good change in this repository:

* implements only the requested increment,
* keeps state ownership clear,
* preserves existing behavior unless intentionally changed,
* uses native macOS/SwiftUI APIs where practical,
* avoids third-party dependencies,
* avoids active-session persistence unless explicitly requested,
* uses lightweight preference persistence only when the requested feature needs it,
* leaves the app lightweight and easy to understand,
* builds successfully when code changes are made.
