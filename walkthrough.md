# Supabase Database Integration Walkthrough

I have successfully integrated Supabase Database for real-time data synchronization.

## Changes Made

1.  **Database Schema**: Created `supabase_schema.sql` for `profiles` and `attendance_records` tables.
2.  **Supabase Service**: Created `lib/services/supabase_service.dart` to handle database operations.
3.  **Auth Provider**: Updated `signUp` to create a user profile in the database.
4.  **Admin View**: Updated to fetch real-time data from Supabase and auto-refresh every 2 seconds.
5.  **Employee View**: Updated to save attendance records to Supabase.

## Verification Steps

### 1. Run SQL Script (If not already done)
Ensure you have run the SQL script from `supabase_schema.sql` in your Supabase Dashboard.

### 2. Test Sign Up (New User)
1.  Run the app: `flutter run`.
2.  Sign up a **new** user (e.g., "Bob", Dept: "Sales").
3.  **Verification**: Check your Supabase `profiles` table. You should see the new user.

### 3. Test Employee Attendance
1.  Login as the new user.
2.  Click "Clock In".
3.  **Verification**: Check your Supabase `attendance_records` table. You should see a new record.

### 4. Test Admin View (Real-time)
1.  **Device A (Admin)**: Login as an Admin (or use a separate simulator/device).
    *   *Note*: The current Admin View fetches all users with role 'Employee'.
2.  **Device B (Employee)**: Login as the employee you just created.
3.  **Action**: On Device B, click "Clock In".
4.  **Observation**: On Device A, within 2 seconds, the employee's status should change to **ONLINE** (Green) and the activity feed should show the Clock In event.
5.  **Action**: On Device B, click "Break".
6.  **Observation**: On Device A, status should change to **ON BREAK** (Orange).
