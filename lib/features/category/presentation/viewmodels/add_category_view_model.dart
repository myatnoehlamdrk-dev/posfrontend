import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/base/form_validation_mixin.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';

class AddCategoryViewModel extends BaseViewModel with FormValidationMixin {
  final CategoryRepository _repository;

  AddCategoryViewModel({CategoryRepository? repository})
      : _repository = repository ?? _defaultRepository();

  static CategoryRepository _defaultRepository() {
    throw UnimplementedError(
        'CategoryRepository must be injected into AddCategoryViewModel');
  }

  String _name = '';
  String _description = '';
  String _packageLimit = '';

  String get name => _name;
  String get description => _description;
  String get packageLimit => _packageLimit;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Category? _result;
  Category? get result => _result;

  void setName(String value) => _name = value;
  void setDescription(String value) => _description = value;
  void setPackageLimit(String value) => _packageLimit = value;

  void loadExisting(Category category) {
    _name = category.name;
    _description = category.description;
    _packageLimit = category.packageLimit > 0 ? category.packageLimit.toString() : '';
    notifyListeners();
  }

  Future<bool> save({
    required bool isEditing,
    String? categoryId,
    required String inventoryType,
  }) async {
    clearAllFieldErrors();
    if (_name.trim().isEmpty) {
      setFieldError('name', 'Category name is required');
    }
    notifyListeners();
    if (fieldErrors.isNotEmpty) return false;

    _isSaving = true;
    resetError();
    notifyListeners();

    try {
      final amount = int.tryParse(_packageLimit.trim());
      if (isEditing && categoryId != null) {
        _result = await _repository.updateCategory(
          id: categoryId,
          name: _name.trim(),
          description: _description.trim(),
          packageLimit: amount,
        );
      } else {
        _result = await _repository.createCategory(
          type: inventoryType,
          name: _name.trim(),
          description: _description.trim(),
          packageLimit: amount,
        );
      }
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Failed to save category: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
