import 'dart:async';

import 'package:flutter/material.dart';
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
/// sixth bespoke screen would be six copies of the same paging, search, and
/// empty-state logic to keep in step.
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
  late final DashboardTableViewModel _viewModel;
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardTableViewModel(
      repository: DashboardRepositoryImpl(),
      endpoint: widget.spec.endpoint,
      fixedQuery: widget.query,
      direction: widget.showDirectionToggle ? widget.initialDirection : null,
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
    _debounce?.cancel();
    _vertical.removeListener(_onVerticalScroll);
    _vertical.dispose();
    _horizontal.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _viewModel.applySearch(value);
    });
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
              title: widget.spec.title,
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
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(fontSize: 14, color: p.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search',
              hintStyle: TextStyle(fontSize: 14, color: p.textMuted),
              prefixIcon: Icon(Icons.search, size: 18, color: p.textMuted),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 18, color: p.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        _viewModel.applySearch('');
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: p.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: p.primary),
              ),
            ),
          ),
          if (widget.showDirectionToggle) ...[
            const SizedBox(height: 10),
            _DirectionToggle(
              value: _viewModel.direction ?? 'desc',
              onChanged: _viewModel.setDirection,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${_viewModel.total} ${_viewModel.total == 1 ? 'row' : 'rows'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
              if (_viewModel.total > _viewModel.rows.length) ...[
                Text(
                  '  ·  showing ${_viewModel.rows.length}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
              const Spacer(),
              if (_viewModel.page > 1)
                Text(
                  'Page ${_viewModel.page} of ${_viewModel.lastPage}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
            ],
          ),
          if (widget.spec.note != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.spec.note!,
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
        totalWidth: widget.spec.totalWidth,
      );
    }

    if (_viewModel.hasError && _viewModel.rows.isEmpty) {
      return _Message(
        icon: Icons.cloud_off,
        title: 'Could not load',
        detail: _viewModel.errorMessage ?? 'Something went wrong.',
        actionLabel: 'Retry',
        onAction: _viewModel.load,
      );
    }

    if (_viewModel.rows.isEmpty) {
      return _Message(
        icon: Icons.inbox,
        title: _viewModel.search.isEmpty ? 'Nothing to show' : 'No matches',
        detail: _viewModel.search.isEmpty
            ? 'There are no rows in this table yet.'
            : 'Nothing matches "${_viewModel.search}".',
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
            )
          else if (_viewModel.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TextButton(
                  onPressed: _viewModel.loadMore,
                  child: Text('Load more', style: TextStyle(color: p.primary)),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
      // fixed page (15 by default), so building them together is cheaper than
      // the bookkeeping it would take to keep two scroll views in step.
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widget.spec.totalWidth,
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
          for (final column in widget.spec.columns)
            _cell(
              column,
              Text(
                column.label,
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
    return Container(
      color: index.isEven ? p.surface : p.surfaceAlt.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                overflow: column.wrap
                    ? TextOverflow.ellipsis
                    : TextOverflow.ellipsis,
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
                      color: value == entry.key ? Colors.white : p.textSecondary,
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
                child: Text(
                  actionLabel!,
                  style: TextStyle(color: p.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
