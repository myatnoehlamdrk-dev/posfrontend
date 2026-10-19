import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/core/utils/image_compressor.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/data/repositories/category_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/domain/entities/product_detail.dart';
import 'package:posfrontend/features/product/data/repositories/product_create_repository_impl.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';

class AddProductViewModel extends BaseViewModel with FormValidationMixin {
  final ProductCreateRepositoryImpl _repository = ProductCreateRepositoryImpl();
  final TextEditingController name = TextEditingController();
  final TextEditingController brand = TextEditingController();
  final TextEditingController sku = TextEditingController();
  final FocusNode imageFocus = FocusNode();

  bool _isSet = false;
  bool get isSet => _isSet;

  String _inventoryType = 'self';
  String get inventoryType => _inventoryType;

  String? _selectedSupplierId;
  String? get selectedSupplierId => _selectedSupplierId;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Category? _selectedCategory;
  Category? get selectedCategory => _selectedCategory;

  static const String uncategorizedLabel = 'Uncategorized';

  bool _uncategorized = false;
  bool get uncategorized => _uncategorized;

  List<PackageOption> _packages = [];
  List<PackageOption> get packages => _packages;

  PackageOption? _selectedPackage;
  PackageOption? get selectedPackage => _selectedPackage;

  List<SupplierOption> _suppliers = [];
  List<SupplierOption> get suppliers => _suppliers;

  File? _imageFile;
  File? get imageFile => _imageFile;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  String? _imageDeleteUrl;

  bool _uploading = false;
  bool get uploading => _uploading;

  /// Set when the user clears the photo. The backend ignores a missing
  /// image (it means "keep the current one"), so removal rides along as an
  /// explicit flag on the save payload.
  bool _imageRemoved = false;
  bool get imageRemoved => _imageRemoved;

  /// A photo was picked but its upload did not come back with a URL. Saving
  /// anyway would silently keep the *old* image, because the backend reads a
  /// missing image as "keep the current one".
  bool _uploadFailed = false;
  bool get uploadFailed => _uploadFailed;

  /// True when the last photo was kept on the API host instead of ImgBB.
  ///
  /// The upload succeeded, so the screen that called [pickAndUpload] shows the
  /// usual success message either way — this only decides whether it is the
  /// amber warning instead, because the file is not on a host every device
  /// can reach and will not outlive the machine holding it.
  bool _imageStoredLocally = false;
  bool get imageStoredLocally => _imageStoredLocally;

  /// True when the picked photo could not be reduced before it was uploaded.
  ///
  /// Nothing in the pipeline could decode it (HEIC and similar), so the
  /// camera original went over the wire — worth saying, since on a shop
  /// connection that is the difference between a second and a minute.
  bool _imageOversized = false;
  bool get imageOversized => _imageOversized;

  Key _imageKey = UniqueKey();
  Key get imageKey => _imageKey;

  final List<ProductCreateVariant> _variants = [
    ProductCreateVariant(size: 'Small', color: 'Black'),
  ];
  List<ProductCreateVariant> get variants => List.unmodifiable(_variants);

