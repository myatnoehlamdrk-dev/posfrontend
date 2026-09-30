import 'dart:io';

const langs = ['myanmar', 'thai', 'japanese'];

void main() {
  for (final lang in langs) {
    final file = File('lib/shared/l10n/strings/$lang.dart');
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync();
    final buffer = StringBuffer();
    final seen = <String>{};

    final entryPattern = RegExp(r"^\s*'([^']+)'\s*:");
    bool inMap = false;
    bool mapClosed = false;

    for (final line in content.split('\n')) {
      if (!inMap) {
        final mapStart = line.indexOf('= {');
        if (mapStart != -1) {
          inMap = true;
          buffer.writeln(line);
          continue;
        }
        buffer.writeln(line);
        continue;
      }

      if (mapClosed) {
        buffer.writeln(line);
        continue;
      }

      if (line.trim() == '};') {
        mapClosed = true;
        buffer.writeln(line);
        continue;
      }

      final match = entryPattern.firstMatch(line);
      if (match != null) {
        final key = match.group(1)!;
        if (seen.contains(key)) continue;
        seen.add(key);
      }
      buffer.writeln(line);
    }

    file.writeAsStringSync(buffer.toString());
    print('$lang: ${seen.length} unique keys');
  }
}
