# MYR Debt Tracker

Offline Flutter debt tracker for Malaysian Ringgit (MYR) with Material 3 light/dark themes and local SQLite (`sqflite`) storage.

## Setup & Run (Android)

1. Generate the Android platform scaffolding in this directory (if not already present):
   ```bash
   flutter create . --platforms=android
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

## Build APK

- **Universal Release APK:**
  ```bash
  flutter build apk --release
  ```
  Output: `build\app\outputs\flutter-apk\app-release.apk`

- **Split APKs by ABI:**
  ```bash
  flutter build apk --split-per-abi
  ```
  Output: `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

- **Direct Install via ADB:**
  ```bash
  flutter install
  ```

### Optional: Change App Launcher Name
In `android/app/src/main/AndroidManifest.xml`, update `android:label="Debt Tracker"`.