  static const List<String> sizeOptions = [
    'Individual',
    'Family Pack',
    'Small',
    'Medium',
    'Large',
    'XL',
    'Standard',
    'Premium',
    'Enterprise',
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

  void initFromProduct(ProductDetailEntity p) {
    name.text = p.name;
    brand.text = p.brand;
    sku.text = p.sku;
    _selectedSupplierId = (p.supplierId == '—' || p.supplierId.isEmpty)
        ? null
        : p.supplierId;
    _imageUrl = p.imageUrl;
    _imageDeleteUrl = p.imageDeleteUrl;
    _imageRemoved = false;
    _uploadFailed = false;
    _inventoryType = (p.inventoryType.isNotEmpty && p.inventoryType != '—')
        ? p.inventoryType
        : 'self';
    _isSet = p.isBundle == 'Yes';
    _variants.clear();
    for (final v in p.variants) {
      _variants.add(
        ProductCreateVariant(
          size: v.size,
          color: v.color,
          quantity: v.quantity,
          price: v.price,
        ),
      );
    }
    if (_variants.isEmpty) {
      _variants.add(ProductCreateVariant(size: 'Small', color: 'Black'));
    }
    notifyListeners();
  }

  Future<void> loadInitialData({ProductDetailEntity? existingProduct}) async {
    await Future.wait([loadSuppliers()]);
    final product = existingProduct;
    if (product != null) {
      initFromProduct(product);
      await loadCategories();
      if (product.categoryName.isNotEmpty) {
        final cat = _categories
            .where((c) => c.name == product.categoryName)
            .firstOrNull;
        if (cat != null) {
          await onCategoryChanged(cat);
          if (product.packageId.isNotEmpty && product.packageId != '—') {
            final pkg = _packages
                .where((pk) => pk.id == product.packageId)
                .firstOrNull;
            if (pkg != null) {
              _selectedPackage = pkg;
              notifyListeners();
            }
          }
        }
      }
      if (product.categoryName.isEmpty ||
          product.categoryName == uncategorizedLabel) {
        _uncategorized = true;
        notifyListeners();
      }
    } else {
      await loadCategories();
    }
  }

  Future<void> loadSuppliers() async {
    final list = await runAsync(
      (token) => _repository.getSuppliers(cancelToken: token),
    );
    if (list != null) _suppliers = list;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final cats = await CategoryRepositoryImpl().getCategories(
        type: _inventoryType,
      );
      _categories = cats;
      _selectedCategory = null;
      _uncategorized = false;
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
    _uncategorized = false;
    if (cat == null) {
      _packages = [];
      _selectedPackage = null;
      notifyListeners();
      return;
    }
    notifyListeners();
    final pkgs = await runAsync(
      (token) => _repository.getPackages(cat.id, cancelToken: token),
      showLoading: false,
    );
    _packages = pkgs ?? [];
    _selectedPackage = null;
    notifyListeners();
  }

  void onCategoryUnfiled() {
    onCategoryChanged(null);
    _uncategorized = true;
    notifyListeners();
  }

  void setInventoryType(String value) {
    _inventoryType = value;
    notifyListeners();
    loadCategories();
  }

  /// Fills the form from a purchase item. Only the fields both screens carry
  /// are copied: product name, stock (the first variant's quantity), price and
  /// supplier. Everything else stays for manual entry.
  void applyPurchaseItem(PurchaseOrderEntity order) {
    final productName = order.productName.trim();
    if (productName.isNotEmpty) name.text = productName;

    if (_variants.isEmpty) {
      _variants.add(ProductCreateVariant(size: 'Small', color: 'Black'));
    }
    _variants[0] = _variants.first.copyWith(
      quantity: order.quantity,
      price: order.unitPrice.toDouble(),
    );

    if (order.supplierId.isNotEmpty) {
      final match = _suppliers
          .where(
            (s) => s.id == order.supplierId || s.name == order.supplierName,
          )
          .firstOrNull;
      if (match != null) {
        _selectedSupplierId = match.id;
      } else if (order.supplierName.isNotEmpty) {
        _suppliers.insert(
          0,
          SupplierOption(id: order.supplierId, name: order.supplierName),
        );
        _selectedSupplierId = order.supplierId;
      }
    }
    notifyListeners();
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

  Future<void> pickAndUpload() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      // Native platforms shrink at pick time (cheap, in the platform
      // channel). Windows/Linux ignore these — imageCompressor covers them.
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (xfile == null) return;
    _imageFile = File(xfile.path);
    _imageKey = UniqueKey();
    _uploading = true;
    notifyListeners();
    try {
      final compressed = await compressImage(xfile, writePreviewFile: true);
      _imageFile = compressed.previewFile ?? _imageFile;
      _imageKey = UniqueKey();
      _imageOversized = compressed.oversized;
      notifyListeners();
      final result = await ImgbbRepositoryImpl().uploadImage(
        compressed.bytes,
        fileName: compressed.fileName,
      );
      _imageUrl = result.url;
      _imageDeleteUrl = result.deleteUrl;
      _uploadFailed = false;
      _imageStoredLocally = result.storedLocally;
      _imageKey = UniqueKey();
      notifyListeners();
    } on ApiException catch (e) {
      _uploadFailed = true;
      setError(e.message);
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  /// Clears the photo for this product.
  ///
  /// A remote copy may already exist, so the delete URL is dropped here and
  /// the backend retires the remote file when it writes the row.
  void removeImage() {
    _imageFile = null;
    _imageUrl = null;
    _imageDeleteUrl = null;
    _imageRemoved = true;
    _uploadFailed = false;
    _imageStoredLocally = false;
    _imageKey = UniqueKey();
    notifyListeners();
  }

  void onVariantChanged(int index, ProductCreateVariant v) {
    _variants[index] = v;
    notifyListeners();
  }

  void addVariant() {
    _variants.add(ProductCreateVariant(size: 'Small', color: 'Black'));
    notifyListeners();
  }

  void removeVariant(int index) {
    _variants.removeAt(index);
    notifyListeners();
  }

  Future<bool> save({ProductDetailEntity? existingProduct}) async {
    if (_uploading) {
      setError('Please wait for image upload to finish');
      return false;
    }
    if (_uploadFailed) {
      setError(
        'The image upload did not finish. Tap the photo to try again, or remove it.',
      );
      return false;
    }
    final productName = name.text.trim();
    if (productName.isEmpty) {
      setError('Product name is required');
      return false;
    }
    final isUpdate = existingProduct != null;
    // Create requires one complete variant. Update treats the product's own
    // rows differently: they are sent back as they are, and only rows the
    // user newly added must be filled in. Quick-sale rows carry no size, a
    // sold-out row has no quantity — filtering those out would drop them
    // from a payload the backend replaces wholesale (wiping the rows and
    // zeroing the stock). A product with nothing to send at all (only the
    // untouched placeholder row) skips variants/stock via
    // preserveStockAndVariants below instead of failing the save.
    final originCount = existingProduct?.variants.length ?? 0;
    final valid = <ProductCreateVariant>[
      for (var i = 0; i < _variants.length; i++)
        // The product's own rows are always included, whatever they hold —
        // a quick-sale variant has no size, a sold-out row has no quantity,
        // and dropping either from this list would delete it on the server
        // (update replaces the variants array wholesale). Only rows the
        // user just added must be complete.
        if (i < originCount ||
            (_variants[i].size.isNotEmpty &&
                _variants[i].quantity > 0 &&
                _variants[i].price > 0))
          _variants[i],
    ];
    if (valid.isEmpty && !isUpdate) {
      setError('Add at least one variant with a size, quantity and price');
      return false;
    }
    // Placement is required when creating, but only conditionally on update:
    // the payload carries the category nowhere (only packageId, which the
    // backend reads through package -> category), so a category selection
    // exists solely to filter the package list. On update, selecting nothing
    // means "keep the current placement" — packageId is omitted from the
    // payload and the backend leaves the package untouched. Requiring both
    // unconditionally made every product that was created without a
    // category/package permanently un-editable ("Category is required" on
    // every save, including a plain image removal).
    if (_selectedCategory == null && !_uncategorized) {
      if (!isUpdate || _selectedPackage != null) {
        setError('Category is required');
        return false;
      }
    } else if (_selectedCategory != null && _selectedPackage == null) {
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
      // Nothing of the product's to send back (placeholder-only form):
      // omit stock/variants so the server keeps both, rather than
      // replacing them with an empty list and zeroing the stock.
      preserveStockAndVariants: isUpdate && valid.isEmpty,
      sku: sku.text.trim(),
      supplierId: _selectedSupplierId ?? '',
      supplierName: _suppliers
          .firstWhere(
            (s) => s.id == (_selectedSupplierId ?? ''),
            orElse: () => const SupplierOption(id: '', name: ''),
          )
          .name,
      supplierContact: '',
      supplierSince: '',
      supplierAddress: '',
      imageDeleteUrl: _imageDeleteUrl ?? '',
      removeImage: _imageRemoved,
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
    imageFocus.dispose();
    super.dispose();
  }
}
