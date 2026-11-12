import 'package:flutter/material.dart';

/// A figure that counts up to its value, the way CountUp.js does on the web.
///
/// The first build counts from zero; when [value] changes — a different month
/// is picked, a fee rate is edited — the same widget counts from wherever it
/// currently sits to the new figure instead of snapping to it. [format] runs on
/// every frame, so the grouped thousands and the decimal places stay right the
/// whole way up.
///
/// The counter always runs, even when the platform reports reduced motion: it
/// is a short tick on one line of text rather than a moving surface, and the
/// figure reads correctly at every frame.
class CountUpText extends StatelessWidget {
  final num value;

  /// Turns the in-flight number into the string on screen, e.g. `ofMoney`.
  final String Function(num value) format;

  /// Long enough that the motion reads, short enough that changing a filter
  /// never feels like waiting.
  final Duration duration;
  final Curve curve;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animated, _) => Text(
        format(animated),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// The same count-up effect for a figure that is already formatted as a
/// string, e.g. `MMK 11,280,000` or `1,264`.
///
/// Only the number inside the text moves; whatever surrounds it — the currency
/// prefix, a `%` suffix, a thousands separator — is held still, so the card's
/// copy can stay exactly as the screen wrote it.
class CountUpString extends StatelessWidget {
  final String value;

  final Duration duration;
  final Curve curve;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const CountUpString({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final parts = _FormattedNumber.parse(value);
    if (parts == null) {
      return Text(
        value,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: parts.number),
      duration: duration,
      curve: curve,
      builder: (context, animated, _) => Text(
        parts.render(animated),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// The first numeric token in a label, split from the text around it.
///
/// `MMK 11,280,000` becomes prefix `MMK `, number `11280000`, suffix `''`, and
/// keeps the comma grouping; `12.5%` keeps its single decimal and `%` sign.
class _FormattedNumber {
  final String prefix;
  final String suffix;
  final double number;
  final int decimals;
  final bool grouped;

  const _FormattedNumber({
    required this.prefix,
    required this.suffix,
    required this.number,
    required this.decimals,
    required this.grouped,
  });

  static final RegExp _token = RegExp(r'\d[\d,]*(?:\.\d+)?');

  static _FormattedNumber? parse(String text) {
    final match = _token.firstMatch(text);
    if (match == null) return null;

    final token = match.group(0)!;
    final dot = token.indexOf('.');
    final decimals = dot == -1 ? 0 : token.length - dot - 1;
    final number = double.tryParse(token.replaceAll(',', ''));
    if (number == null) return null;

    return _FormattedNumber(
      prefix: text.substring(0, match.start),
      suffix: text.substring(match.end),
      number: number,
      decimals: decimals,
      grouped: token.contains(','),
    );
  }

  String render(num animated) {
    final fixed = animated.toDouble().toStringAsFixed(decimals);
    final body = grouped ? _withCommas(fixed) : fixed;
    return '$prefix$body$suffix';
  }

  static String _withCommas(String fixed) {
    final dot = fixed.indexOf('.');
    final whole = dot == -1 ? fixed : fixed.substring(0, dot);
    final rest = dot == -1 ? '' : fixed.substring(dot);
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '$buffer$rest';
  }
}
