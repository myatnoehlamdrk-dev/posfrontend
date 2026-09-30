import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';
import 'package:posfrontend/features/dashboard/presentation/viewmodels/dashboard_table_view_model.dart';
import 'package:posfrontend/features/dashboard/presentation/widgets/dashboard_table_skeleton.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

/// A read-only table of dashboard rows.
///
/// One screen serves all six tables because the only things that differ are the
/// endpoint and the column list, and both arrive as data in [spec]. Building a
/// sixth bespoke screen would be six copies of the same paging, month filter,
/// and empty-state logic to keep in step.
///
/// Rows load lazily: the first page comes from the API and the next page is
/// fetched when the user scrolls near the bottom. Row numbers keep counting
/// across pages so the number a row carries is its position in the whole result
/// set, not in the currently loaded slice.
///
/// The header and the rows share one horizontal [ScrollController]. That is the
/// whole trick to making this look like a table: a table whose header scrolls
/// independently of its body is not a table, and the usual alternative, two
/// separate horizontal lists, only stays aligned if both are told about each
/// other's offset.
class DashboardTableScreen extends StatefulWidget {
  final DashboardTableSpec spec;

  /// Extra query parameters merged into every request, such as `low: 1`.
  final Map<String, dynamic> query;

  /// Adds a Most / Least segmented control above the table. Only the
  /// most/least-bought table uses it; the other five have nothing to toggle.
  final bool showDirectionToggle;

  /// Which side of the toggle the screen opens on. The most-bought and
  /// least-bought cards share one endpoint, so the card that was tapped decides
  /// which one you land on, rather than both opening on Most.
  final String initialDirection;

  const DashboardTableScreen({
    super.key,
    required this.spec,
    this.query = const {},
    this.showDirectionToggle = false,
    this.initialDirection = 'desc',
  });

  static Route<void> route({
    required DashboardTableSpec spec,
    Map<String, dynamic> query = const {},
    bool showDirectionToggle = false,
    String initialDirection = 'desc',
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => DashboardTableScreen(
        spec: spec,
        query: query,
        showDirectionToggle: showDirectionToggle,
        initialDirection: initialDirection,
      ),
    );
  }

  @override
  State<DashboardTableScreen> createState() => _DashboardTableScreenState();
}

class _DashboardTableScreenState extends State<DashboardTableScreen> {
  static const double _numberWidth = 48;

  /// The row-number column. Every table gets one; the value it shows is the
  /// row's position in the already-loaded list (`index + 1`), so numbering
  /// starts at 1 and keeps counting as more pages arrive without any already
  /// visible row changing its number.
  static const TableColumn _numberColumn = TableColumn(
    label: '#',
    width: _numberWidth,
    align: TableColumnAlign.right,
    kind: TableValueKind.number,
  );

