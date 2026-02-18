-- Insert Version 1.0.3
-- Use this if you are upgrading users who are still on v1.0.1 or below.
-- (Users on v1.0.2+ can use the in-appAdmin Release Manager instead!)

INSERT INTO app_versions (
  version_code,
  version_name,
  apk_url,
  release_notes,
  force_update
) VALUES (
  4, -- Matches 'version: 1.0.3+4' in pubspec.yaml
  '1.0.3',
  'https://bqjrdyxmcsbmiktwpukm.supabase.co/storage/v1/object/public/app-releases/app-release.apk',
  'Performance improvements and bug fixes.',
  false
);
