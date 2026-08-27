import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository.dart';

class CategoryViewModel extends BaseViewModel {
  final CategoryRepository _repository;
  late final List<Category> _categories;

  String _search = '';
  String _status = 'All Status';

  CategoryViewModel({required CategoryRepository repository})
      : _repository = repository {
    _categories = _repository.getCategories();
  }

  List<Category> get filtered {
    final q = _search.toLowerCase();
    return _categories.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(q);
      final matchesStatus =
          _status == 'All Status' ||
          (_status == 'Active' && c.active) ||
          (_status == 'Inactive' && !c.active);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get totalCount => _categories.length;

  String get search => _search;
  String get status => _status;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatus(String value) {
    _status = value;
    notifyListeners();
  }

  void addCategory(Category category) {
    _categories.add(category);
    notifyListeners();
  }
}