  late final DashboardTableViewModel _viewModel;
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  /// The current calendar month as `YYYY-MM`, the sales filter's default.
  static String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardTableViewModel(
      repository: DashboardRepositoryImpl(),
      endpoint: widget.spec.endpoint,
      fixedQuery: widget.query,
      direction: widget.showDirectionToggle ? widget.initialDirection : null,
      // Only the sales table filters by month, and it starts on the current
      // month rather than on all time.
      month: widget.spec.showMonthFilter ? _currentMonthKey() : null,
    )..load();
    _vertical.addListener(_onVerticalScroll);
  }

  void _onVerticalScroll() {
    if (!_vertical.hasClients) return;
    final position = _vertical.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _viewModel.loadMore();
    }
  }

  @override
  void dispose() {
    _vertical.removeListener(_onVerticalScroll);
    _vertical.dispose();
    _horizontal.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t(widget.spec.title),
              showMenuButton: false,
              showBackButton: true,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Column(
                    children: [
                      _buildToolbar(p),
                      Expanded(child: _buildBody(p)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showDirectionToggle) ...[
            _DirectionToggle(
              value: _viewModel.direction ?? 'desc',
              onChanged: _viewModel.setDirection,
            ),
            const SizedBox(height: 10),
          ],
          if (widget.spec.showMonthFilter) ...[
            _MonthFilter(
              value: _viewModel.month,
              onChanged: _viewModel.setMonth,
              palette: p,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Text(
                context.l10n
                    .t(_viewModel.total == 1 ? '1 row' : '{v1} rows')
                    .replaceAll('{v1}', _viewModel.total.toString()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
              if (_viewModel.total > _viewModel.rows.length) ...[
                Text(
                  context.l10n
                      .t('  ·  showing {v1}')
                      .replaceAll('{v1}', (_viewModel.rows.length).toString()),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ],
          ),
          if (widget.spec.note != null) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.t(widget.spec.note!),
              style: TextStyle(fontSize: 11, color: p.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_viewModel.isLoading && !_viewModel.hasLoaded) {
      return DashboardTableSkeleton(
        columns: widget.spec.columns,
        totalWidth: _tableWidth,
      );
    }

    if (_viewModel.hasError && _viewModel.rows.isEmpty) {
      return _Message(
        icon: Icons.cloud_off,
        title: context.l10n.t('Could not load'),
        detail: _viewModel.errorMessage ?? 'Something went wrong.',
        actionLabel: 'Retry',
        onAction: _viewModel.load,
      );
    }

    if (_viewModel.rows.isEmpty) {
      return _Message(
        icon: Icons.inbox,
        title: context.l10n.t('Nothing to show'),
        detail: 'There are no rows in this table yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      color: p.primary,
      backgroundColor: p.surface,
      child: ListView(
        controller: _vertical,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildTable(p),
          if (_viewModel.isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The width the number column adds on top of the spec's own width.
  double get _tableWidth => widget.spec.totalWidth + _numberColumn.width;

  Widget _buildTable(AppPalette p) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      // One horizontal viewport for the header and every row. The rows are a
      // fixed-page slice of the already-fetched list, and new pages arrive at
      // the bottom, so building them together is simpler than keeping two
      // scroll views in step.
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderRow(p),
              for (var i = 0; i < _viewModel.rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.border),
                _buildDataRow(p, _viewModel.rows[i], i),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(AppPalette p) {
    return Container(
      color: p.surfaceAlt,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _cell(
            _numberColumn,
            Text(
              context.l10n.t(_numberColumn.label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: p.textSecondary,
              ),
              textAlign: _textAlign(_numberColumn),
            ),
          ),
          for (final column in widget.spec.columns)
            _cell(
              column,
              Text(
                context.l10n.t(column.label),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: p.textSecondary,
                ),
                textAlign: _textAlign(column),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(AppPalette p, DashboardTableRow row, int index) {
    // `index` walks the accumulated rows list, so 0 is the first row ever
    // loaded. Adding 1 gives a number that is stable across load-more: page 2
    // appends rows 16..30 without touching the 1..15 already on screen.
    final rowNumber = index + 1;

    return Container(
      color: index.isEven ? p.surface : p.surfaceAlt.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cell(
            _numberColumn,
            Text(
              rowNumber.toString(),
              style: TextStyle(
                fontSize: 13,
                color: p.textMuted,
                fontWeight: FontWeight.w400,
              ),
              textAlign: _textAlign(_numberColumn),
            ),
          ),
          for (final column in widget.spec.columns)
            _cell(
              column,
              Text(
                row.display(column),
                style: TextStyle(
                  fontSize: 13,
                  color: p.textPrimary,
                  fontWeight: column.kind == TableValueKind.text
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
                textAlign: _textAlign(column),
                maxLines: column.wrap ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(TableColumn column, Widget child) {
    return SizedBox(
      width: column.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Align(
          alignment: column.align == TableColumnAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  TextAlign _textAlign(TableColumn column) =>
      column.align == TableColumnAlign.right ? TextAlign.right : TextAlign.left;
}

/// Sentinel a month sheet returns for "All time", so a real all-time choice can
/// be told apart from the sheet being dismissed (which returns null too).
const String _allTimeMonth = '__ALL_TIME__';

/// The sales table's month filter. The chip on the toolbar only opens a picker;
/// a reload happens only when the user actually picks a month or All time in
/// the calendar sheet, never while the picker is open. The value is either null
/// (all time) or `YYYY-MM`, the format the API accepts.
class _MonthFilter extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final AppPalette palette;

  const _MonthFilter({
    required this.value,
    required this.onChanged,
    required this.palette,
  });

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "September 2026" for `2026-09`, null when the filter is all time.
  static String? _labelOf(String? month) {
    if (month == null) return null;
    final parts = month.split('-');
    final year = int.tryParse(parts.length == 2 ? parts[0] : '');
    final monthIndex = parts.length == 2
        ? (int.tryParse(parts[1]) ?? 0) - 1
        : -1;
    if (year == null || monthIndex < 0 || monthIndex >= 12) return month;
    return '${_monthNames[monthIndex]} $year';
  }

  Future<void> _openPicker(BuildContext context) async {
    final palette = this.palette;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonthSheet(initial: value, palette: palette),
    );
    if (picked == null) return; // dismissed without choosing
    final next = picked == _allTimeMonth ? null : picked;
    if (next == value) return;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final label = _labelOf(value) ?? 'All time';

    return Row(
      children: [
        Icon(Icons.calendar_month_outlined, size: 18, color: p.textMuted),
        const SizedBox(width: 8),
        Text(
          context.l10n.t('Month'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: p.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_drop_down, size: 18, color: p.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Body of the month picker: a year switcher over a 3-column grid of the twelve
/// months. Picking a month (or All time) closes the sheet and returns the
/// choice; picking the already-active option just closes it.
class _MonthSheet extends StatefulWidget {
  final String? initial;
  final AppPalette palette;

  const _MonthSheet({required this.initial, required this.palette});

  @override
  State<_MonthSheet> createState() => _MonthSheetState();
}

class _MonthSheetState extends State<_MonthSheet> {
  late final String? _selected = widget.initial;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = _yearOf(_selected) ?? now.year;
  }

  static int? _yearOf(String? month) {
    if (month == null) return null;
    final parts = month.split('-');
    return parts.length == 2 ? int.tryParse(parts[0]) : null;
  }

  static String _key(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  void _select(int month) {
    final key = _key(_year, month);
    // Choosing the month that is already active is a no-op: just close.
    Navigator.pop(context, key == _selected ? null : key);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              context.l10n.t('Select month'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _year > 2000 ? () => setState(() => _year--) : null,
                icon: Icon(Icons.chevron_left, color: p.textMuted),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    context.l10n
                        .t('{v1}')
                        .replaceAll('{v1}', (_year).toString()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _year < now.year
                    ? () => setState(() => _year++)
                    : null,
                icon: Icon(Icons.chevron_right, color: p.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: [
              for (var month = 1; month <= 12; month++) _monthCell(month, now),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              final isAllTime = _selected == null;
              // Same as the months: picking what is already active just closes.
              Navigator.pop(context, isAllTime ? null : _allTimeMonth);
            },
            icon: Icon(Icons.clear_all, size: 16, color: p.primary),
            label: Text(
              context.l10n.t('All time'),
              style: TextStyle(color: p.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthCell(int month, DateTime now) {
    final p = widget.palette;
    final key = _key(_year, month);
    final isSelected = key == _selected;
    final isCurrent = key == _key(now.year, now.month);

    return GestureDetector(
      onTap: () => _select(month),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? p.primary : p.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: p.border),
        ),
        child: Text(
          _MonthFilter._monthNames[month - 1].substring(0, 3),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: !isSelected && isCurrent ? p.primary : p.textPrimary,
            decoration: !isSelected && isCurrent
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DirectionToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const options = {'desc': 'Most Bought', 'asc': 'Least Bought'};

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: value == entry.key ? p.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value == entry.key
                          ? Colors.white
                          : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: p.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.textMuted),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, style: TextStyle(color: p.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
