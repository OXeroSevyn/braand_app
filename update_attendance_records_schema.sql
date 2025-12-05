-- Update Attendance Records Table
-- Add columns for verification data

ALTER TABLE attendance_records
ADD COLUMN IF NOT EXISTS device_id TEXT,
ADD COLUMN IF NOT EXISTS biometric_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS photo_url TEXT,
ADD COLUMN IF NOT EXISTS verification_method TEXT CHECK (verification_method IN ('fingerprint', 'face_id', 'none'));

-- Create index for device_id lookups
CREATE INDEX IF NOT EXISTS idx_attendance_records_device_id ON attendance_records(device_id);
