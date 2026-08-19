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

**OnTask** is a native macOS menu bar application that keeps the user's current task visible while they work.

The core problem OnTask solves is simple:

> What am I supposed to be doing right now?

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

Use the asset system or a centralized configuration where appropriate.

### Current Task Exists

When a task is active:

* the menu bar should display the current task,
* the task should remain visible while the user works in other applications,
* the menu bar label must remain short enough not to consume excessive menu bar space.

Task text should be truncated when necessary.

The exact limit should be centralized rather than hard-coded throughout the UI.

Target approximately **5-20 visible characters** for the menu bar representation.

The full task name must remain available inside the menu.

Example:

```text
Finish database assign...
```

Do not let very long task names consume excessive menu bar width.

---

# 5. Menu Behavior

Clicking the OnTask menu bar item opens the application's menu interface.

The MVP menu is the application's primary interface.

The main MVP UI belongs in:

```text
Views/MenuView.swift
```

Do not create unnecessary additional views until the UI is complicated enough to justify them.

For the current MVP, `MenuView` may contain the complete OnTask interface.

---

# 6. No-Task UI

When there is no current task, `MenuView` should provide a minimal interface for creating one.

Conceptually:

```text
┌─────────────────────────┐
│ What are you doing?     │
│                         │
│ [____________________]  │
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
* elapsed task time,
* timer state,
* pause/resume control,
* restart control,
* rename/change-task control,
* done/clear control,
* quit control.

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

# 8. Task Semantics

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

The current task should conceptually contain enough information to represent:

```text
task text
timer state
start/resume timestamps
previously accumulated elapsed time
```

The exact internal representation may vary if a cleaner implementation exists.

---

# 9. Starting a Task

Starting a task should:

1. validate that meaningful task text exists,
2. set that text as the current task,
3. begin the task stopwatch,
4. update the menu bar label,
5. persist the appropriate state.

Whitespace-only task names should not become valid tasks.

Avoid unnecessary validation beyond what is useful for this small app.

---

# 10. Renaming a Task

Renaming changes the description of the current task.

It does **not** create a new task session.

Most importantly:

> **Renaming a task must not reset its stopwatch.**

Example:

```text
Before:
"Work on homework"
Elapsed: 18:42

Rename to:
"Finish ICS homework"

After:
"Finish ICS homework"
Elapsed: 18:42
```

Do not implement rename by clearing the task and creating a new one if doing so resets session state.

---

# 11. Completing / Clearing a Task

For the MVP, marking the task as done and clearing the current task lead to the same resulting focus state:

```text
No Current Task
```

Clearing/completing should:

1. remove the current task,
2. reset timer state,
3. reset accumulated elapsed time,
4. remove task text from the menu bar,
5. return the menu bar to the icon-only state,
6. persist the cleared state.

Do not retain a task history in the MVP.

After clearing:

```text
currentTask = none
elapsedTime = 0
timer = inactive
```

---

# 12. Stopwatch Requirements

Each active task has a stopwatch.

The stopwatch must support:

* start,
* pause,
* resume,
* restart.

The stopwatch measures how long the current focus session has been active.

---

# 13. Stopwatch Architecture

Do **not** design the stopwatch around persistently incrementing and saving a counter every second.

Avoid this conceptual model:

```text
421
422
423
424
425
```

with every tick treated as persisted application state.

Instead, use timestamps and accumulated elapsed duration.

A conceptual model is:

```text
elapsed duration before current run
+
(current time - current run start time)
```

For example:

```text
Task resumed at: 10:00:00
Current time:    10:07:32

Current run duration = 7m 32s
```

If 12 minutes had already accumulated before the resume:

```text
12:00 + 7:32 = 19:32
```

The UI may refresh frequently to display the stopwatch.

Frequent UI refreshes should not require frequent persistence writes.

---

# 14. Pause Semantics

When the stopwatch is running and the user pauses it:

1. calculate elapsed time accumulated during the current run,
2. add that duration to previously accumulated elapsed time,
3. mark the stopwatch as paused,
4. stop increasing displayed elapsed time,
5. persist the meaningful state change.

While paused, wall-clock time should not increase task elapsed time.

Example:

```text
8:00 start
8:10 pause

Elapsed = 10 minutes

8:10–8:30 remains paused

