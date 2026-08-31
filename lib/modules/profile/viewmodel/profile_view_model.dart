import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/profile/model/profile_response.dart';
import 'package:posfrontend/modules/profile/repository/profile_repository.dart';

class ProfileViewModel extends BaseViewModel {
  final ProfileRepository _repository;

  ProfileViewModel({required ProfileRepository repository})
      : _repository = repository;

  ProfileResponse? _profile;
  ProfileResponse? get profile => _profile;

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

  final Map<String, String?> _fieldErrors = {};
  Map<String, String?> get fieldErrors => Map.unmodifiable(_fieldErrors);

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

  void _clearError(String key) {
    if (_fieldErrors.containsKey(key)) {
      _fieldErrors.remove(key);
      notifyListeners();
    }
  }

  void clearSuccess() {
    _successMessage = '';
    notifyListeners();
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
    _fieldErrors.clear();
    if (_name.trim().isEmpty) {
      _fieldErrors['name'] = 'Name is required';
    }
    if (_email.trim().isEmpty) {
      _fieldErrors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.trim())) {
      _fieldErrors['email'] = 'Enter a valid email';
    }
    notifyListeners();

    if (_fieldErrors.isNotEmpty) return false;

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
    _fieldErrors.clear();
    if (currentPassword.isEmpty) {
      _fieldErrors['currentPassword'] = 'Current password is required';
    }
    if (newPassword.isEmpty) {
      _fieldErrors['newPassword'] = 'New password is required';
    } else if (newPassword.length < 6) {
      _fieldErrors['newPassword'] = 'Password must be at least 6 characters';
    }
    notifyListeners();

    if (_fieldErrors.isNotEmpty) return false;

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
