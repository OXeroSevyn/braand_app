-- Fix Auto Sign-out Permissions
-- Allow Admins to insert attendance records for ANY user (required for auto sign-out service)

-- 1. Create a policy for Admins to insert any attendance record
CREATE POLICY "Admins can insert attendance for any user"
ON attendance_records FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'Admin'
  )
);

-- 2. Create a View for Admin Leave Requests (to enable robust streaming)
CREATE OR REPLACE VIEW admin_leave_requests_view AS
SELECT 
  lr.id,
  lr.user_id,
  lr.start_date,
  lr.end_date,
  lr.leave_type,
  lr.reason,
  lr.status,
  lr.admin_comment,
  lr.created_at,
  p.name as user_name,
  p.role as user_role,
  p.department as user_department,
  p.avatar as user_avatar
FROM leave_requests lr
JOIN profiles p ON lr.user_id = p.id;

-- 3. Grant permissions on the view
GRANT SELECT ON admin_leave_requests_view TO authenticated;
GRANT SELECT ON admin_leave_requests_view TO service_role;