Elapsed at 8:30 = still 10 minutes
```

---

# 15. Resume Semantics

Resuming a paused task should:

1. preserve already accumulated elapsed time,
2. record the new resume/start timestamp,
3. mark the stopwatch as running,
4. continue accumulating from that point.

Resume must not reset elapsed time.

---

# 16. Restart Semantics

Restarting the stopwatch means:

> Keep the same current task, but reset its elapsed time to zero.

Example:

```text
Task:
"Write README"

Elapsed:
31:14
```

After restart:

```text
Task:
"Write README"

Elapsed:
00:00
```

The task itself remains active.

If the timer was running before restart, restarting should result in a fresh running timer unless existing UI semantics explicitly specify otherwise.

Keep restart logic centralized in the model.

---

# 17. Quit Semantics

Selecting Quit should terminate OnTask normally.

When OnTask quits:

* its menu bar icon/text disappears because the application is no longer running.

Do not leave a separate floating UI element behind.

Persist enough meaningful state before termination to allow the application to restore its previous state when reopened.

---

# 18. Persistence Behavior

OnTask stores application state locally on the user's Mac.

The MVP does not require:

* a backend,
* networking,
* authentication,
* user accounts,
* cloud storage,
* remote databases,
* analytics infrastructure.

Use lightweight local persistence.

The preferred MVP mechanism is:

```text
UserDefaults
```

unless an implementation constraint clearly makes another built-in local mechanism more appropriate.

---

# 19. Persistence Responsibilities

Persistence logic belongs behind:

```text
Services/PersistenceService.swift
```

Views should **not** interact with `UserDefaults` directly.

Avoid:

```text
MenuView
    ↓
UserDefaults.standard...
```

Prefer:

```text
MenuView
    ↓
FocusSession
    ↓
PersistenceService
    ↓
UserDefaults
```

This keeps storage details separate from UI behavior.

---

# 20. What Should Be Persisted

Persist enough state to accurately restore the current task session.

That will likely include information equivalent to:

```text
task text
timer state
current run start/resume timestamp
previous accumulated elapsed time
```

The exact stored keys or encoded representation are implementation details.

Keep persistence representation cohesive and easy to evolve.

Avoid storing values that can be safely derived from other persisted state.

---

# 21. App Restart Behavior

When OnTask launches:

```text
OnTaskApp
    ↓
load persisted state
    ↓
restore FocusSession
    ↓
render correct menu-bar state
```

If no task existed:

```text
icon-only menu state
```

If a task existed:

```text
task menu state
```

If the task was paused:

```text
restore paused task
restore accumulated duration
do not count time while app was closed
```

If the task was running when the app was closed:

* preserve timestamp-based semantics,
* elapsed time may continue based on the running task's timestamps when restored.

Avoid implementations that require the process to stay alive for time measurement to remain accurate.

---

# 22. Architecture Overview

                         OnTaskApp
                            │
                            ▼
                    ┌────────────────┐
                    │  FocusSession  │
                    │    (Model)     │
                    └───────┬────────┘
                         ▲   │
         reads state /   │   │ save / load
        invokes actions  │   ▼
                         │  ┌─────────────────────┐
                         │  │ PersistenceService  │
                         │  └──────────┬──────────┘
                         │             ▼
                    ┌────┴─────┐  UserDefaults
                    │ MenuView │
                    │  (View)  │
                    └────┬─────┘
                         ↕
                        User

MenuView and FocusSession form the application's continuous interaction loop. PersistenceService is a supporting service used by the model to save and restore meaningful state; it is not the terminal step of every user interaction.

---

# 23. Repository / Source Structure

The intended MVP source structure is:

```text
OnTask/
├── Views/
│   └── MenuView.swift
│
├── Models/
│   └── FocusSession.swift
│
├── Services/
│   └── PersistenceService.swift
│
├── OnTaskApp.swift
└── Assets.xcassets/
```

Do not add folders merely because they might theoretically be useful someday.

Add new files or directories only when they have an actual responsibility.

---

# 24. File Responsibilities

## `OnTaskApp.swift`

The application entry point.

Responsibilities:

* configure the macOS menu-bar application,
* initialize shared application state,
* restore persisted focus state,
* connect the root menu UI to that state,
* manage top-level application lifecycle concerns.

Keep this file small.

It should primarily wire components together.

Do not place stopwatch algorithms or task business logic here.

---

## `Views/MenuView.swift`

The primary/root UI for the MVP.

Responsibilities include displaying:

* task input when no task exists,
* current task,
* elapsed stopwatch time,
* timer controls,
* rename controls,
* done/clear controls,
* quit control.

`MenuView` may coordinate presentation of feature UI.

It should not own the underlying business rules.

Do not place persistence implementation here.

Do not duplicate timer calculations here if they belong in `FocusSession`.

---

## `Models/FocusSession.swift`

The primary model and source of truth for the current focus session.

Responsibilities include state and behavior related to:

* current task,
* active/inactive task state,
* timer running/paused state,
* accumulated duration,
* task start/resume timestamps,
* start,
* pause,
* resume,
* restart,
* rename,
* clear/complete.

This model owns the meaning of user actions.

Example:

```text
User presses Pause
        ↓
