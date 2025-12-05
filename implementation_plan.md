# Implementation Plan - Supabase Database Integration

To show real-time data for all users (Employees and Admins), we need to move beyond local storage and use Supabase's Database.

## User Action Required
- [ ] **Run SQL Script**: The user must run a provided SQL script in their Supabase Dashboard to create the necessary tables (`profiles`, `attendance_records`) and policies.

## Proposed Changes

### 1. Database Schema (New `supabase_schema.sql`)
- Create `profiles` table (id, name, email, role, department, created_at).
- Create `attendance_records` table (id, user_id, type, timestamp, location, created_at).
- Enable RLS (Row Level Security) and add policies for reading/writing.

### 2. `lib/services/supabase_service.dart` (New)
- Create a service to handle database interactions.
- `createProfile(User user)`: Insert into `profiles`.
- `getEmployees()`: Select from `profiles`.
- `saveRecord(AttendanceRecord record)`: Insert into `attendance_records`.
- `getRecentActivity()`: Select from `attendance_records` with joins/fetches.

### 3. `lib/providers/auth_provider.dart`
- Update `signUp` to call `SupabaseService.createProfile` after successful auth.

### 4. `lib/screens/admin_view.dart`
- Replace `StorageService` calls with `SupabaseService`.
- Implement the 2-second auto-refresh using `SupabaseService`.
- Update `_buildEmployeeTable` to calculate status based on real `attendance_records`.

### 5. `lib/screens/employee_view.dart`
- Update to use `SupabaseService` for clocking in/out.

## Verification Plan
1.  **Run SQL**: User runs the script.
2.  **Sign Up**: Create a new Employee user. Verify they appear in the `profiles` table (and thus the Admin View).
3.  **Clock In**: Employee clocks in.
4.  **Admin Check**: Admin sees the Employee as "ONLINE" and sees the "CLOCK_IN" event in the feed.
