-- Insert Version 1.0.2
-- This enables the Admin Release Manager feature for users.

INSERT INTO app_versions (
  version_code,
  version_name,
  apk_url,
  release_notes,
  force_update
) VALUES (
  3, -- Matches 'version: 1.0.2+3' in pubspec.yaml
  '1.0.2',
  'https://bqjrdyxmcsbmiktwpukm.supabase.co/storage/v1/object/public/app-releases/app-release.apk',
  'Added Admin Release Manager! 🚀 You can now publish updates directly from the app.',
  false
);
