-- Insert Version 1.0.5
-- Admin Navigation Cleanup: Simplified bottom nav and expanded Quick Actions.

INSERT INTO app_versions (
  version_code,
  version_name,
  apk_url,
  release_notes,
  force_update
) VALUES (
  6, -- Matches 'version: 1.0.5+6' in pubspec.yaml
  '1.0.5',
  'https://bqjrdyxmcsbmiktwpukm.supabase.co/storage/v1/object/public/app-releases/app-release.apk',
  'Refined Admin Dashboard Navigation! 🧭 Bottom bar is now cleaner (4 items), with more tools in Quick Actions Grid.',
  false
);
