# Braand App

**Braand App** is a comprehensive workforce operating system built with Flutter and Supabase. It provides a robust platform for organizations to manage employee attendance, tasks, and communications with a distinct Neo-brutalism design language.

## 🚀 Key Features

### For Employees
*   **Smart Attendance Dashboard**:
    *   **Live Clock**: Real-time server-synced clock.
    *   **One-Tap Actions**: Clock In, Clock Out, Break Start, and Break End with visual status indicators.
    *   **Geofencing**: Attendance logic enforces location requirements (must be within office range).
    *   **Office Hours**: strictly enforces shift timings.
*   **Personal Insights**:
    *   **Attendance History**: Calendar view of monthly attendance with status indicators (Full/Partial/Absent).
    *   **Stats**: Weekly work hour charts and daily summaries.
*   **Task Management**: View and update assigned tasks.
*   **Messages**: Integrated chat/announcements with unread badge counters.
*   **Profile**: Manage personal details and device registration.

### For Administrators
*   **Command Center**:
    *   **Live Dashboard**: Real-time overview of who is clocked in, on break, or offline.
    *   **Employee Management**: Add/Edit employees, manage roles and departments.
*   **Configuration**:
    *   **Office Locations**: Set up valid office geofences (Latitude/Longitude/Radius).
    *   **Office Hours**: Define working hours and shift policies.
*   **Reporting**:
    *   **Attendance Reports**: detailed logs of employee timings.
    *   **Task Reports**: track workforce productivity.

## 🛠️ Technology Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Supabase (PostgreSQL, Authentication, Realtime)
*   **Notifications**: Firebase Cloud Messaging (FCM)
*   **State Management**: Provider
*   **Location**: Geolocator (GPS & Geofencing)
*   **Design System**: Custom Neo-brutalism components (`NeoCard`, `NeoButton`) with full Dark/Light mode support.

## 📂 Project Structure

```
lib/
├── main.dart             # App Entry & Initializers (Supabase/Firebase)
├── screens/
│   ├── dashboard_screen.dart   # Main Shell (Mobile/Web layout logic)
│   ├── employee_view.dart      # Employee Tab Navigation
│   ├── admin_view.dart         # Admin Tab Navigation
│   ├── attendance_screen.dart  # Calendar & History View
│   ├── office_locations_screen.dart # Geofence Config
│   └── ...
├── services/
│   ├── attendance_verification_service.dart # Core Attendance Logic
│   ├── office_hours_service.dart            # Shift Validation
│   └── supabase_service.dart                # Database Interactions
├── widgets/              # Reusable Neo-brutalism Components
└── providers/            # Auth & Theme State
```

## ⚡ Getting Started

1.  **Prerequisites**:
    *   Flutter SDK installed.
    *   Supabase project set up.
    *   Firebase project configured (for notifications).

2.  **Installation**:
    ```bash
    git clone https://github.com/your-repo/braand_app.git
    cd braand_app
    flutter pub get
    ```

3.  **Configuration**:
    *   Add your Supabase credentials in `lib/supabase_credentials.dart`.
    *   Ensure `google-services.json` is present in `android/app/`.

4.  **Run**:
    ```bash
    flutter run
    ```
