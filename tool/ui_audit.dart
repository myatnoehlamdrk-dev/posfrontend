// Guardrail for the design system.
//
//   dart run tool/ui_audit.dart            # check, exit 1 on violations
//   dart run tool/ui_audit.dart --update   # accept the current raw-font-size debt
//
// Two rules, both about keeping new debt out while old debt is paid down:
//
//   hardcodedColor  no `Color(0x…)` outside `lib/shared/theme`, unless the file
//                   is on the allowlist below. The allowlist is the register of
//                   what is left to convert, and it only ever shrinks.
//
//   rawFontSize     no `fontSize:` outside `lib/shared/theme` in excess of the
//                   per-file count recorded in `tool/ui_audit_baseline.json`.
//                   There are hundreds of these, so the baseline is a ratchet:
//                   a file may get smaller, never larger, and `--update` is
//                   only ever run after a file has been converted.
//
// Both rules scan for the literal text, so a `Color(0x` inside a doc comment
// counts too. That is deliberate: the comment would be describing a colour
// that the rule is supposed to be forbidding.
import 'dart:convert';
import 'dart:io';

const String libDir = 'lib';
const String themeDir = 'lib/shared/theme';
const String baselinePath = 'tool/ui_audit_baseline.json';

/// Files that may still contain hardcoded colours, with the reason.
///
/// Every entry is temporary. Remove an entry as soon as its file is clean;
/// the script fails if a file not listed here has any `Color(0x` at all.
const Map<String, String> colorAllowlist = {
  // Phase 4: the welcome screen is a pasted design mockup with its own
  // `_Spec` palette and its own typefaces. Rebuilding it on app tokens
  // removes these in one go; converting them piecemeal now would only make
  // the mockup look half-ported.
  'lib/features/onboarding/presentation/screens/get_started_screen.dart':
      'deferred to Phase 4 onboarding rebuild',

  // Product colour swatches the merchant picks when creating a product.
  // These are data, not UI: the swatch must show the colour it names.
  'lib/features/product/presentation/viewmodels/add_product_view_model.dart':
      'product colour options are data',

  // Already dark-mode aware: colours live in brightness-specific
  // `static const _dark` / `_light` fields of `_InventoryColors`, selected
  // via `_InventoryColors.of(context)`. They cannot reference `context.palette`
  // (which needs a BuildContext) without losing `const`, so they stay as
  // literals. A future pass can convert them to palette tokens by making the
  // helpers non-const.
  // Phase 1E follow-up: these screens still paint with hardcoded hex colours
  // and have not yet been migrated to context.palette / AppColors. They are
  // tracked here so the guardrail fails only on *new* colour debt. Each
  // entry is removed as the file is converted.
  'lib/features/onboarding/presentation/screens/splash_screen.dart':
      'brand splash artwork — constant in both modes by design',
  'lib/features/product/presentation/screens/products_catalog_screen.dart':
      'promo wallpaper artwork (canvas painters, gradients, always-on-white badge text) — constant in both modes by design',
  'lib/features/sale_analysis/presentation/operation_fee/operation_fee_style.dart': 'Phase 1E follow-up',
  'lib/features/sale_analysis/presentation/operation_fee/widgets/fee_rules_card.dart': 'Phase 1E follow-up',
  'lib/features/inventory/presentation/screens/inventory_screen.dart':
      'brightness-aware via _InventoryColors (static const)',
};

void main(List<String> args) {
  final update = args.contains('--update');
  final files = _dartFiles(Directory(libDir)).toList()..sort();

  final colors = <String, int>{};
  final fontSizes = <String, int>{};
  for (final file in files) {
    final source = File(file).readAsStringSync();
    final normalized = file.replaceAll('\\', '/');
    final c = 'Color(0x'.allMatches(source).length;
    final f = RegExp(r'fontSize:\s*\d').allMatches(source).length;
    if (c > 0) colors[normalized] = c;
    if (f > 0) fontSizes[normalized] = f;
  }

  final colorViolations = <String>[];
  for (final entry in colors.entries) {
    if (_isTheme(entry.key)) continue;
    if (colorAllowlist.containsKey(entry.key)) continue;
    colorViolations.add(
      '  ${entry.key}: ${entry.value} hardcoded colour(s)',
    );
  }

  final baseline = update ? fontSizes : _readBaseline();
  final fontViolations = <String>[];
  for (final entry in fontSizes.entries) {
    if (_isTheme(entry.key)) continue;
    final allowed = baseline[entry.key] ?? 0;
    if (entry.value > allowed) {
      fontViolations.add(
        '  ${entry.key}: ${entry.value} raw fontSize (baseline $allowed)',
      );
    }
  }

  if (update) {
    File(baselinePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(_sorted(fontSizes)),
    );
    stdout.writeln('Wrote $baselinePath (${fontSizes.length} files).');
  }

  final totalColors = colors.values.fold<int>(0, (a, b) => a + b);
  final totalFonts = fontSizes.values.fold<int>(0, (a, b) => a + b);
  stdout.writeln(
    'ui_audit: $totalColors hardcoded colours in ${colors.length} files, '
    '$totalFonts raw fontSize in ${fontSizes.length} files.',
  );
  stdout.writeln(
    '  allowlisted for colour: ${colorAllowlist.length} file(s); '
    'theme layer excluded from both rules.',
  );

  if (colorViolations.isEmpty && fontViolations.isEmpty) {
    stdout.writeln('ui_audit: OK');
    return;
  }

  if (colorViolations.isNotEmpty) {
    stderr.writeln(
      '\nHardcoded colours outside $themeDir (add to the allowlist only '
      'with a reason, or convert them):',
    );
    colorViolations.forEach(stderr.writeln);
  }
  if (fontViolations.isNotEmpty) {
    stderr.writeln(
      '\nNew raw fontSize — convert these to AppTypography, then re-run '
      'with --update:',
    );
    fontViolations.forEach(stderr.writeln);
  }
  exit(1);
}

bool _isTheme(String path) =>
    path.replaceAll('\\', '/').startsWith('$themeDir/');

Map<String, int> _readBaseline() {
  final file = File(baselinePath);
  if (!file.existsSync()) {
    stderr.writeln(
      'ui_audit: $baselinePath is missing. Run '
      '`dart run tool/ui_audit.dart --update` once to create it.',
    );
    exit(2);
  }
  final decoded = jsonDecode(file.readAsStringSync());
  return {
    for (final e in (decoded as Map<String, dynamic>).entries)
      e.key: (e.value as num).toInt(),
  };
}

Map<String, int> _sorted(Map<String, int> values) {
  final keys = values.keys.toList()..sort();
  return {for (final k in keys) k: values[k]!};
}

Iterable<String> _dartFiles(Directory dir) sync* {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    yield entity.path;
  }
}
