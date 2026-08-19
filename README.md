 # OnTask

OnTask is a macOS menu bar app that keeps your current task visible while you work.

## Why OnTask Exists

It is easy to lose track of what you were doing, switch between tasks without realizing it, or spend too much time on something without noticing.

OnTask is designed to answer one question:

**What am I supposed to be doing right now?**

By keeping the current task in the macOS menu bar, OnTask helps users stay aware of their intention, focus on one thing at a time, and avoid mindless task switching or multitasking.

It also tracks how long the current task has been active, making it easier to stay aware of where your time is going.

## How It Works

When OnTask is running:

* If no task is set, a small icon appears in the macOS menu bar.
* Click the icon to set a current task.
* The task is displayed directly in the menu bar.
* Click the task to view its full name and elapsed time.
* Pause, resume, or restart the stopwatch when needed.
* Rename the current task without resetting the stopwatch.
* Mark the task as done or clear it to return to the icon-only state.
* Quit OnTask to remove it completely from the menu bar.

## Goal

OnTask is intentionally simple.

It is not a task manager or productivity dashboard. Its purpose is to keep the user's **current focus** visible and make it easier to:

* Remember what you intended to do.
* Maintain your train of thought.
* Focus on one task at a time.
* Reduce unnecessary context switching.
* Stay aware of how much time you have spent on the task.

## Tech

OnTask is a native macOS application built with **Swift** and **SwiftUI**. OnTask stores task and stopwatch data locally on the user's Mac and does not require a backend or cloud storage.

