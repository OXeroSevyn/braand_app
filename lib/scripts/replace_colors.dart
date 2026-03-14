import 'dart:io';

void main() async {
  final dir = Directory('lib/screens');
  final dirWidgets = Directory('lib/widgets');

  await _processDirectory(dir);
  await _processDirectory(dirWidgets);

  // ignore: avoid_print
  print('Finished replacing hardcoded colors.');
}

Future<void> _processDirectory(Directory dir) async {
  if (!await dir.exists()) return;

  final entities = await dir.list(recursive: true).toList();
  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await _processFile(entity);
    }
  }
}

Future<void> _processFile(File file) async {
  String content = await file.readAsString();
  bool modified = false;

  // Pattern to replace AppColors.brand with Theme.of(context).colorScheme.primary
  // Note: This requires BuildContext `context` to be available. In most build methods, it is.
  if (content.contains('AppColors.brand')) {
    content = content.replaceAll(
        'AppColors.brand', 'Theme.of(context).colorScheme.primary');
    modified = true;
  }

  // Same for brandDark -> secondary or primary Container based on usage, but primary is safest fallback.
  if (content.contains('AppColors.brandDark')) {
    content = content.replaceAll(
        'AppColors.brandDark', 'Theme.of(context).colorScheme.secondary');
    modified = true;
  }

  if (modified) {
    await file.writeAsString(content);
    // ignore: avoid_print
    print('Updated: \${file.path}');
  }
}
