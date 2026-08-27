import 'dart:convert';

import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/register/model/register_request.dart';
import 'package:posfrontend/modules/register/model/user_model.dart';
import 'package:posfrontend/modules/register/repository/auth_repository.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';

class RegisterViewModel extends BaseViewModel {
  final ShopLocalRepository _shopRepository;
  final ShopApiRepository _shopApiRepository;
  final ImgbbRepository _imgbbRepository;
  final AuthRepository _authRepository;

  RegisterViewModel({
    required ShopLocalRepository shopRepository,
    required ShopApiRepository shopApiRepository,
    required ImgbbRepository imgbbRepository,
    required AuthRepository authRepository,
  })  : _shopRepository = shopRepository,
        _shopApiRepository = shopApiRepository,
        _imgbbRepository = imgbbRepository,
        _authRepository = authRepository;

  // Read-only shop context (fetched from local storage).
  Shop? _shop;
  Shop? get shop => _shop;
  String? get shopName => _shop?.name;
  String? get shopType => _shop?.type;

  User? _user;
  User? get user => _user;

  // Registration form fields.
  String _name = '';
  String _email = '';
  String _password = '';
  String _phone = '';
  String _social = '';
  String _role = '';
  String _address = '';
  String _nrc = '';
  String _billingWay = '';
  String _dob = '';
  String? _gender;

  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get phone => _phone;
  String get social => _social;
  String get role => _role;
  String get address => _address;
  String get nrc => _nrc;
  String get billingWay => _billingWay;
  String get dob => _dob;
  String? get gender => _gender;

  final Map<String, String?> _fieldErrors = {};
  Map<String, String?> get fieldErrors => Map.unmodifiable(_fieldErrors);

  void setName(String value) {
    _name = value;
    _clearError('name');
  }

  void setEmail(String value) {
    _email = value;
    _clearError('email');
  }

  void setPassword(String value) {
    _password = value;
    _clearError('password');
  }

  void setPhone(String value) {
    _phone = value;
    _clearError('phone');
  }

  void setSocial(String value) {
    _social = value;
    _clearError('social');
  }

  void setRole(String value) {
    _role = value;
    _clearError('role');
  }

  void setAddress(String value) {
    _address = value;
    _clearError('address');
  }

  void setNrc(String value) {
    _nrc = value;
    _clearError('nrc');
  }

  void setBillingWay(String value) {
    _billingWay = value;
    _clearError('billingWay');
  }

  void setDob(String value) {
    _dob = value;
    _clearError('dob');
  }

  void setGender(String? value) {
    _gender = value;
    _clearError('gender');
    notifyListeners();
  }

  void _clearError(String key) {
    if (_fieldErrors.containsKey(key)) {
      _fieldErrors.remove(key);
      notifyListeners();
    }
  }

  Future<void> loadShop() async {
    setLoading(true);
    try {
      _shop = await _shopRepository.getShop();
      notifyListeners();
    } catch (e) {
      setError('Failed to load shop: $e');
    } finally {
      setLoading(false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  /// Required: full name, email, password, billing way. All others may be null.
  bool validate() {
    _fieldErrors.clear();

    if (_name.trim().isEmpty) {
      _fieldErrors['name'] = 'Full name is required';
    }
    if (_email.trim().isEmpty) {
      _fieldErrors['email'] = 'Email is required';
    } else if (!_isValidEmail(_email)) {
      _fieldErrors['email'] = 'Enter a valid email';
    }
    if (_password.isEmpty) {
      _fieldErrors['password'] = 'Password is required';
    }
    if (_billingWay.trim().isEmpty) {
      _fieldErrors['billingWay'] = 'Billing way is required';
    }

    notifyListeners();
    return _fieldErrors.isEmpty;
  }

  Future<bool> register() async {
    resetError();
    if (!validate()) {
      setError('Please complete all required fields');
      return false;
    }

    setLoading(true);
    try {
      // Shop may already be loaded; otherwise read from local storage.
      final localShop = _shop ?? await _shopRepository.getShop();
      if (localShop == null) {
        setError('No shop found. Please create a shop first.');
        return false;
      }

      // An existing shop (selected from the database) already has an id,
      // so we must NOT create a new one — just reuse its id.
      final bool isExistingShop =
          localShop.id != null && localShop.id!.isNotEmpty;
      String shopId;

      if (isExistingShop) {
        shopId = localShop.id!;
      } else {
        // 1) Upload the picked logo to ImgBB (only if an image was selected).
        var shop = localShop;
        if (shop.logoData != null && shop.logoData!.isNotEmpty) {
          final bytes = base64Decode(shop.logoData!);
          final logoUrl = await _imgbbRepository.uploadImage(
            bytes,
            fileName: 'shop_logo.jpg',
          );
          shop = shop.copyWith(logoUrl: logoUrl);
          await _shopRepository.saveShop(shop);
        }

        // 2) Shop controller: persist the shop (with logo URL) on the backend.
        final createdShop = await _shopApiRepository.createShop(shop);
        await _shopRepository.saveShop(createdShop);
        _shop = createdShop;
        notifyListeners();
        shopId = createdShop.id!;
      }

      // 3) Auth controller: register the user referencing the shop.
      final user = await _authRepository.register(
        RegisterRequest(
          fullName: _name.trim(),
          email: _email.trim(),
          password: _password,
          phone: _phone.trim().isEmpty ? null : _phone.trim(),
          social: _social.trim().isEmpty ? null : _social.trim(),
          role: _role.trim().isEmpty ? null : _role.trim(),
          address: _address.trim().isEmpty ? null : _address.trim(),
          nrc: _nrc.trim().isEmpty ? null : _nrc.trim(),
          billingWay: _billingWay.trim(),
          dob: _dob.isEmpty ? null : _dob,
          gender: _gender,
          shopId: shopId,
        ),
      );
      _user = user;
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Registration failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
