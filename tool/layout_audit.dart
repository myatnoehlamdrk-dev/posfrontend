// Flags layout that breaks once labels get longer, which is what translating
// into Burmese, Thai and Japanese does.
//
// The scan is line-based rather than brace-balanced on purpose: `dart format`
// has already normalised the tree, so indentation is a dependable signal for
// "this argument belongs to the call on the previous line", and a hand-rolled
// paren matcher gets quadratic on nested builders.
//
// Three checks, in descending order of how much damage they do when they break:
//
//   ROW_NO_FLEX  a Row holding two or more Text children and nothing that can
//                shrink. The label grows, the value is pushed off the edge.
//   FIXED_TEXT   text inside a SizedBox/Container with a hard-coded width and
//                no Flexible inside it, so the text cannot reflow.
//   CLAMPED      maxLines: 1 together with a hard height, or a fixed-height
//                box, around translated copy. Burmese stacks marks above and
//                below the baseline and gets clipped by tight boxes.
//
// A hit is a place to look, not necessarily a bug: a two-word label in a wide
// row is fine. The output is a worklist.
import 'dart:io';

void main(List<String> args) {
  final root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('run from the package root');
    exit(1);
  }
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('l10n'));

  final hits = <String>[];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    final rel = file.path.replaceAll('\\', '/');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final indent = _indent(line);
      if (line.trimLeft().startsWith('//')) continue;

      // --- ROW_NO_FLEX -------------------------------------------------
      if (RegExp(r'^\s*(pw\.)?Row\(').hasMatch(line)) {
        final block = _block(lines, i, indent);
        final texts = RegExp(r'(pw\.)?Text\(').allMatches(block).length;
        final flex = RegExp(
          r'\b(Expanded|Flexible|Spacer|MainAxisSize\.min)\b',
        ).hasMatch(block);
        if (texts >= 2 && !flex) {
          hits.add('ROW_NO_FLEX  $rel:${i + 1}  ($texts texts, no flex)');
        }
      }

      // --- FIXED_TEXT --------------------------------------------------
      if (RegExp(r'(SizedBox|Container)\(\s*$').hasMatch(line) ||
          RegExp(r'(SizedBox|Container)\(\s*width:\s*\d').hasMatch(line)) {
        final block = _block(lines, i, indent);
        if (!RegExp(r'\b(Flexible|Expanded|FittedBox|AutoSizeText)\b')
            .hasMatch(block)) {
          final w = RegExp(r'width:\s*([\d.]+)').firstMatch(block)?.group(1);
          if (w != null && RegExp(r'(pw\.)?Text\(').hasMatch(block)) {
            hits.add('FIXED_TEXT   $rel:${i + 1}  (width: $w)');
          }
        }
      }

      // --- CLAMPED -----------------------------------------------------
      if (RegExp(r'maxLines:\s*1').hasMatch(line)) {
        final block = _block(lines, i, indent, up: 6, down: 6);
        if (RegExp(r'\bheight:\s*\d').hasMatch(block) ||
            RegExp(r'\bSizedBox\(\s*height:').hasMatch(block)) {
          hits.add('CLAMPED      $rel:${i + 1}  (maxLines: 1 + fixed height)');
        }
      }
    }
  }

  hits.sort();
  for (final h in hits) {
    stdout.writeln(h);
  }
  stdout.writeln('\n${hits.length} to review');
}

int _indent(String line) {
  var n = 0;
  for (final ch in line.trimLeft().codeUnits) {
    if (ch != 32) break;
    n++;
  }
  return n;
}

/// The lines belonging to the call starting at [start].
///
/// Down: while the line is more indented than the call, or a continuation of
/// it (trailing comma/bracket). Up: the few lines that opened it, so a
/// `Text(...)` above the `SizedBox(width:)` is still seen.
String _block(List<String> lines, int start, int indent,
    {int up = 0, int down = 24}) {
  final out = StringBuffer(lines[start]);
  for (var j = start + 1; j < lines.length && j <= start + down; j++) {
    final l = lines[j];
    if (l.trim().isEmpty) continue;
    final li = _indent(l);
    if (li <= indent && !RegExp(r'[,\(\[\{]$').hasMatch(l.trimRight())) break;
    out.writeln(l);
  }
  for (var j = start - 1, n = 0; j >= 0 && n < up; j--, n++) {
    final prefix = lines[j] + '\n';
    final updated = prefix + out.toString();
    out.clear();
    out.write(updated);
  }
  return out.toString();
}
