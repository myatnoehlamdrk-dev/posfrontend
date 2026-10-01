import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart';

class AssignProductToPackageViewModel extends BaseViewModel {
  final ProductRepository _productRepository;
  final PackageEntity package;

  AssignProductToPackageViewModel({
    required ProductRepository productRepository,
    required this.package,
  }) : _productRepository = productRepository;

  /// Upper bound for the single page this screen loads. The endpoint has no
  /// maximum, so this only caps how large a response the picker will ask for;
  /// a shop with more products than this would need real pagination.
  static const int _pageSize = 200;

  List<CatalogProductView> _allProducts = [];
  List<CatalogProductView> get allProducts => _allProducts;

  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;

  bool _isAssigning = false;
  bool get isAssigning => _isAssigning;

  int get selectedCount => _selectedIds.length;

  /// Every product in the shop that is not in a package yet, newest and oldest
  /// alike. The list is deliberately unsorted by recency on screen: the screen
  /// used to read only the first page of `/api/products`, whose default page
  /// size is 10, so any unassigned product older than the ten newest was never
  /// fetched and could not be assigned from here.
  List<CatalogProductView> get filtered {
    return _allProducts
        .where((p) => p.packageId.isEmpty || p.packageId == '—')
        .toList();
  }

  bool get allFilteredSelected {
    final items = filtered;
    return _selectedIds.length == items.length && items.isNotEmpty;
  }

  void toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    final items = filtered;
    if (_selectedIds.length == items.length) {
      _selectedIds.clear();
    } else {
      _selectedIds.addAll(items.map((p) => p.id));
    }
    notifyListeners();
  }

  Future<void> loadProducts() async {
    setLoading(true);
    resetError();
    try {
      // perPage defaults to 10 in the repository, which silently cut the list
      // off at the ten newest products. Ask for a page big enough to cover the
      // whole shop so an old unassigned product can still be assigned here.
      final response = await _productRepository.getProducts(
        perPage: _pageSize,
        cancelToken: cancelToken,
      );
      final rawList = response['data'];
      final List<dynamic> items = rawList is List ? rawList : [];
      _allProducts = items.map((json) {
        final map = json as Map<String, dynamic>;
        final id = map['id']?.toString() ?? '';
        final name = map['name']?.toString() ?? '';
        final brand = map['brand']?.toString() ?? '';
        final sku = map['sku']?.toString() ?? '';
        final price = (map['stock'] as num?)?.toDouble() ?? 0.0;
        final stock = (map['stock'] as num?)?.toInt() ?? 0;
        final isSet = map['isSet'] == true;
        final category = map['category']?.toString() ?? '';
        final packageId = map['packageId']?.toString() ?? '';
        final imageUrl = resolveMediaUrl(map['image']?.toString().trim());
        final createdBy = map['createdBy']?.toString() ?? '';
        final variantsRaw = map['variants'];
        final variantList = variantsRaw is List ? variantsRaw : [];
        return CatalogProductView(
          id: id,
          name: name,
          brand: brand,
          sku: sku,
          price: price,
          stock: stock,
          isSet: isSet,
          category: category,
          packageId: packageId,
          icon: CatalogProductView.iconFor(name),
          color: CatalogProductView.colorFor(name),
          imageUrl: imageUrl,
          variants: variantList.map((v) {
            final vm = v as Map<String, dynamic>;
            return ProductVariant(
              size: (vm['size'] as String?)?.trim() ?? '',
              color: (vm['color'] as String?)?.trim() ?? '',
              quantity: (vm['quantity'] as num?)?.toInt() ?? 0,
              price: (vm['price'] as num?)?.toDouble() ?? 0,
            );
          }).toList(),
          createdBy: createdBy,
        );
      }).toList();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load products: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<int> assignToPackage() async {
    if (_selectedIds.isEmpty) return 0;

    _isAssigning = true;
    resetError();
    notifyListeners();

    try {
      final dio = ApiClient.create();
      int successCount = 0;

      for (final productId in _selectedIds) {
        try {
          await dio.patch(
            '/products/$productId',
            data: {'packageId': int.tryParse(package.id)},
            cancelToken: cancelToken,
          );
          successCount++;
        } catch (_) {
          // Continue with other products
        }
      }

      _isAssigning = false;
      notifyListeners();
      return successCount;
    } on ApiException catch (e) {
      setError(e.message);
      _isAssigning = false;
      notifyListeners();
      return 0;
    } catch (e) {
      setError('Failed to assign products: $e');
      _isAssigning = false;
      notifyListeners();
      return 0;
    }
  }
}
