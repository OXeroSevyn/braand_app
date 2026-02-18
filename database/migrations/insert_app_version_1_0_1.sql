-- Insert Version 1.0.1
-- This assumes you have uploaded the NEW APK to the same bucket location or a new one.

INSERT INTO app_versions (
  version_code,
  version_name,
  apk_url,
  release_notes,
  force_update
) VALUES (
  2, -- Matches 'version: 1.0.1+2' in pubspec.yaml
  '1.0.1',
  'https://bqjrdyxmcsbmiktwpukm.supabase.co/storage/v1/object/public/app-releases/app-release.apk', -- Update this if you renamed the file
  'Bug fixes and performance improvements.',
  false
);
