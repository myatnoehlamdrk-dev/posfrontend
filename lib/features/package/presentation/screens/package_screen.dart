import 'package:flutter/material.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/data/repositories/package_repository_impl.dart';
import 'package:posfrontend/features/package/presentation/screens/add_package_screen.dart';
import 'package:posfrontend/features/package/presentation/screens/package_details_screen.dart';
import 'package:posfrontend/features/package/presentation/viewmodels/package_view_model.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class PackageScreen extends StatefulWidget {
  final Category category;

  const PackageScreen({super.key, required this.category});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  late final PackageViewModel _viewModel;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color title = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color border = Color(0xFFE5E7EB);

  String get _badgeCode {
    final name = widget.category.name;
    return name.length > 12 ? '${name.substring(0, 12)}...' : name;
  }

  @override
  void initState() {
    super.initState();
    _viewModel = PackageViewModel(
      repository: PackageRepositoryImpl(),
      categoryId: widget.category.id,
    );
  }

  Future<void> _openAddPackage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPackageScreen(category: widget.category),
      ),
    );
    if (result is PackageEntity) {
      _viewModel.addPackage(result);
    } else {
      _viewModel.load();
    }
  }

  Future<void> _openEditPackage(PackageEntity package) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPackageScreen(
          category: widget.category,
          existingPackage: package,
        ),
      ),
    );
    if (result is PackageEntity) {
      _viewModel.updatePackage(result);
    }
  }

  void _showDeleteDialog(PackageEntity p) {
    bool deleting = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Package'),
              content: Text('Are you sure you want to delete "${p.name}"?'),
              actions: [
                TextButton(
                  onPressed: deleting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: deleting
                      ? null
                      : () async {
                          setDialogState(() => deleting = true);
                          Navigator.pop(ctx);
                          final success = await _viewModel.deletePackage(p.id);
                          if (!success && mounted && _viewModel.hasError) {
                            showErrorSnackBar(
                              context,
                              _viewModel.errorMessage!,
                            );
                          }
                        },
                  child: deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _buildContent(isWide: isWide);

        if (isWide) {
          return Scaffold(
            backgroundColor: bg,
            floatingActionButton: FloatingActionButton(
              onPressed: _openAddPackage,
              backgroundColor: const Color(0xFF4FD1D9),
              child: const Icon(Icons.inventory_2, color: Colors.white),
            ),
            body: body,
          );
        }

        return Scaffold(
          backgroundColor: bg,
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddPackage,
            backgroundColor: const Color(0xFF4FD1D9),
            child: const Icon(Icons.inventory_2, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          body: body,
        );
      },
    );
  }

  Widget _buildContent({required bool isWide}) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final items = _viewModel.filtered;
          return Column(
            children: [
              AppScreenTopBar(
                title: widget.category.name,
                showBackButton: true,
                showMenuButton: false,
              ),
              Expanded(
                child: RefreshableBody(
                  onRefresh: () => _viewModel.load(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _breadcrumb(),
                        const SizedBox(height: 16),
                        _headingRow(),
                        const SizedBox(height: 20),
                        if (_viewModel.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(color: purple),
                            ),
                          )
                        else if (_viewModel.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                _viewModel.errorMessage ??
                                    'Failed to load packages.',
                                style: const TextStyle(color: gray),
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            'List of Packages (${_viewModel.total})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (c, constraints) {
                              final cols = constraints.maxWidth >= 560 ? 2 : 1;
                              return _packageGrid(items, cols);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _breadcrumb() {
    const style = TextStyle(fontSize: 13, color: gray);
    return Wrap(
      children: [
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Dashboard',
            style: TextStyle(fontSize: 13, color: purple),
          ),
        ),
        const Text('  >  ', style: style),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Inventory',
            style: TextStyle(fontSize: 13, color: purple),
          ),
        ),
        const Text('  >  ', style: style),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Self Inventory',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: purple),
          ),
        ),
        const Text('  >  ', style: style),
        Text(widget.category.name, style: style),
      ],
    );
  }

  Widget _headingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: title,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your category here...',
                style: TextStyle(fontSize: 16, color: gray),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PackageSort>(
              value: _viewModel.sort == PackageSort.nameAz
                  ? null
                  : _viewModel.sort,
              hint: const Text(
                'Sort',
                style: TextStyle(color: title, fontSize: 14),
              ),
              style: const TextStyle(color: title, fontSize: 14),
              items: [
                DropdownMenuItem(
                  value: PackageSort.dateNewest,
                  child: const Text('Newest'),
                ),
                DropdownMenuItem(
                  value: PackageSort.dateOldest,
                  child: const Text('Oldest'),
                ),
              ],
              onChanged: (v) => _viewModel.setSort(v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _packageGrid(List<PackageEntity> items, int cols) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No packages found.', style: TextStyle(color: gray)),
        ),
      );
    }
    if (cols == 1) {
      return Column(
        children: items
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _packageCard(p),
              ),
            )
            .toList(),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = _packageCard(items[i]);
      final b = i + 1 < items.length
          ? _packageCard(items[i + 1])
          : const SizedBox.shrink();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ],
        ),
      );
      rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }

  Widget _packageCard(PackageEntity p) {
    final c = widget.category;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackageDetailsScreen(package: p, category: c),
        ),
      ),
      onLongPress: () => _showDeleteDialog(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _packageImage(p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: title,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _catBadge(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.spec,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: gray),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Qty: ${p.quantity} in ${p.productLimit}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: title,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: gray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: gray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statusBadge(_computedStatus(p)),
                  if (p.createdBy.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'by ${p.createdBy}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: gray,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: purple),
              tooltip: 'Edit package',
              onPressed: () => _openEditPackage(p),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  StockStatus _computedStatus(PackageEntity p) {
    final limit = p.productLimit;
    final qty = p.quantity;
    if (limit <= 0 || qty == 0) return StockStatus.outOfStock;
    final pct = (qty / limit) * 100;
    if (pct >= 70) return StockStatus.highStock;
    if (pct >= 30) return StockStatus.midStock;
    return StockStatus.lowStock;
  }

  Widget _catBadge() {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _badgeCode,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: purple,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(StockStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stockBg(s),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stockLabel(s),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: stockFg(s),
        ),
      ),
    );
  }

  Widget _packageImage(PackageEntity p) {
    final c = widget.category;
    final images = p.productImages;

    if (images.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              (c.iconColor ?? const Color(0xFF6D28D9)).withValues(alpha: 0.85),
              (c.iconColor ?? const Color(0xFF6D28D9)).withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            c.icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 38,
          ),
        ),
      );
    }

    return SizedBox(
      width: 90,
      height: 90,
      child: images.length == 1
          ? _pkgSingleImage(images[0])
          : images.length == 2
          ? _pkgTwoImageMosaic(images)
          : _pkgThreeImageMosaic(images),
    );
  }

  Widget _pkgSingleImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: 90,
        height: 90,
        errorBuilder: (_, _, _) => Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: gray,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _pkgTwoImageMosaic(List<String> urls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _pkgMosaicTile(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _pkgMosaicTile(urls.length > 1 ? urls[1] : '')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pkgThreeImageMosaic(List<String> urls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: _pkgMosaicTile(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _pkgMosaicTile(urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(flex: 2, child: _pkgMosaicTile(urls[2])),
        ],
      ),
    );
  }

  Widget _pkgMosaicTile(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_outlined, color: gray, size: 16),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFF3F4F6),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: gray,
          size: 16,
        ),
      ),
    );
  }
}
