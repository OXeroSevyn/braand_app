-- Insert a new version into the app_versions table.
-- Replace values as needed.

INSERT INTO app_versions (
  version_code,
  version_name,
  apk_url,
  release_notes,
  force_update
) VALUES (
  1, -- version_code (Must match 'version: x.x.x+1' in pubspec.yaml)
  '1.0.0', -- version_name
  'https://bqjrdyxmcsbmiktwpukm.supabase.co/storage/v1/object/public/app-releases/app-release.apk', -- Public URL
  'Initial release with In-App Update support! 🚀', -- Release notes
  false -- force_update
);
