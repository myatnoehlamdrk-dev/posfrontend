import 'package:equatable/equatable.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';

/// How a cell renders its raw value.
///
/// The tables are described by data, not by a widget tree per screen: six
/// read-only tables with the same shape do not justify six screens, and a
/// column list is far easier to review against the request than a bespoke
/// layout is.
enum TableValueKind {
  text,
  number,
  currency,
  date,
  time,
  dateTime,
}

enum TableColumnAlign { left, right }

class TableColumn extends Equatable {
  /// Label shown in the header. Also the fallback name for the JSON key.
  final String label;

  /// Key the row is read from. Defaults to a snake_case form of [label].
  final String? jsonKey;

  final double width;
  final TableColumnAlign align;
  final TableValueKind kind;

  /// Lets a long cell (a sale's product list) wrap to a second line instead of
  /// being cut off, which matters because that column carries the most content.
  final bool wrap;

  const TableColumn({
    required this.label,
    required this.width,
    this.jsonKey,
    this.align = TableColumnAlign.left,
    this.kind = TableValueKind.text,
    this.wrap = false,
  });

  String get fieldKey =>
      jsonKey ??
      label
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

  @override
  List<Object?> get props => [label, jsonKey, width, align, kind, wrap];
}

/// One page of rows plus the paging state the screen needs.
class TablePage extends Equatable {
  final List<DashboardTableRow> rows;
  final int page;
  final int lastPage;
  final int total;
  final int perPage;

  const TablePage({
    required this.rows,
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 15,
  });

  bool get hasMore => page < lastPage;

  static const TablePage empty = TablePage(rows: []);

  @override
  List<Object?> get props => [rows, page, lastPage, total, perPage];
}

class DashboardTableRow extends Equatable {
  final Map<String, dynamic> data;

  const DashboardTableRow(this.data);

  String get id => data['id']?.toString() ?? '';

  String text(String key) {
    final value = data[key];
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  int integer(String key) {
    final value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Renders the raw value for a column. Kept here rather than in the widget so
  /// that a number never shows up as "25000.0" and a date never shows up as an
  /// ISO string with a T in it.
  String display(TableColumn column) {
    switch (column.kind) {
      case TableValueKind.text:
        return text(column.fieldKey);
      case TableValueKind.number:
        return integer(column.fieldKey).withCommas();
      case TableValueKind.currency:
        return integer(column.fieldKey).asCurrency();
      case TableValueKind.date:
        return _formatDate(column.fieldKey, withTime: false);
      case TableValueKind.time:
        return text(column.fieldKey);
      case TableValueKind.dateTime:
        return _formatDate(column.fieldKey, withTime: true);
    }
  }

  String _formatDate(String key, {required bool withTime}) {
    final raw = text(key);
    if (raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final date =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';

    if (!withTime) return date;

    return '$date ${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [data];
}
