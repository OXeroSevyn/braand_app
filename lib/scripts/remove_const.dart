import 'dart:io';

void main() async {
  final dirOptions = [Directory('lib/screens'), Directory('lib/widgets')];

  for (final dir in dirOptions) {
    if (!await dir.exists()) continue;

    final entities = await dir.list(recursive: true).toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _processFile(entity);
      }
    }
  }
}

Future<void> _processFile(File file) async {
  String content = await file.readAsString();
  bool modified = false;

  // Specific error fixes based on the provided log

  // Specific error fixes based on the provided log
  if (content.contains(
      'const BorderSide(color: Theme.of(context).colorScheme.primary')) {
    content = content.replaceAll(
        'const BorderSide(color: Theme.of(context).colorScheme.primary',
        'BorderSide(color: Theme.of(context).colorScheme.primary');
    modified = true;
  }
  if (content.contains(
      'const Icon(Icons.add, color: Theme.of(context).colorScheme.primary)')) {
    content = content.replaceAll(
        'const Icon(Icons.add, color: Theme.of(context).colorScheme.primary)',
        'Icon(Icons.add, color: Theme.of(context).colorScheme.primary)');
    modified = true;
  }
  if (content.contains(
      'const Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary')) {
    content = content.replaceAll(
        'const Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary',
        'Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary');
    modified = true;
  }
  if (content.contains(
      'const TextStyle(color: Theme.of(context).colorScheme.primary')) {
    content = content.replaceAll(
        'const TextStyle(color: Theme.of(context).colorScheme.primary',
        'TextStyle(color: Theme.of(context).colorScheme.primary');
    modified = true;
  }

  // Generic regex for const Widget(...Theme.of(context)...)
  // This is tricky doing across multiple lines, so we fix the specific instances we saw.

  final regexIcon =
      RegExp(r'const\s+Icon\s*\([^)]*Theme\.of\s*\(\s*context\s*\)[^)]*\)');
  if (regexIcon.hasMatch(content)) {
    content = content.replaceAllMapped(
        regexIcon, (match) => match.group(0)!.replaceFirst('const ', ''));
    modified = true;
  }

  final regexTextStyle = RegExp(
      r'const\s+TextStyle\s*\([^)]*Theme\.of\s*\(\s*context\s*\)[^)]*\)');
  if (regexTextStyle.hasMatch(content)) {
    content = content.replaceAllMapped(
        regexTextStyle, (match) => match.group(0)!.replaceFirst('const ', ''));
    modified = true;
  }

  final regexBorderSide = RegExp(
      r'const\s+BorderSide\s*\([^)]*Theme\.of\s*\(\s*context\s*\)[^)]*\)');
  if (regexBorderSide.hasMatch(content)) {
    content = content.replaceAllMapped(
        regexBorderSide, (match) => match.group(0)!.replaceFirst('const ', ''));
    modified = true;
  }

  final regexCircularProgress = RegExp(
      r'const\s+CircularProgressIndicator\s*\([^)]*Theme\.of\s*\(\s*context\s*\)[^)]*\)');
  if (regexCircularProgress.hasMatch(content)) {
    content = content.replaceAllMapped(regexCircularProgress,
        (match) => match.group(0)!.replaceFirst('const ', ''));
    modified = true;
  }

  if (modified) {
    await file.writeAsString(content);
    // ignore: avoid_print
    print('Fixed const in: \${file.path}');
  }
}
