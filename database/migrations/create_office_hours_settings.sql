-- Office Hours Management System
-- Migration file to add office hours settings and auto sign-out functionality

-- Create office_hours_settings table
CREATE TABLE IF NOT EXISTS public.office_hours_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  in_time TIME NOT NULL,
  out_time TIME NOT NULL,
  sunday_off BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.office_hours_settings ENABLE ROW LEVEL SECURITY;

-- Admins can manage office hours
CREATE POLICY "Admins can manage office hours"
  ON public.office_hours_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );

-- Everyone can read office hours
CREATE POLICY "Everyone can read office hours"
  ON public.office_hours_settings
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Insert default office hours (10:30 AM - 8:00 PM, Sunday off)
INSERT INTO public.office_hours_settings (in_time, out_time, sunday_off, is_active)
VALUES ('10:30:00', '20:00:00', TRUE, TRUE)
ON CONFLICT DO NOTHING;

-- Add comment
COMMENT ON TABLE public.office_hours_settings IS 'Stores global office hours configuration with auto sign-out support';
