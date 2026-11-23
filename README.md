# MYR Debt Tracker

**MYR Debt Tracker** is a simple, private, offline-first Flutter app for tracking personal debts in **Malaysian Ringgit (MYR / RM)** — with zero interest calculations, no cloud accounts, and all data stored locally on your device using SQLite (`sqflite`).

Whether you are keeping track of money you owe to friends/family or money owed to you, the app gives you a clear view of your net position, partial payment history, monthly payoff forecasts, and offline due date reminders.

## Features

- **Track Both Sides of Debt**: Record **I Owe** and **Owed to Me** entries with person name, amount in RM (up to RM 100,000.00), optional due date, and notes.
- **Repeat & Split Monthly Installments**: Repeat a monthly amount (e.g., RM 200 for 6 months) or split a total across 2–36 months so installments automatically populate future months in the **Monthly Plan** with individual reminders.
- **Categories / Tags**: Label debts (*General*, *Family*, *Friends*, *Bills*, *Business*, *Other*) to filter your debt list and view a **By Category** spending breakdown in **Monthly Plan**.
- **Search & Sort**: Search debts instantly by person name, note, or tag, and sort by **Soonest Due**, **Highest Balance**, **Newest**, or **Name (A–Z)**.
- **Group by Person Summary**: View combined net totals and expandable debt lists per person in the dedicated **People** tab.
- **Edit & Manage Records**: Update a debt's details (name, type, category, total amount, due date, or note) anytime from the detail screen, or delete individual records / entire installment plans cleanly.
- **Partial & Full Payments**: Log repayments over time with payment history, undo accidental entries, or settle a remaining balance in one tap.
- **Monthly Plan & Charts**: Visualize upcoming debts you owe across **This Month**, **Next Month**, and **Incoming** months with a donut chart, forecast bar graph, and overdue/undated alerts.
- **Custom Offline Due Date Reminders**: Local notifications (1 day before and/or on the due date) with a customizable daily reminder time and built-in test notification in **Settings**.
- **JSON Backup & Restore**: Export all debts, payment history, and preferences to a `.json` file (or copy to clipboard) and restore anytime from **Settings**.
- **Light, Dark & System Themes**: Material 3 interface with persistent theme switching in **Settings**.
- **100% Offline & Private**: All records and preferences stay locally on your Android device in SQLite.

## Setup & Run (Android)

1. Generate the Android platform scaffolding in this directory (if not already present):
   ```powershell
   flutter create . --platforms=android
   ```
2. Install dependencies:
   ```powershell
   flutter pub get
   ```
3. Run on a connected Android device or emulator:
   ```powershell
   flutter run
   ```

## Build APK

- **Universal Release APK:**
  ```powershell
  flutter build apk --release
  ```
  Output: `build\app\outputs\flutter-apk\app-release.apk`

- **Split APKs by ABI:**
  ```powershell
  flutter build apk --split-per-abi
  ```
  Output: `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

- **Direct Install via ADB:**
  ```powershell
  flutter install
  ```