MenuView receives click
        ↓
FocusSession.pause()
        ↓
FocusSession calculates and updates state
```

Do not make `MenuView` independently implement pause logic.

---

## `Services/PersistenceService.swift`

Responsible for storing and restoring local application state.

Responsibilities:

* abstract `UserDefaults`,
* save meaningful focus session state,
* load saved focus session state,
* clear persisted focus state when appropriate.

UI code should not care how persistence is implemented.

---

## `Assets.xcassets/`

Stores application visual assets such as:

* app icon,
* menu-bar icon,
* colors,
* images.

Do not place Swift source code in the asset catalog.

---

# 25. Views vs Models vs Services

Use these definitions consistently.

## Views

Views answer:

> What does the user see?

Examples:

* labels,
* text fields,
* buttons,
* menu sections,
* formatting,
* layout.

Views may detect a user event such as a click.

Views should delegate the meaning of that event to the appropriate model.

---

## Models

Models answer:

> What does the application know, and what are the rules around that state?

Examples:

```text
current task
is timer paused?
when was the timer resumed?
how much elapsed time has accumulated?
what does "restart" mean?
```

Models own application behavior and state transitions.

---

## Services

Services answer:

> How does the application interact with storage, macOS facilities, or external systems?

For the MVP:

```text
PersistenceService
```

handles local storage.

Views should generally not interact directly with external systems.

---

# 26. Root UI Philosophy

`MenuView` is the root/master UI container.

For the MVP there is no need for:

```text
FocusView.swift
```

because focus functionality is currently the entire menu.

Do not create additional UI abstraction merely for symmetry.

If the UI eventually becomes complex enough to justify separate feature views, `MenuView` may compose them.

Conceptually:

```text
MenuView
├── current MVP focus UI
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

# 27. No Master Model for the MVP

Do not introduce a generic:

```text
MasterModel
AppModel
RootModel
```

for the current MVP unless an actual coordination problem requires it.

Currently:

```text
MenuView
    ↓
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

# 28. Extensibility Philosophy

The architecture should remain easy to extend without implementing extensions prematurely.

Potential future concepts may include things such as:

* Pomodoro functionality,
* macOS notifications,
* launch-at-login,
* calendar connections,
* task-management integrations,
* other application integrations.

These are **not part of the MVP** unless explicitly requested.

However, current code should avoid unnecessarily preventing such additions.

The correct approach is:

> Build clean boundaries now, not unused future infrastructure.

For example:

Good:

```text
MenuView → FocusSession → PersistenceService
```

because components have clear responsibilities.

Bad:

```text
MenuView.swift
contains UI
contains timer algorithm
contains storage
contains integration code
contains everything
```

---

# 29. Integration Philosophy

If OnTask later communicates with external applications or services, that integration should generally not be embedded directly in `MenuView` or `FocusSession`.

A future integration might conceptually look like:

```text
External Service
      ↓
Integration / Service
      ↓
Application Model
      ↓
