import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart'
    as old_shop;
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

class ShopViewModel extends BaseViewModel with FormValidationMixin {
  final ShopLocalRepository _localRepository;
  final ShopApiRepository _apiRepository;

  ShopViewModel({
    required ShopLocalRepository localRepository,
    required ShopApiRepository apiRepository,
  }) : _localRepository = localRepository,
       _apiRepository = apiRepository;

  String? _logoData;
  String? get logoData => _logoData;

  String? _logoUrl;
  String? get logoUrl => _logoUrl;

  String _name = '';
  String get name => _name;

  String? _type;
  String? get type => _type;

  String _physicalAddress = '';
  String get physicalAddress => _physicalAddress;

  String _ownerName = '';
  String get ownerName => _ownerName;

  String _ownerEmail = '';
  String get ownerEmail => _ownerEmail;

  String _ownerPhone = '';
  String get ownerPhone => _ownerPhone;

  bool _isShopCreated = false;
  bool get isShopCreated => _isShopCreated;

  bool get canProceedToRegister => _isShopCreated;

  String _mode = 'create';
  String get mode => _mode;

  void setMode(String mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  List<old_shop.Shop> _shops = const [];
  List<old_shop.Shop> get shops => _shops;

  bool _shopsLoaded = false;
  bool get shopsLoaded => _shopsLoaded;

  bool _isLoadingShops = false;
  bool get isLoadingShops => _isLoadingShops;

  old_shop.Shop? _selectedOldShop;
  old_shop.Shop? get selectedOldShop => _selectedOldShop;

  void selectExistingShop(old_shop.Shop shop) {
    _selectedOldShop = shop;
    notifyListeners();
  }

  void reset() {
    _logoData = null;
    _logoUrl = null;
    _name = '';
    _type = null;
    _physicalAddress = '';
    _ownerName = '';
    _ownerEmail = '';
    _ownerPhone = '';
    _isShopCreated = false;
    _mode = 'create';
    _shopsRequestId++;
    _shops = const [];
    _shopsLoaded = false;
    _selectedOldShop = null;
    resetError();
    clearAllFieldErrors();
    notifyListeners();
  }

  int _shopsRequestId = 0;

  Future<void> loadShops({String? query}) async {
    _shopsRequestId++;
    final requestId = _shopsRequestId;
    _isLoadingShops = true;
    notifyListeners();
    try {
      final result = await _apiRepository.getShops(
        query: query,
        cancelToken: cancelToken,
      );
      if (requestId != _shopsRequestId) return;
      _shops = result;
      _shopsLoaded = true;
    } on ApiException catch (e) {
      if (requestId != _shopsRequestId) return;
      setError(e.message);
    } catch (e) {
      if (requestId != _shopsRequestId) return;
      setError('Failed to load shops: $e');
    } finally {
      if (requestId == _shopsRequestId) {
        _isLoadingShops = false;
        notifyListeners();
      }
    }
  }

  void clearShops() {
    _shopsRequestId++;
    _shops = const [];
    _shopsLoaded = false;
    _isLoadingShops = false;
    _selectedOldShop = null;
    resetError();
    notifyListeners();
  }

  Future<void> saveSelectedShop() async {
    if (_selectedOldShop == null) return;
    await _localRepository.saveShop(
      old_shop.Shop(
        id: _selectedOldShop!.id,
        name: _selectedOldShop!.name,
        type: _selectedOldShop!.type,
        physicalAddress: _selectedOldShop!.physicalAddress,
        ownerInformation: _selectedOldShop!.ownerInformation,
      ),
    );
    _isShopCreated = true;
    notifyListeners();
  }

  void setLogo(String? base64) {
    _logoData = base64;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    clearFieldError('name');
  }

  void setType(String? value) {
    _type = value;
    clearFieldError('type');
    notifyListeners();
  }

  void setPhysicalAddress(String value) {
    _physicalAddress = value;
    clearFieldError('physicalAddress');
  }

  void setOwnerName(String value) {
    _ownerName = value;
    clearFieldError('ownerName');
  }

  void setOwnerEmail(String value) {
    _ownerEmail = value;
    clearFieldError('ownerEmail');
  }

  void setOwnerPhone(String value) {
    _ownerPhone = value;
    clearFieldError('ownerPhone');
  }

  bool validate() {
    clearAllFieldErrors();

    if (_name.trim().isEmpty) {
      setFieldError('name', 'Shop name is required');
    }
    if (_type == null || _type!.trim().isEmpty) {
      setFieldError('type', 'Shop type is required');
    }
    if (_physicalAddress.trim().isEmpty) {
      setFieldError('physicalAddress', 'Physical address is required');
    }
    if (_ownerName.trim().isEmpty) {
      setFieldError('ownerName', "Owner's name is required");
    }
    if (_ownerEmail.trim().isEmpty) {
      setFieldError('ownerEmail', "Owner's email is required");
    } else if (!isValidEmail(_ownerEmail)) {
      setFieldError('ownerEmail', 'Enter a valid email');
    }
    if (_ownerPhone.trim().isEmpty) {
      setFieldError('ownerPhone', "Owner's phone is required");
    }

    notifyListeners();
    return fieldErrors.isEmpty;
  }

  Future<bool> createShop() async {
    resetError();
    if (!validate()) {
      setError('Please complete all required fields');
      return false;
    }

    setLoading(true);
    try {
      final shop = old_shop.Shop(
        logoData: _logoData,
        name: _name.trim(),
        type: _type!,
        physicalAddress: _physicalAddress.trim(),
        ownerInformation: old_shop.OwnerInformation(
          name: _ownerName.trim(),
          email: _ownerEmail.trim(),
          phone: _ownerPhone.trim(),
        ),
      );

      await _localRepository.saveShop(shop);
      _isShopCreated = true;
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to save shop locally: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
