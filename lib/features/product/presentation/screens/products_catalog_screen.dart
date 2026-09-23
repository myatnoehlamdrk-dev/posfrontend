import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/category_products_screen.dart';
import 'package:posfrontend/features/product/presentation/viewmodels/products_catalog_view_model.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_grid.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_skeleton.dart';

class ProductsCatalogScreen extends StatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final ProductsCatalogViewModel _viewModel;
  late final PageController _hotPageController;
  int _hotIndex = 0;
  bool _hotPaused = false;
  bool _isSearchOpen = false;
  bool _disposed = false;
  static const Color bg = Color(0xFFF8F9FC);
  static const Color gray = Color(0xFF6B7280);
  static const Color purple = Color(0xFF6D28D9);
  static const Color titleColor = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _viewModel = ProductsCatalogViewModel();
    _hotPageController = PageController(initialPage: 5000);
    _viewModel.load();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_disposed) return;
      if (!mounted || _hotPaused) {
        _startAutoScroll();
        return;
      }
      final hotProducts = _viewModel.hotProducts;
      if (hotProducts.length > 1 && _hotPageController.hasClients) {
        _hotIndex = (_hotIndex + 1) % hotProducts.length;
        _hotPageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollCtrl.dispose();
    _viewModel.dispose();
    _search.dispose();
    _hotPageController.dispose();
    super.dispose();
  }

  void _openProduct(CatalogProductView p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: p.id),
      ),
    );
  }

  void _showDeleteDialog(CatalogProductView p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _viewModel.deleteProduct(p.id);
              if (!success && mounted && _viewModel.hasError) {
                showErrorSnackBar(context, _viewModel.errorMessage!);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              navigateToDashboard(context);
            }
          },
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 768;

              if (isWide) {
                return Scaffold(
                  backgroundColor: bg,
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => setState(() => _isSearchOpen = !_isSearchOpen),
                    backgroundColor: purple,
                    child: Icon(
                      _isSearchOpen ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                  ),
                  body: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          width: 240,
                          child: AppDrawer(activeItem: 'Product'),
                        ),
                        Expanded(child: _content()),
                      ],
                    ),
                  ),
                );
              }
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: bg,
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => _isSearchOpen = !_isSearchOpen),
                  backgroundColor: purple,
                  child: Icon(
                    _isSearchOpen ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                ),
                drawer: const AppDrawer(activeItem: 'Product'),
                body: SafeArea(child: _content()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _content() {
    final categories = _viewModel.categories;

    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                AppScreenTopBar(
                  title: 'Products',
                  showMenuButton: true,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: RefreshableBody(
                    scrollController: _scrollCtrl,
                    onRefresh: () => _viewModel.load(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: _buildBody(categories),
                    ),
                  ),
                ),
              ],
            ),
            if (_isSearchOpen)
              Positioned(
                top: 72,
                left: 24,
                right: 24,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Expanded(child: _searchField()),
                      const SizedBox(width: 8),
                      _iconButton(Icons.close, onTap: () {
                        setState(() {
                          _isSearchOpen = false;
                          _search.clear();
                          _viewModel.setSearchQuery('');
                        });
                      }),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(List<CategoryShowcaseData> categories) {
    if (_viewModel.isLoading && categories.isEmpty) {
      return const CategorySkeleton();
    }

    if (_viewModel.hasError && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Unable to load categories',
              style: const TextStyle(color: Colors.red, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _viewModel.load(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to see categories here',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_viewModel.hotProducts.isNotEmpty) ...[
          _hotCarousel(_viewModel.hotProducts),
          const SizedBox(height: 28),
        ],
        CategoryShowcaseGrid(
          categories: categories,
          onProductTap: _openProduct,
          onProductLongPress: _showDeleteDialog,
          onCategoryTap: (cat) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                categoryId: cat.id,
                categoryName: cat.name,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: IconButton(
        icon: Icon(icon, color: titleColor, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: _viewModel.setSearchQuery,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: const TextStyle(color: gray, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: gray, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: purple),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static const List<LinearGradient> _promoGradients = [
    LinearGradient(colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6)]),
    LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)]),
    LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF10B981)]),
    LinearGradient(colors: [Color(0xFFFDBA74), Color(0xFFF97316)]),
    LinearGradient(colors: [Color(0xFFA5B4FC), Color(0xFF6366F1)]),
  ];

  Widget _hotCarousel(List<CatalogProductView> items) {
    final loopCount = 10000;
    return RepaintBoundary(
      child: GestureDetector(
        onPanDown: (_) => setState(() => _hotPaused = true),
        onPanEnd: (_) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _hotPaused = false);
          });
        },
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                key: const PageStorageKey('hotCarousel'),
                controller: _hotPageController,
                itemCount: loopCount,
                onPageChanged: (i) => setState(() => _hotIndex = i % items.length),
                itemBuilder: (ctx, i) =>
                    _hotBanner(items[i % items.length], i),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _hotIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _hotIndex ? purple : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hotBanner(CatalogProductView p, int index) {
    final gradient = _promoGradients[index % _promoGradients.length];
    final accent = Color.lerp(gradient.colors[0], gradient.colors[1], 0.6)!;
    final hasImage = (p.imageUrl ?? '').isNotEmpty;
    final radius = 30.0;
    return GestureDetector(
      onTap: () => _openProduct(p),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        // Isometric/perspective tilt of the whole card (mockup showcase).
        child: Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-0.09)
            ..rotateY(0.035),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // — Clay / glass card —
              Container(
                width: double.infinity,
                height: 194,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 26,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(-2, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 126,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.category.isEmpty ? 'Featured' : p.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            PriceText(
                              p.price,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B21B6),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    gradient.colors[1],
                                    accent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Shop Now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 90),
                  ],
                ),
              ),
              // Clay volumetric shading (top highlight, base tone).
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.05),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Glossy glass sheen across the whole card.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.07),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Soft ambient shadow under the product area.
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 150,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: RadialGradient(
                      radius: 1.1,
                      colors: [
                        Colors.black.withValues(alpha: 0.14),
                        Colors.black.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // The product itself, sitting on the card.
              Positioned(
                right: 6,
                top: 10,
                bottom: 10,
                child: SizedBox(
                  width: 158,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: hasImage
                        ? _GradientBlendedImage(
                            imageUrl: p.imageUrl!,
                            width: 158,
                            gradient: gradient,
                            errorFallback: _promoBadge(p, gradient),
                          )
                        : _promoBadge(p, gradient),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoBadge(CatalogProductView p, LinearGradient gradient) {
    final accent = Color.lerp(gradient.colors[0], const Color(0xFF111827), 0.7)!;
    return Center(
      child: Icon(
        p.icon,
        color: accent,
        size: 64,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
          ),
        ],
      ),
    );
  }
}

class _GradientBlendedImage extends StatefulWidget {
  const _GradientBlendedImage({
    required this.imageUrl,
    required this.width,
    required this.gradient,
    required this.errorFallback,
  });

  final String imageUrl;
  final double width;
  final LinearGradient gradient;
  final Widget errorFallback;

  @override
  State<_GradientBlendedImage> createState() => _GradientBlendedImageState();
}

class _GradientBlendedImageState extends State<_GradientBlendedImage> {
  ui.Image? _image;
  bool _failed = false;
  ImageStream? _stream;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _image = info.image);
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _load(widget.imageUrl);
  }

  @override
  void didUpdateWidget(_GradientBlendedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _stream?.removeListener(_listener);
      _load(widget.imageUrl);
    }
  }

  void _load(String url) {
    if (!mounted) return;
    _failed = false;
    _image = null;
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    _stream = stream;
    stream.addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.errorFallback;
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    return CustomPaint(
      size: Size(widget.width, double.infinity),
      painter: _GradientColorImagePainter(image),
    );
  }
}