View
```

Do not implement integrations unless explicitly requested.

---

# 30. Pomodoro Extensibility

Do not add Pomodoro functionality in the MVP.

If Pomodoro is added later, it should not require rewriting the core focus session architecture.

Keep current task logic sufficiently isolated that another timer-related feature can be introduced as its own model/service where appropriate.

Do not combine hypothetical Pomodoro behavior into `FocusSession` now.

---

# 31. UI Design Principles

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

# 32. Menu-Bar Design Principles

Menu-bar space is scarce.

Therefore:

* keep labels short,
* truncate long task names,
* avoid displaying unnecessary status text,
* do not permanently display elapsed time in the menu-bar label unless explicitly requested,
* avoid menu-bar UI that expands significantly.

The menu bar's main job is:

> Keep the current task visible.

Detailed timer information belongs inside the menu.

---

# 33. Native macOS First

Prefer native Apple APIs and SwiftUI where reasonable.

Primary technology:

```text
Swift
SwiftUI
macOS APIs
```

Use AppKit only when necessary to accomplish behavior that SwiftUI does not cleanly provide.

Do not introduce:

* Electron,
* React,
* web views,
* Node.js,
* Python runtimes,
* backend frameworks,

for functionality that can be implemented cleanly with the native macOS stack.

---

# 34. Dependencies

Prefer the standard Apple frameworks.

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

# 35. State Ownership Rule

One of the most important architectural rules:

> **There should be one source of truth for focus-session state.**

That source should be `FocusSession`.

Avoid duplicated state such as:

```text
MenuView.currentTask
FocusSession.currentTask
PersistenceService.currentTask
```

where each can independently diverge.

Prefer:

```text
FocusSession.currentTask
```

with other components reading, presenting, saving, or restoring that value.

---

# 36. Keep Views Thin

A view may:

* display state,
* format state for presentation,
* collect user input,
* call model actions.

A view should generally not:

* calculate session semantics,
* implement timer state machines,
* access persistence directly,
* decide how restart works,
* decide how pause accumulation works.

If logic becomes difficult to describe as purely UI behavior, it likely belongs elsewhere.

---

# 37. Keep Models Focused

`FocusSession` should represent focus-session behavior.

Do not turn it into a universal dumping ground.

It should not eventually become responsible for:

* Google authentication,
* notification permissions,
* arbitrary integrations,
* unrelated settings,
* menu layout,
* app icons.

When a responsibility is genuinely different, introduce an appropriate service/model when needed.

---

# 38. Error Handling Philosophy

This is a small local application.

Error handling should be proportional to the risk.

Avoid unnecessary complexity.

Important failures should:

* fail safely,
* avoid corrupting state,
* avoid crashing where reasonably possible.

Persistence failures should not cause an unrecoverable application state.

Do not introduce large error-management frameworks for the MVP.

---

# 39. Naming

Prefer descriptive names.

Good examples:

```text
FocusSession
MenuView
PersistenceService
elapsedTime
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

# 40. Code Readability

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

# 41. Comments

Comments should explain **why**, especially when behavior is not obvious.

Good:

```text
// Store accumulated elapsed time when pausing so wall-clock time
// during the paused period does not count toward the session.
```

Less useful:

```text
// Set isPaused to true
isPaused = true
```

Do not over-comment self-explanatory Swift syntax.

---

# 42. Incremental Development Rule

This repository should be developed incrementally.

When given a small implementation request:

> Implement only the requested increment.

Do not automatically continue into later milestones.

For example, if asked:

> Create the basic menu bar icon and menu.

Do not also implement:

* focus-session persistence,
* stopwatch,
* Pomodoro,
* integrations,

unless explicitly requested.

Small commits and understandable milestones are preferred.

---

# 43. Before Editing

Before making meaningful changes:

1. read `README.md`,
2. read `AGENTS.md`,
3. inspect relevant existing source files,
4. understand the current architecture,
5. preserve existing working behavior unless the task requires changing it.

Do not assume the repository still exactly matches an earlier prompt.

The repository is the current source of truth for implementation state.

---

# 44. Existing Code First

Before creating a new abstraction:

* inspect whether an appropriate type already exists,
* extend existing responsibilities when appropriate,
* avoid duplicate implementations.

Do not create:

```text
FocusTimer
TimerManager
TimerService
SessionTimer
```

all representing the same concept.

Keep the architecture coherent.

---

# 45. Changes to Project Structure

Do not reorganize the project casually.

The intended baseline is:

```text
Views/
Models/
Services/
```

plus the app entry point and assets.

If a new folder is justified by actual code, it may be introduced.

Do not add empty folders for hypothetical future use.

When moving Swift files, preserve Xcode project references and ensure the project builds.

---

# 46. Build Validation

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

---

# 47. Runtime Validation

For UI behavior, compilation alone is insufficient.

When feasible, verify the relevant behavior in the running macOS application.

Examples:

* menu-bar item appears,
* no-task state displays correctly,
* task can be entered,
* task label updates,
* pause stops elapsed-time growth,
* resume continues from prior duration,
* restart resets duration,
* rename preserves duration,
* clear returns to icon-only state,
* quitting removes menu-bar presence,
* persisted state restores correctly.

Only validate behavior relevant to the current implementation stage.

---

# 48. Testing Philosophy

Prefer tests for behavior with meaningful logic, especially timer state transitions.

Potential model-level scenarios include:

```text
start → running
running → pause
pause → resume
running → restart
paused → restart
rename preserves elapsed time
clear removes task and resets timer
```

