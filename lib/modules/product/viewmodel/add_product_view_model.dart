import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/modules/product/model/product_create_models.dart';
import 'package:posfrontend/modules/product/model/product_detail_models.dart' hide ProductVariant;
import 'package:posfrontend/modules/product/repository/product_create_repository_impl.dart';

class AddProductViewModel extends BaseViewModel with FormValidationMixin {
  final ProductCreateRepositoryImpl _repository = ProductCreateRepositoryImpl();
  final TextEditingController name = TextEditingController();
  final TextEditingController brand = TextEditingController();
  final TextEditingController sku = TextEditingController();
  final TextEditingController productSearch = TextEditingController();
  final FocusNode imageFocus = FocusNode();

  bool _isSet = false;
  bool get isSet => _isSet;

  String _inventoryType = 'self';
  String get inventoryType => _inventoryType;

  String? _selectedSupplierId;
  String? get selectedSupplierId => _selectedSupplierId;

  List<ProductSearchResult> _searchResults = [];
  List<ProductSearchResult> get searchResults => _searchResults;

  bool _showSearchResults = false;
  bool get showSearchResults => _showSearchResults;

  String? _selectedPurchaseItemId;
  String? get selectedPurchaseItemId => _selectedPurchaseItemId;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Category? _selectedCategory;
  Category? get selectedCategory => _selectedCategory;

  List<PackageOption> _packages = [];
  List<PackageOption> get packages => _packages;

  PackageOption? _selectedPackage;
  PackageOption? get selectedPackage => _selectedPackage;

  List<SupplierOption> _suppliers = [];
  List<SupplierOption> get suppliers => _suppliers;

  List<PendingPurchaseItem> _pendingPurchaseItems = [];
  List<PendingPurchaseItem> get pendingPurchaseItems => _pendingPurchaseItems;

  bool _loadingPurchaseItems = false;
  bool get loadingPurchaseItems => _loadingPurchaseItems;

  File? _imageFile;
  File? get imageFile => _imageFile;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  String? _imageDeleteUrl;

  bool _uploading = false;
  bool get uploading => _uploading;

  Key _imageKey = UniqueKey();
  Key get imageKey => _imageKey;

  final List<ProductVariant> _variants = [
    ProductVariant(size: 'Small', color: 'Black'),
  ];
  List<ProductVariant> get variants => List.unmodifiable(_variants);

  static const List<String> sizeOptions = [
    'Individual', 'Family Pack', 'Small', 'Medium', 'Large',
    'XL', 'Standard', 'Premium', 'Enterprise',
  ];

  static const List<ProductColorOption> colorOptions = [
    ProductColorOption('Black', Color(0xFF000000)),
    ProductColorOption('White', Color(0xFFFFFFFF)),
    ProductColorOption('Gray', Color(0xFF808080)),
    ProductColorOption('Navy Blue', Color(0xFF000080)),
    ProductColorOption('Royal Blue', Color(0xFF4169E1)),
    ProductColorOption('Red', Color(0xFFE53935)),
    ProductColorOption('Green', Color(0xFF43A047)),
    ProductColorOption('Yellow', Color(0xFFFDD835)),
    ProductColorOption('Orange', Color(0xFFFB8C00)),
    ProductColorOption('Brown', Color(0xFF795548)),
  ];

  void initFromProduct(ProductDetail p) {
    name.text = p.name;
    brand.text = p.brand;
    sku.text = p.sku;
    _selectedSupplierId = (p.supplierId == '—' || p.supplierId.isEmpty) ? null : p.supplierId;
    _imageUrl = p.imageUrl;
    _imageDeleteUrl = p.imageDeleteUrl;
    _inventoryType = (p.inventoryType.isNotEmpty && p.inventoryType != '—') ? p.inventoryType : 'self';
    _isSet = p.isBundle == 'Yes';
    _variants.clear();
    for (final v in p.variants) {
      _variants.add(ProductVariant(
        size: v.size, color: v.color, quantity: v.quantity, price: v.price,
      ));
    }
    if (_variants.isEmpty) {
      _variants.add(ProductVariant(size: 'Small', color: 'Black'));
    }
    notifyListeners();
  }

