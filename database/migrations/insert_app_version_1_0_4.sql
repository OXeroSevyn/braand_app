-- Insert Version 1.0.4
-- Visual Overhaul: Redesigned Admin Dashboard.

INSERT INTO app_versions (
  version_code,
  version_name,
  apk_url,
  release_notes,
  force_update
) VALUES (
  5, -- Matches 'version: 1.0.4+5' in pubspec.yaml
  '1.0.4',
  'https://bqjrdyxmcsbmiktwpukm.supabase.co/storage/v1/object/public/app-releases/app-release.apk',
  'Brand new Admin Dashboard! 🎨 Simplified header, new Quick Actions grid, and cleaner stats.',
  false
);
