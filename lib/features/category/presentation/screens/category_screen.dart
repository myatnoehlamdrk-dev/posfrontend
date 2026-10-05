import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:get_it/get_it.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';
import 'package:posfrontend/features/category/presentation/screens/add_category_screen.dart';
import 'package:posfrontend/features/category/presentation/viewmodels/category_view_model.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:posfrontend/features/package/presentation/screens/package_screen.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';

class CategoryScreen extends StatefulWidget {
  final String inventoryType;

  const CategoryScreen({super.key, this.inventoryType = 'self'});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final CategoryViewModel _viewModel;


  String get _inventoryLabel {
    switch (widget.inventoryType) {
      case 'public':
        return 'Public Inventory';
      case 'self':
      default:
        return 'Self Inventory';
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = CategoryViewModel(
      repository: GetIt.instance<CategoryRepository>(),
      inventoryRepository: GetIt.instance<InventoryRepository>(),
      type: widget.inventoryType,
    );
  }

  Future<void> _openAddCategory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(inventoryType: widget.inventoryType),
      ),
    );
    if (result is Category) {
      _viewModel.addCategory(result);
    }
  }

  Future<void> _openEditCategory(Category category) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(
          inventoryType: widget.inventoryType,
          existingCategory: category,
        ),
      ),
    );
    if (result is Category) {
      _viewModel.updateCategory(result);
    }
  }

  void _showDeleteDialog(Category c) {
    bool deleting = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.t('Delete Category')),
              content: Text(
                context.l10n
                    .t('Are you sure you want to delete "{v1}"?')
                    .replaceAll('{v1}', (c.name).toString()),
              ),
              actions: [
                TextButton(
                  onPressed: deleting ? null : () => Navigator.pop(ctx),
                  child: Text(context.l10n.t('Cancel')),
                ),
                TextButton(
                  onPressed: deleting
                      ? null
                      : () async {
                          setDialogState(() => deleting = true);
                          Navigator.pop(ctx);
                          final success = await _viewModel.deleteCategory(c.id);
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
                      : Text(
                          context.l10n.t('Delete'),
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
    final p = context.palette;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _buildContent(isWide: isWide);

        if (isWide) {
          return Scaffold(
            backgroundColor: p.surface,
            floatingActionButton: FloatingActionButton(
              onPressed: _openAddCategory,
              backgroundColor: const Color(0xFF4FD1D9),
              child: const Icon(Icons.category, color: Colors.white),
            ),
            body: body,
          );
        }

        return Scaffold(
          backgroundColor: p.surface,
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddCategory,
            backgroundColor: const Color(0xFF4FD1D9),
            child: const Icon(Icons.category, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          body: body,
        );
      },
    );
  }

  Widget _buildContent({required bool isWide}) {
    final p = context.palette;
    return SafeArea(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final items = _viewModel.filtered;
          return Column(
            children: [
              AppScreenTopBar(
                title: _inventoryLabel,
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
                              child: CircularProgressIndicator(color: AppColors.brandPurpleDark),
                            ),
                          )
                        else if (_viewModel.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                _viewModel.errorMessage ??
                                    'Failed to load categories.',
                                style: TextStyle(color: p.textSecondary),
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (c, constraints) {
                              final cols = constraints.maxWidth >= 560 ? 2 : 1;
                              return _categoryGrid(items, cols);
                            },
                          ),
                        const SizedBox(height: 20),
                        _pagination(items.length),
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
    final p = context.palette;
    final style = TextStyle(fontSize: 13, color: p.textSecondary);
    return Wrap(
      children: [
        GestureDetector(
          onTap: () {},
          child: Text(
            context.l10n.t('Dashboard'),
            style: TextStyle(fontSize: 13, color: AppColors.brandPurpleDark),
          ),
        ),
        Text('  >  ', style: style),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            context.l10n.t('Inventory'),
            style: TextStyle(fontSize: 13, color: AppColors.brandPurpleDark),
          ),
        ),
        Text('  >  ', style: style),
        GestureDetector(
          onTap: () {},
          child: Text(
            _inventoryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.brandPurpleDark),
          ),
        ),
        Text('  >  ', style: style),
        Text(context.l10n.t('Categories'), style: style),
      ],
    );
  }

  Widget _headingRow() {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('Categories'),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CategorySort>(
              value: _viewModel.sort == CategorySort.nameAz
                  ? null
                  : _viewModel.sort,
              hint: Text(
                context.l10n.t('Sort'),
                style: TextStyle(color: p.textPrimary, fontSize: 14),
              ),
              style: TextStyle(color: p.textPrimary, fontSize: 14),
              items: [
                DropdownMenuItem(
                  value: CategorySort.dateNewest,
                  child: Text(context.l10n.t('Newest')),
                ),
                DropdownMenuItem(
                  value: CategorySort.dateOldest,
                  child: Text(context.l10n.t('Oldest')),
                ),
              ],
              onChanged: (v) => _viewModel.setSort(v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryGrid(List<Category> items, int cols) {
    final p = context.palette;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            context.l10n.t('No categories found.'),
            style: TextStyle(color: p.textSecondary),
          ),
        ),
      );
    }
    if (cols == 1) {
      return Column(
        children: items
            .map(
              (c) => Padding(
                key: ValueKey(c.id),
                padding: const EdgeInsets.only(bottom: 20),
                child: _categoryCard(c),
              ),
            )
            .toList(),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = _categoryCard(items[i]);
      final b = i + 1 < items.length
          ? _categoryCard(items[i + 1])
          : const SizedBox.shrink();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 20),
            Expanded(child: b),
          ],
        ),
      );
      rows.add(const SizedBox(height: 20));
    }
    return Column(children: rows);
  }

  Widget _categoryCard(Category c) {
    final p = context.palette;
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PackageScreen(category: c))),
      onLongPress: () => _showDeleteDialog(c),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: p.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _categoryImage(c),
                    Positioned(
                      left: -8,
                      bottom: -8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D28D9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _packageBadge(c.packageCount, c.packageLimit),
                      const SizedBox(height: 8),
                      Text(
                        c.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.brandPurpleDark),
                  tooltip: 'Edit category',
                  onPressed: () => _openEditCategory(c),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        context.l10n
                            .t('Created: {v1}')
                            .replaceAll('{v1}', (c.createdDate).toString()),
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                      if (c.createdBy.isNotEmpty)
                        Text(
                          context.l10n
                              .t('by {v1}')
                              .replaceAll('{v1}', (c.createdBy).toString()),
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      _statusBadge(c.active),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: p.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryImage(Category c) {
    final images = c.productImages;
    if (images.isEmpty) {
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6D28D9).withValues(alpha: 0.85),
              const Color(0xFF6D28D9).withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.category,
            color: Colors.white.withValues(alpha: 0.9),
            size: 42,
          ),
        ),
      );
    }

    return SizedBox(
      width: 110,
      height: 110,
      child: images.length == 1
          ? _singleImage(images[0])
          : images.length == 2
          ? _twoImageMosaic(images)
          : _threeImageMosaic(images),
    );
  }

  Widget _singleImage(String url) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: 110,
        height: 110,
        errorBuilder: (_, _, _) => Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: p.chipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: p.textSecondary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _twoImageMosaic(List<String> urls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mosaicTile(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _mosaicTile(urls.length > 1 ? urls[1] : '')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _threeImageMosaic(List<String> urls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: _mosaicTile(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _mosaicTile(urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(flex: 2, child: _mosaicTile(urls[2])),
        ],
      ),
    );
  }

  Widget _mosaicTile(String url) {
    final p = context.palette;
    if (url.isEmpty) {
      return Container(
        color: p.chipBg,
        child: Icon(Icons.image_outlined, color: p.textSecondary, size: 20),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => Container(
        color: p.chipBg,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: p.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _packageBadge(int count, int limit) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.selectionTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.l10n
            .t('{v1} in {v2}')
            .replaceAll('{v1}', (count).toString())
            .replaceAll('{v2}', (limit).toString()),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brandPurpleDark,
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? p.successBg : p.dangerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? context.l10n.t('Active') : context.l10n.t('Inactive'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? p.successFg : p.dangerFg,
        ),
      ),
    );
  }

  Widget _pagination(int shown) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n
                .t('First {v2} of {v1} categories')
                .replaceAll('{v1}', (_viewModel.totalCount).toString())
                .replaceAll('{v2}', (shown).toString()),
            style: TextStyle(fontSize: 13, color: p.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(Icons.chevron_left, color: p.textSecondary),
          onPressed: null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brandPurpleDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '1',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: p.textSecondary),
          onPressed: null,
        ),
      ],
    );
  }
}