  Future<void> loadInitialData({ProductDetail? existingProduct}) async {
    await Future.wait([loadSuppliers(), loadPendingPurchaseItems()]);
    final product = existingProduct;
    if (product != null) {
      initFromProduct(product);
      await loadCategories();
      if (product.categoryName.isNotEmpty) {
        final cat = _categories.where((c) => c.name == product.categoryName).firstOrNull;
        if (cat != null) {
          await onCategoryChanged(cat);
          if (product.packageId.isNotEmpty && product.packageId != '—') {
            final pkg = _packages.where((pk) => pk.id == product.packageId).firstOrNull;
            if (pkg != null) {
              _selectedPackage = pkg;
              notifyListeners();
            }
          }
        }
      }
    } else {
      await loadCategories();
    }
  }

  Future<void> loadSuppliers() async {
    final list = await runAsync((token) => _repository.getSuppliers(cancelToken: token));
    if (list != null) _suppliers = list;
    notifyListeners();
  }

  Future<void> loadPendingPurchaseItems() async {
    _loadingPurchaseItems = true;
    notifyListeners();
    final list = await runAsync((token) => _repository.getPendingPurchaseItems(cancelToken: token));
    _pendingPurchaseItems = list ?? [];
    _loadingPurchaseItems = false;
    notifyListeners();
  }