Do not create excessive testing infrastructure before there is meaningful logic to test.

Timer logic should be structured so it can be tested without requiring the actual UI.

Where useful, avoid hard dependencies on `Date.now` throughout business logic if doing so makes deterministic timer tests difficult.

Do not overengineer testability prematurely, but keep deterministic logic in mind.

---

# 49. Source Control

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

# 50. Privacy

OnTask's MVP is local-first.

Task text and timer data should remain on the user's Mac.

Do not:

* transmit task text,
* add analytics,
* add telemetry,
* call external services,
* introduce tracking,

unless explicitly required by a future product decision.

No user account is required.

---

# 51. Security

The MVP handles low-risk local productivity data.

Still follow basic safety principles:

* do not log sensitive task text unnecessarily,
* do not introduce network access without a product requirement,
* do not store secrets because the MVP has no need for them,
* do not request unnecessary macOS permissions.

Use the minimum system privileges required.

---

# 52. Performance

OnTask should be lightweight.

It spends most of its time idle in the menu bar.

Avoid:

* aggressive polling,
* unnecessary background processing,
* frequent disk writes,
* high-frequency persistence,
* unnecessary networking.

A visible stopwatch may refresh frequently enough for a natural display, but the underlying architecture should remain efficient.

---

# 53. Accessibility

Use standard SwiftUI controls where possible.

Do not sacrifice accessibility for custom visuals.

Buttons and icons should have understandable labels where appropriate.

The application should remain usable without relying solely on ambiguous iconography.

---

# 54. Avoid Premature Features

Do not independently add:

* Pomodoro,
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
* settings dashboards.

Even if such a feature seems useful, it is outside the current MVP unless explicitly requested.

---

# 55. Avoid Premature Infrastructure

Do not independently introduce:

```text
backend services
REST APIs
GraphQL
SQLite
SwiftData
Core Data
PostgreSQL
cloud storage
authentication
dependency injection frameworks
large coordinator hierarchies
complex repositories/data-source layers
```

The current architecture does not require them.

Introduce infrastructure only when an actual requirement creates the need.

---

# 56. Do Not One-Shot the Project

Even though the overall MVP is documented here, do not interpret this document as an instruction to implement everything at once.

If the current prompt asks only for:

```text
menu bar shell
```

implement only that.

If the next prompt asks for:

```text
FocusSession
```

implement that next.

The purpose of this document is to ensure each incremental change fits the same architecture.

---

# 57. Preferred Development Sequence

Unless the repository has already progressed beyond these stages, a sensible development order is:

```text
1. Native menu-bar application shell
2. MenuView and quit behavior
3. FocusSession task state
4. Set / display / clear current task
5. Stopwatch core behavior
6. Pause / resume
7. Restart
8. Rename
9. Persistence
10. Restore state across launches
11. Polish and validation
```

This sequence is guidance, not a request to implement every step.

Always follow the current explicit task.

---

# 58. Architecture Decision Rule

When unsure where code belongs, ask:

### Is this about what the user sees?

Put it in:

```text
Views/
```

### Is this about task/timer state or behavior?

Put it in:

```text
Models/
```

### Is this about storage, macOS facilities, or external communication?

Put it in:

```text
Services/
```

### Is this about application startup and top-level wiring?

It likely belongs in:

```text
OnTaskApp.swift
```

---

# 59. Example Event Flow

For a Pause click:

```text
User
  ↓
Pause button
  ↓
MenuView
  ↓
FocusSession.pause()
  ↓
FocusSession updates elapsed state
  ↓
PersistenceService saves meaningful state
  ↓
SwiftUI reflects new state
```

The same general pattern should apply to:

```text
start
resume
restart
rename
clear
```

---

# 60. Central Engineering Principle

The central architecture principle for OnTask is:

> **The UI presents state. The model owns behavior. Services handle external/system concerns.**

Or more concretely:

```text
MenuView
= what the user sees

FocusSession
= what the app knows and how focus behavior works

PersistenceService
= how the app remembers

OnTaskApp
= how everything starts and connects
```

Maintain this separation unless a concrete requirement demonstrates that another design would be simpler or clearer.

---

# 61. Definition of a Good Change

A good OnTask change should:

* solve the requested behavior,
* preserve the product's simplicity,
* fit the established architecture,
* avoid unrelated modifications,
* compile successfully,
* remain understandable,
* avoid unnecessary dependencies,
* make future modification reasonably easy,
* not implement unrequested features.

When there is a choice, prefer the smallest clean solution that satisfies the current requirement.

