import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _imfFixdate(DateTime utc) =>
    '${_weekdays[utc.weekday - 1]}, '
    '${utc.day.toString().padLeft(2, '0')} '
    '${_months[utc.month - 1]} ${utc.year} '
    '${utc.hour.toString().padLeft(2, '0')}:'
    '${utc.minute.toString().padLeft(2, '0')}:'
    '${utc.second.toString().padLeft(2, '0')} GMT';

void main() {
  group('parseRetryAfterSeconds', () {
    test('reads delta-seconds', () {
      expect(parseRetryAfterSeconds('120'), 120);
      expect(parseRetryAfterSeconds('0'), 0);
      expect(parseRetryAfterSeconds('-5'), 0);
    });

    test('reads an IMF-fixdate as the seconds until it', () {
      final target = DateTime.now().toUtc().add(const Duration(seconds: 90));
      final seconds = parseRetryAfterSeconds(_imfFixdate(target));

      expect(seconds, isNotNull);
      expect(seconds!, inInclusiveRange(60, 90));
    });

    test('clamps an IMF-fixdate already in the past to zero', () {
      expect(parseRetryAfterSeconds('Wed, 21 Oct 2015 07:28:00 GMT'), 0);
    });

    test('returns null for anything unusable', () {
      expect(parseRetryAfterSeconds(null), isNull);
      expect(parseRetryAfterSeconds(''), isNull);
      expect(parseRetryAfterSeconds('soon'), isNull);
      // A zone other than GMT, and the obsoleted RFC 850 form, are rejected
      // rather than guessed at.
      expect(parseRetryAfterSeconds('Wed, 21 Oct 2015 07:28:00 PST'), isNull);
      expect(parseRetryAfterSeconds('21 Oct 2015 07:28:00 GMT'), isNull);
    });
  });
}
