 # OnTask

OnTask is a macOS menu bar app that helps you stay conscious of what you're doing right now.

<img width="100" height="100" alt="OnTask" src="https://github.com/user-attachments/assets/9f414750-118d-45f9-bb5b-db11fcbfd254" />


## Why OnTask Exists

It is easy to lose track of what you were doing, switch between tasks without realizing it, or spend too much time on something without noticing.

OnTask is designed to answer one question:

**What am I supposed to be doing right now?**

By keeping the current task in the macOS menu bar, OnTask helps you stay aware of your intention, focus on one thing at a time, and avoid mindless task switching or multitasking.

It also tracks how long the current task has been active, making it easier to stay aware of where your time is going.

## How It Works

When OnTask is running:

* If no task is set, a small icon appears in the macOS menu bar.
* Click the icon to set a current task.
* The task is displayed directly in the menu bar.
* The menu bar view and task color are consistent with the macOS color theme.
* Click the task to view its full name and elapsed time.
* Pause, resume, or restart the stopwatch when needed.
* Rename the current task without resetting the stopwatch.
* Mark the task as done or clear it to return to the icon-only state.
* Quit OnTask to remove it completely from the menu bar.

## Goal

OnTask is intentionally simple.

It's not a task manager or productivity dashboard. Its purpose is to keep your **current focus** visible and make it easier to:

* Remember what you intended to do.
* Maintain your train of thought.
* Focus on one task at a time.
* Reduce unnecessary context switching.
* Stay aware of how much time you have spent on the task.

## Tech

- **Swift** — core application logic
- **SwiftUI** — menu popup and interface
- **AppKit** — macOS menu bar integration, popover behavior, and native system dialogs
- **Observation** — shared application state between the UI and models
- **Xcode** — development, building, and debugging
- **macOS** — native target platform

## Running Locally

### Requirements

- macOS
- Xcode

### Setup (for developers)

1. Clone the repository:

   ```bash
   git clone <your-github-repository-url>
   cd on-task
   ```

2. Open the Xcode project:

```open OnTask.xcodeproj```

3. In Xcode, select My Mac as the run destination.

4. Press Run (⌘R).

## Using the Downloaded App

1. Download the latest `OnTask.zip` from the GitHub **Releases** section.
2. Unzip the file.
3. Move `OnTask.app` into your **Applications** folder.
4. Open `OnTask` from Applications or Spotlight.
5. OnTask will appear in the macOS menu bar.

### Using OnTask

- Click the OnTask icon in the menu bar.
- Enter the task you want to focus on.
- Start the task to begin tracking your time.
- Your current task remains visible in the menu bar.
- Click the menu-bar item at any time to:
  - Pause or resume the timer
  - Restart the timer
  - Rename the current task
  - Mark the task as done
  - Change the appearance color
- Selecting **Done** clears the current task and resets the timer.

OnTask keeps the current focus session only while the app is running. Quitting the app clears the current task and timer.

### macOS Security Warning

The downloadable version is currently an unsigned development build, so macOS may block it the first time it is opened.

If this happens:

1. Try opening `OnTask.app`.
2. Open **System Settings → Privacy & Security**.
3. Scroll down until you see a message that OnTask was blocked.
4. Click **Open Anyway**.
5. Confirm that you want to open the app.

You should only bypass this warning if you downloaded OnTask from this project's official GitHub repository.
   

