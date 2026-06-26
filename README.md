# Diurnal

A Franklin-methodology day planner for Mac, iPad, and iPhone.

## Features

- **Daily Page** — A/B/C prioritised tasks, appointments, notes, and roll-over of incomplete tasks
- **Weekly Compass** — Weekly goals and "Sharpening the Saw" renewal across four dimensions
- **Goals** — Short-range, intermediate, and long-range goal tracking
- **Mission Statement** — Your personal purpose statement
- **iCloud Sync** — CloudKit keeps everything in sync across all your devices

---

## Xcode Setup (one-time, ~5 minutes)

The Swift source files are ready. You need to create the Xcode project wrapper:

### 1. Create the project

1. Open **Xcode**
2. **File → New → Project**
3. Choose **Multiplatform → App**
4. Set:
   - **Product Name:** `Diurnal`
   - **Bundle Identifier:** `com.yourname.diurnal` (use your own reverse domain)
   - **Storage:** `None` (SwiftData is wired up manually in the source)
   - **Host in CloudKit:** leave unchecked for now
5. **Save into:** `/Users/simonrolph/Development/Diurnal/`
   - Xcode will create `Diurnal/Diurnal.xcodeproj`

### 2. Replace the generated files

Delete the auto-generated files Xcode creates (`ContentView.swift`, `DiurnalApp.swift`, the asset catalogue placeholder) and replace with the files already in the `Diurnal/` folder.

In Xcode's project navigator, drag in all the folders:
```
Diurnal/
  DiurnalApp.swift
  ContentView.swift
  Models/
  Views/
```

Make sure **"Copy items if needed"** is **unchecked** (the files are already there).

### 3. Enable CloudKit

1. Select the **Diurnal** target in Xcode
2. **Signing & Capabilities** tab
3. Click **+ Capability** → add **iCloud**
4. Tick **CloudKit**
5. Under Containers, click **+** and add `iCloud.com.yourname.diurnal`
6. Click **+ Capability** again → add **Background Modes** → tick **Remote notifications**

### 4. Set minimum deployment targets

- **iOS:** 17.0
- **macOS:** 14.0

### 5. Build and run

Select a simulator or your device and press **⌘R**.

---

## Project structure

```
Diurnal/
├── DiurnalApp.swift          Entry point, ModelContainer + CloudKit
├── ContentView.swift         Adaptive nav (TabView on iPhone, sidebar on iPad/Mac)
├── Models/
│   ├── DailyTask.swift       A/B/C prioritised tasks
│   ├── Appointment.swift     Timed appointments
│   ├── DailyNote.swift       Per-day notes
│   ├── WeeklyCompass.swift   Weekly planning page
│   ├── Goal.swift            Short/intermediate/long-range goals
│   └── MissionStatement.swift Personal mission
└── Views/
    ├── Daily/                Daily page, task rows, add forms
    ├── Calendar/             Month grid with day navigation
    ├── Weekly/               Weekly Compass view
    ├── Goals/                Goals list and detail
    └── Mission/              Mission Statement editor
```
