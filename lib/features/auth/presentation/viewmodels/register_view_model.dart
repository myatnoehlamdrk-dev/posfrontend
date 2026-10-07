import 'package:flutter/foundation.dart';
import 'package:posfrontend/core/auth/password_policy.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/features/auth/domain/entities/user.dart';
import 'package:posfrontend/features/auth/domain/usecases/register.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

class RegisterViewModel extends BaseViewModel with FormValidationMixin {
  final RegisterUseCase _registerUseCase;
  final ShopLocalRepository _shopRepository;

  RegisterViewModel({
    required RegisterUseCase registerUseCase,
    required ShopLocalRepository shopRepository,
  }) : _registerUseCase = registerUseCase,
       _shopRepository = shopRepository;

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

  void setName(String value) {
    _name = value;
    clearFieldError('name');
  }

  void setEmail(String value) {
    _email = value;
    clearFieldError('email');
  }

  void setPassword(String value) {
    _password = value;
    clearFieldError('password');
  }

  void setPhone(String value) {
    _phone = value;
    clearFieldError('phone');
  }

  void setSocial(String value) {
    _social = value;
    clearFieldError('social');
  }

  void setRole(String value) {
    _role = value;
    clearFieldError('role');
  }

  void setAddress(String value) {
    _address = value;
    clearFieldError('address');
  }

  void setNrc(String value) {
    _nrc = value;
    clearFieldError('nrc');
  }

  void setBillingWay(String value) {
    _billingWay = value;
    clearFieldError('billingWay');
  }

  void setDob(String value) {
    _dob = value;
    clearFieldError('dob');
  }

  void setGender(String? value) {
    _gender = value;
    clearFieldError('gender');
    notifyListeners();
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

  /// Step 1 gate: the three fields the account cannot exist without. Everything
  /// else in this form is optional and the backend accepts it as null, so
  /// holding step 2 for its own sake would only add a tap.
  bool validateUserInfoStep() {
    clearAllFieldErrors();

    if (_name.trim().isEmpty) {
      setFieldError('name', 'Full name is required');
    }
    if (_email.trim().isEmpty) {
      setFieldError('email', 'Email is required');
    } else if (!isValidEmail(_email)) {
      setFieldError('email', 'Enter a valid email');
    }
    if (_password.isEmpty) {
      setFieldError('password', 'Password is required');
    } else if (_password.length < PasswordPolicy.minLength) {
      // Matches the API's rule. Checking it here turns a round trip into
      // immediate feedback, but the server stays the authority.
      setFieldError(
        'password',
        'Password must be at least ${PasswordPolicy.minLength} characters',
      );
    }

    notifyListeners();
    return fieldErrors.isEmpty;
  }

  /// Step 2 is all optional, so there is nothing to reject.
  bool validateDetailStep() => true;

  /// Step 3 gate. The shop itself was created on the previous screen, so the
  /// only thing this step owns is how the user is billed against it.
  bool validateShopStep() {
    clearAllFieldErrors();

    if (_billingWay.trim().isEmpty) {
      setFieldError('billingWay', 'Billing way is required');
    }

    notifyListeners();
    return fieldErrors.isEmpty;
  }

  bool validate() => validateUserInfoStep() && validateShopStep();

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

      // A shop that already exists server-side travels as an id. One that was
      // only ever written to local storage has no id, so it rides along with
      // the account instead: the previous order -- create the shop, then
      // register -- called endpoints that sit behind auth:sanctum, which a
      // registrant cannot satisfy, so the flow 401'd before the account was
      // ever created.
      final existingShopId = localShop.id?.isNotEmpty == true
          ? localShop.id
          : null;
      if (existingShopId == null && localShop.name.trim().isEmpty) {
        setError('Shop name is required');
        return false;
      }

      final user = await _registerUseCase(
        RegisterParams(
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
          shopId: existingShopId,
          shop: existingShopId == null ? localShop : null,
        ),
      );
      _user = user;

      if (existingShopId == null && user.shopId.isNotEmpty) {
        // Persist the id the server assigned so every later screen (products,
        // sales, settings) reads the same shop instead of trying to create it
        // again. Non-fatal on purpose: the account already exists at this
        // point, so failing the registration here would send the user back to
        // a form whose email is now taken. The id is recovered from the
        // profile after sign-in.
        try {
          final savedShop = localShop.copyWith(id: user.shopId);
          await _shopRepository.saveShop(savedShop);
          _shop = savedShop;
          notifyListeners();
        } catch (e) {
          debugPrint('Registration: saving the new shop id failed: $e');
        }
      }

      return true;
    } catch (e) {
      setError('Registration failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
