# BRAANDINS Flutter App

This is a complete Flutter port of the BRAANDINS workforce operating system.

## Features

*   **Authentication**: 
    *   Employee Login (`john@braandins.com` / `password`)
    *   Admin Login (`admin@braandins.com` / `password`)
*   **Dashboard**:
    *   **Employee View**: Live Clock, Attendance Actions (Clock In/Out, Break), Weekly Hours Chart, Personal Logs.
    *   **Admin View**: Global Stats, Employee Status Table, Real-time Activity Feed.
*   **Design**: Neo-brutalism aesthetic with Dark/Light mode support.
*   **Persistence**: Uses `shared_preferences` to save user session, theme, and attendance records locally.

## Getting Started

1.  Open this folder (`braand_app`) in **Android Studio** or **VS Code**.
2.  Run `flutter pub get` to install dependencies (already done).
3.  Select your device (Emulator or Physical Device).
4.  Run `main.dart` or press the **Run** button.

## Project Structure

*   `lib/main.dart`: Entry point and Theme setup.
*   `lib/providers/`: State management (Auth, Theme).
*   `lib/screens/`: UI Screens (Auth, Dashboard, Admin/Employee Views).
*   `lib/services/`: Data storage logic.
*   `lib/widgets/`: Reusable components (NeoCard, NeoButton, Clock).

## Notes

*   Location services are implemented using `geolocator`. You may need to grant permissions on the device.
*   Data is stored locally on the device.