  void selectPurchaseItem(PendingPurchaseItem item) {
    _selectedPurchaseItemId = item.id;
    name.text = item.productName;
    if (item.supplierId.isNotEmpty) _selectedSupplierId = item.supplierId;
    _variants.clear();
    _variants.add(ProductVariant(
      size: 'Regular', color: '',
      quantity: item.quantity, price: item.unitPrice.toDouble(),
    ));
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      _showSearchResults = false;
      notifyListeners();
      return;
    }
    final results = await runAsync((token) => _repository.searchProducts(query, cancelToken: token), showLoading: false);
    _searchResults = results ?? [];
    _showSearchResults = _searchResults.isNotEmpty;
    notifyListeners();
  }

  void selectProduct(ProductSearchResult product) {
    name.text = product.name;
    brand.text = product.brand;
    sku.text = product.sku;
    _selectedSupplierId = product.supplierId;
    _imageUrl = product.imageUrl;
    _isSet = product.isSet;
    _inventoryType = product.inventoryType.isNotEmpty ? product.inventoryType : 'self';
    _showSearchResults = false;
    _searchResults = [];
    productSearch.clear();
    _variants.clear();
    if (product.variants.isNotEmpty) {
      for (final v in product.variants) {
        _variants.add(ProductVariant(
          size: (v['size'] ?? '').toString(),
          color: (v['color'] ?? '').toString(),
          quantity: v['quantity'] as int? ?? 0,
          price: (v['price'] as num?)?.toDouble() ?? 0.0,
        ));
      }
    } else {
      _variants.add(ProductVariant(
        size: product.size.isNotEmpty ? product.size : 'Small',
        color: product.color.isNotEmpty ? product.color : 'Black',
      ));
    }
    notifyListeners();
  }

  void setSearchCategoryAndPackage(ProductSearchResult product) async {
    await loadCategories();
    if (product.categoryId.isNotEmpty) {
      final cat = _categories.where((c) => c.id == product.categoryId).firstOrNull;
      if (cat != null) {
        await onCategoryChanged(cat);
        if (product.packageId.isNotEmpty) {
          final pkg = _packages.where((p) => p.id == product.packageId).firstOrNull;
          if (pkg != null) {
            _selectedPackage = pkg;
            notifyListeners();
          }
        }
      }
    }
  }

  Future<void> loadCategories() async {
    try {
      final cats = await CategoryRepositoryImpl().getCategories(type: _inventoryType);
      _categories = cats;
      _selectedCategory = null;
      _packages = [];
      _selectedPackage = null;
      notifyListeners();
    } on ApiException catch (e) {
      setError('Failed to load categories: ${e.message}');
    } catch (e) {
      setError('Failed to load categories: ${formatApiError(e)}');
    }
  }

  Future<void> onCategoryChanged(Category? cat) async {
    _selectedCategory = cat;
    if (cat == null) {
      _packages = [];
      _selectedPackage = null;
      notifyListeners();
      return;
    }
    notifyListeners();
    final pkgs = await runAsync((token) => _repository.getPackages(cat.id, cancelToken: token), showLoading: false);
    _packages = pkgs ?? [];
    _selectedPackage = null;
    notifyListeners();
  }

  void setInventoryType(String value) {
    _inventoryType = value;
    notifyListeners();
    loadCategories();
  }

  void setIsSet(bool value) {
    _isSet = value;
    notifyListeners();
  }

  void setSelectedSupplier(String? id) {
    _selectedSupplierId = id;
    notifyListeners();
  }

  void setSelectedPackage(PackageOption? pkg) {
    _selectedPackage = pkg;
    notifyListeners();
  }

  void addSupplier(SupplierOption supplier) {
    _suppliers.insert(0, supplier);
    _selectedSupplierId = supplier.id;
    notifyListeners();
  }

  void dismissSearch() {
    _showSearchResults = false;
    _searchResults = [];
    notifyListeners();
  }

  Future<void> pickAndUpload() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    _imageFile = File(xfile.path);
    _imageKey = UniqueKey();
    _uploading = true;
    notifyListeners();
    try {
      final result = await ImgbbRepositoryImpl().uploadImage(bytes, fileName: xfile.name);
      _imageUrl = result.url;
      _imageDeleteUrl = result.deleteUrl;
      _imageKey = UniqueKey();
      notifyListeners();
    } on ApiException catch (e) {
      setError(e.message);
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  void onVariantChanged(int index, ProductVariant v) {
    _variants[index] = v;
    notifyListeners();
  }

  void addVariant() {
    _variants.add(ProductVariant(size: 'Small', color: 'Black'));
    notifyListeners();
  }

  void removeVariant(int index) {
    _variants.removeAt(index);
    notifyListeners();
  }

  Future<bool> save({ProductDetail? existingProduct}) async {
    if (_uploading) {
      setError('Please wait for image upload to finish');
      return false;
    }
    final productName = name.text.trim();
    if (productName.isEmpty) {
      setError('Product name is required');
      return false;
    }
    final valid = _variants
        .where((v) => v.size.isNotEmpty && v.quantity > 0 && v.price > 0)
        .toList();
    if (valid.isEmpty) {
      setError('Add at least one variant with a size, quantity and price');
      return false;
    }
    if (_selectedCategory == null) {
      setError('Category is required');
      return false;
    }
    if (_selectedPackage == null) {
      setError('Package is required');
      return false;
    }

    final req = ProductCreateRequest(
      isSet: _isSet,
      name: productName,
      imageUrl: _imageUrl ?? '',
      brand: brand.text.trim(),
      inventoryType: _inventoryType,
      categoryId: _selectedCategory?.id ?? '',
      packageId: _selectedPackage?.id ?? '',
      variants: valid,
      sku: sku.text.trim(),
      supplierId: _selectedSupplierId ?? '',
      supplierName: _suppliers
          .firstWhere((s) => s.id == (_selectedSupplierId ?? ''),
              orElse: () => const SupplierOption(id: '', name: ''))
          .name,
      supplierContact: '',
      supplierSince: '',
      supplierAddress: '',
      imageDeleteUrl: _imageDeleteUrl ?? '',
      purchaseItemId: _selectedPurchaseItemId ?? '',
    );

    try {
      if (existingProduct != null) {
        await _repository.updateProduct(existingProduct.id, req);
      } else {
        await _repository.createProduct(req);
      }
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError(formatApiError(e));
      return false;
    }
  }

  @override
  void dispose() {
    name.dispose();
    brand.dispose();
    sku.dispose();
    productSearch.dispose();
    imageFocus.dispose();
    super.dispose();
  }
}
