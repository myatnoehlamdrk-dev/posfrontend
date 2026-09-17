import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/profile/domain/entities/profile.dart';
import 'package:posfrontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

class ProfileViewModel extends BaseViewModel with FormValidationMixin {
  final ProfileRepository _repository;
  final ShopApiRepository _shopRepository;

  ProfileViewModel({
    required ProfileRepository repository,
    required ShopApiRepository shopRepository,
  })  : _repository = repository,
        _shopRepository = shopRepository;

  ProfileEntity? _profile;
  ProfileEntity? get profile => _profile;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _social = '';
  String _role = '';
  String _address = '';
  String _status = '';
  String _nrcNo = '';
  String _billingWay = '';
  String _dateOfBirth = '';
  String _gender = '';
  String _type = '';
  String _imageUrl = '';

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get social => _social;
  String get role => _role;
  String get address => _address;
  String get status => _status;
  String get nrcNo => _nrcNo;
  String get billingWay => _billingWay;
  String get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get type => _type;
  String get imageUrl => _imageUrl;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  String _successMessage = '';
  String get successMessage => _successMessage;

  Shop? _shop;
  Shop? get shop => _shop;

  void setName(String v) => _name = v;
  void setEmail(String v) => _email = v;
  void setPhone(String v) => _phone = v;
  void setSocial(String v) => _social = v;
  void setRole(String v) => _role = v;
  void setAddress(String v) => _address = v;
  void setStatus(String v) => _status = v;
  void setNrcNo(String v) => _nrcNo = v;
  void setBillingWay(String v) => _billingWay = v;
  void setDateOfBirth(String v) => _dateOfBirth = v;
  void setGender(String v) => _gender = v;
  void setType(String v) => _type = v;
  void setImageUrl(String v) => _imageUrl = v;

  void clearSuccess() {
    _successMessage = '';
    notifyListeners();
  }

  Future<void> loadShop(String shopId) async {
    if (shopId.isEmpty) return;
    try {
      _shop = await _shopRepository.getShopById(shopId);
      notifyListeners();
    } catch (_) {
      // Shop load failure is non-critical
    }
  }

  Future<void> loadProfile() async {
    setLoading(true);
    resetError();
    try {
      _profile = await _repository.getProfile();
      _populateFields();
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load profile: $e');
    } finally {
      setLoading(false);
    }
  }

  void _populateFields() {
    if (_profile == null) return;
    _name = _profile!.fullName;
    _email = _profile!.email;
    _phone = _profile!.phone;
    _social = _profile!.social;
    _role = _profile!.role;
    _address = _profile!.address;
    _status = _profile!.status;
    _nrcNo = _profile!.nrcNo;
    _billingWay = _profile!.billingWay;
    _dateOfBirth = _profile!.dateOfBirth;
    _gender = _profile!.gender;
    _type = _profile!.type;
    _imageUrl = _profile!.image;
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    clearAllFieldErrors();
    if (_name.trim().isEmpty) {
      setFieldError('name', 'Name is required');
    }
    if (_email.trim().isEmpty) {
      setFieldError('email', 'Email is required');
    } else if (!isValidEmail(_email)) {
      setFieldError('email', 'Enter a valid email');
    }
    notifyListeners();

    if (fieldErrors.isNotEmpty) return false;

    _isSaving = true;
    _successMessage = '';
    resetError();
    notifyListeners();

    try {
      _profile = await _repository.updateProfile({
        'name': _name.trim(),
        'email': _email.trim(),
        'phone': _phone,
        'social': _social,
        'role': _role,
        'address': _address,
        'status': _status,
        'nrc_no': _nrcNo,
        'billing_way': _billingWay,
        'date_of_birth': _dateOfBirth,
        'gender': _gender,
        'type': _type,
        'image': _imageUrl,
      });
      _successMessage = 'Profile updated successfully.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to save profile: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    clearAllFieldErrors();
    if (currentPassword.isEmpty) {
      setFieldError('currentPassword', 'Current password is required');
    }
    if (newPassword.isEmpty) {
      setFieldError('newPassword', 'New password is required');
    } else if (newPassword.length < 6) {
      setFieldError('newPassword', 'Password must be at least 6 characters');
    }
    notifyListeners();

    if (fieldErrors.isNotEmpty) return false;

    _isChangingPassword = true;
    _successMessage = '';
    resetError();
    notifyListeners();

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _successMessage = 'Password changed successfully.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to change password: $e');
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }
}
