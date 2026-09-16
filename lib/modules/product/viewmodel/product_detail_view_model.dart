import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/product/model/product_detail_models.dart';
import 'package:posfrontend/modules/product/repository/product_detail_repository.dart';

class ProductDetailViewModel extends BaseViewModel {
  final ProductDetailRepository _repository;
  final String productId;

  ProductDetailViewModel({
    required ProductDetailRepository repository,
    required this.productId,
  }) : _repository = repository;

  ProductDetail? _detail;
  ProductDetail? get detail => _detail;

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  void setTabIndex(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  Future<void> load() async {
    setLoading(true);
    resetError();
    try {
      _detail = await _repository.getDetail(productId, cancelToken: cancelToken);
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Failed to load product detail: $e');
    } finally {
      setLoading(false);
    }
  }
}
