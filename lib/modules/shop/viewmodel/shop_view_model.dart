import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository.dart';

class ShopViewModel extends BaseViewModel {
  final ShopLocalRepository _repository;
  final ShopApiRepository _apiRepository;

  ShopViewModel({
    required ShopLocalRepository repository,
    required ShopApiRepository apiRepository,
  })  : _repository = repository,
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

  // Mode: 'create' (new shop form) or 'existing' (pick from database).
  String _mode = 'create';
  String get mode => _mode;

  void setMode(String mode) {
    if (_mode == mode) return;
    _mode = mode;
    if (mode == 'existing') {
      loadShops();
    }
    notifyListeners();
  }

  List<Shop> _shops = const [];
  List<Shop> get shops => _shops;

  bool _isLoadingShops = false;
  bool get isLoadingShops => _isLoadingShops;

  Shop? _selectedShop;
  Shop? get selectedShop => _selectedShop;

  void selectExistingShop(Shop shop) {
    _selectedShop = shop;
    notifyListeners();
  }

  Future<void> loadShops() async {
    _isLoadingShops = true;
    notifyListeners();
    try {
      _shops = await _apiRepository.getShops();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load shops: $e');
    } finally {
      _isLoadingShops = false;
      notifyListeners();
    }
  }

  /// Persist a chosen existing shop (id + name) for the registration step.
  Future<void> saveSelectedShop() async {
    if (_selectedShop == null) return;
    await _repository.saveShop(
      Shop(
        id: _selectedShop!.id,
        name: _selectedShop!.name,
        type: _selectedShop!.type,
        physicalAddress: _selectedShop!.physicalAddress,
        ownerInformation: _selectedShop!.ownerInformation,
      ),
    );
    _isShopCreated = true;
    notifyListeners();
  }

  final Map<String, String?> _fieldErrors = {};
  Map<String, String?> get fieldErrors => Map.unmodifiable(_fieldErrors);

  void setLogo(String? base64) {
    _logoData = base64;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    _clearError('name');
  }

  void setType(String? value) {
    _type = value;
    _clearError('type');
    notifyListeners();
  }

  void setPhysicalAddress(String value) {
    _physicalAddress = value;
    _clearError('physicalAddress');
  }

  void setOwnerName(String value) {
    _ownerName = value;
    _clearError('ownerName');
  }

  void setOwnerEmail(String value) {
    _ownerEmail = value;
    _clearError('ownerEmail');
  }

  void setOwnerPhone(String value) {
    _ownerPhone = value;
    _clearError('ownerPhone');
  }

  void _clearError(String key) {
    if (_fieldErrors.containsKey(key)) {
      _fieldErrors.remove(key);
      notifyListeners();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  bool validate() {
    _fieldErrors.clear();

    if (_name.trim().isEmpty) {
      _fieldErrors['name'] = 'Shop name is required';
    }
    if (_type == null || _type!.trim().isEmpty) {
      _fieldErrors['type'] = 'Shop type is required';
    }
    if (_physicalAddress.trim().isEmpty) {
      _fieldErrors['physicalAddress'] = 'Physical address is required';
    }
    if (_ownerName.trim().isEmpty) {
      _fieldErrors['ownerName'] = "Owner's name is required";
    }
    if (_ownerEmail.trim().isEmpty) {
      _fieldErrors['ownerEmail'] = "Owner's email is required";
    } else if (!_isValidEmail(_ownerEmail)) {
      _fieldErrors['ownerEmail'] = 'Enter a valid email';
    }
    if (_ownerPhone.trim().isEmpty) {
      _fieldErrors['ownerPhone'] = "Owner's phone is required";
    }

    notifyListeners();
    return _fieldErrors.isEmpty;
  }

  Future<bool> createShop() async {
    resetError();
    if (!validate()) {
      setError('Please complete all required fields');
      return false;
    }

    setLoading(true);
    try {
      final shop = Shop(
        logoData: _logoData,
        name: _name.trim(),
        type: _type!,
        physicalAddress: _physicalAddress.trim(),
        ownerInformation: OwnerInformation(
          name: _ownerName.trim(),
          email: _ownerEmail.trim(),
          phone: _ownerPhone.trim(),
        ),
      );

      await _repository.saveShop(shop);
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

  Future<void> loadSavedShop() async {
    setLoading(true);
    try {
      final shop = await _repository.getShop();
      if (shop != null) {
        _logoData = shop.logoData;
        _logoUrl = shop.logoUrl;
        _name = shop.name;
        _type = shop.type;
        _physicalAddress = shop.physicalAddress;
        _ownerName = shop.ownerInformation.name;
        _ownerEmail = shop.ownerInformation.email;
        _ownerPhone = shop.ownerInformation.phone;
        _isShopCreated = true;
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to load saved shop: $e');
    } finally {
      setLoading(false);
    }
  }
}
