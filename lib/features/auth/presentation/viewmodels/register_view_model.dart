import 'dart:convert';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/usecases/register.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';

class RegisterViewModel extends BaseViewModel with FormValidationMixin {
  final RegisterUseCase _registerUseCase;
  final ShopLocalRepository _shopRepository;
  final ShopApiRepository _shopApiRepository;
  final ImgbbRepository _imgbbRepository;

  RegisterViewModel({
    required RegisterUseCase registerUseCase,
    required ShopLocalRepository shopRepository,
    required ShopApiRepository shopApiRepository,
    required ImgbbRepository imgbbRepository,
  })  : _registerUseCase = registerUseCase,
        _shopRepository = shopRepository,
        _shopApiRepository = shopApiRepository,
        _imgbbRepository = imgbbRepository;

  Shop? _shop;
  Shop? get shop => _shop;
  String? get shopName => _shop?.name;
  String? get shopType => _shop?.type;

  UserEntity? _user;
  UserEntity? get user => _user;

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

  void setName(String value) { _name = value; clearFieldError('name'); }
  void setEmail(String value) { _email = value; clearFieldError('email'); }
  void setPassword(String value) { _password = value; clearFieldError('password'); }
  void setPhone(String value) { _phone = value; clearFieldError('phone'); }
  void setSocial(String value) { _social = value; clearFieldError('social'); }
  void setRole(String value) { _role = value; clearFieldError('role'); }
  void setAddress(String value) { _address = value; clearFieldError('address'); }
  void setNrc(String value) { _nrc = value; clearFieldError('nrc'); }
  void setBillingWay(String value) { _billingWay = value; clearFieldError('billingWay'); }
  void setDob(String value) { _dob = value; clearFieldError('dob'); }
  void setGender(String? value) { _gender = value; clearFieldError('gender'); notifyListeners(); }

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

  bool validate() {
    clearAllFieldErrors();
    if (_name.trim().isEmpty) setFieldError('name', 'Full name is required');
    if (_email.trim().isEmpty) {
      setFieldError('email', 'Email is required');
    } else if (!isValidEmail(_email)) {
      setFieldError('email', 'Enter a valid email');
    }
    if (_password.isEmpty) setFieldError('password', 'Password is required');
    if (_billingWay.trim().isEmpty) setFieldError('billingWay', 'Billing way is required');
    notifyListeners();
    return fieldErrors.isEmpty;
  }

  Future<bool> register() async {
    resetError();
    if (!validate()) {
      setError('Please complete all required fields');
      return false;
    }

    setLoading(true);
    try {
      final localShop = _shop ?? await _shopRepository.getShop();
      if (localShop == null) {
        setError('No shop found. Please create a shop first.');
        return false;
      }

      String shopId;
      if (localShop.id?.isNotEmpty == true) {
        shopId = localShop.id!;
      } else {
        var shop = localShop;
        if (shop.logoData?.isNotEmpty == true) {
          final bytes = base64Decode(shop.logoData!);
          final result = await _imgbbRepository.uploadImage(bytes, fileName: 'shop_logo.jpg');
          shop = shop.copyWith(logoUrl: result.url);
          await _shopRepository.saveShop(shop);
        }
        final createdShop = await _shopApiRepository.createShop(shop);
        await _shopRepository.saveShop(createdShop);
        _shop = createdShop;
        notifyListeners();
        shopId = createdShop.id!;
      }

      final user = await _registerUseCase(RegisterParams(
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
      ));
      _user = user;
      return true;
    } catch (e) {
      setError('Registration failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