class _GradientColorImagePainter extends CustomPainter {
  _GradientColorImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final base = math.min(
      size.width / src.width,
      size.height / src.height,
    );
    // Oversize slightly so the photo fills the whole image area and no
    // photo border/edge line is visible.
    final target = base * 1.12;
    final dstW = src.width * target;
    final dstH = src.height * target;
    // Bias the photo toward the top while keeping it fully visible.
    var cy = size.height * 0.42;
    if (cy - dstH / 2 < 0) cy = dstH / 2;
    final dst = Rect.fromCenter(
      center: Offset(size.width / 2, cy),
      width: dstW,
      height: dstH,
    );
    final box = Offset.zero & size;

    // Soft white glow behind the product so it pops off the pastel card.
    canvas.drawRect(
      box,
      Paint()
        ..shader = const RadialGradient(
          radius: 1.0,
          colors: [Color(0x66FFFFFF), Colors.transparent],
          stops: [0.0, 0.75],
        ).createShader(box),
    );

    // Soft contact shadow beneath the product for depth.
    final shadowRect = Rect.fromLTWH(
      dst.left - 10,
      dst.bottom - 6,
      dst.width + 20,
      34,
    );
    canvas.drawRect(
      shadowRect,
      Paint()
        ..shader = const RadialGradient(
          radius: 1.0,
          colors: [Color(0x33000000), Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(shadowRect),
    );

    // The product itself, above the board layers, soft at the edges.
    canvas.saveLayer(
      box,
      Paint()..color = const Color.fromRGBO(0, 0, 0, 0.82),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GradientColorImagePainter oldDelegate) =>
      oldDelegate.image != image;
}
