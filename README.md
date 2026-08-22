# Time Sayer ⏰ 🗣️

A lightweight, native macOS menu bar app that announces the time at your chosen frequency using macOS system voices.

## Features

- **Customisable Announcement Intervals**:
  - Every Minute (ideal for testing or frequent time checks)
  - Every 15 Minutes / Quarter Hour (`:00`, `:15`, `:30`, `:45`)
  - Every 30 Minutes / Half Hour (`:00`, `:30`)
  - Every Hour (`:00`)
- **System 12-Hour / 24-Hour Time Detection**:
  - Automatically matches your macOS system time format (or can be manually switched between 12-hour AM/PM and 24-hour mode).
- **System Speech Voice Integration**:
  - Select any installed macOS system voice (Siri, Australian, British, US, etc.)
  - Adjustable speech speed and volume
  - Choose between *Conversational*, *Concise*, and *Natural Spoken* phrasing styles
- **Wall-Clock Precise Alignment**:
  - Automatically calculates exact offsets to wall-clock marks for punctual time announcements
- **Menu Bar Native**:
  - Runs in the background as an `LSUIElement` without taking up space in your Dock or `Cmd+Tab` switcher
  - "Announce Time Now" quick action for instant testing

## Building & Running

To build and package into `Time Sayer.app`:

```bash
chmod +x build.sh
./build.sh
```

To launch the app:

```bash
open "Time Sayer.app"
```

To install to your Applications folder:

```bash
cp -R "Time Sayer.app" /Applications/
```
