import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import '../model/sale_item_models.dart';
import '../repository/sale_item_repository.dart';
import '../repository/sale_item_repository_impl.dart';

class SaleItemViewModel extends BaseViewModel {
  final SaleItemRepository _repository;

  List<SaleOrder> _sales = [];
  List<SaleOrder> get sales => _sales;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _currentPage = 1;
  int _lastPage = 1;
  bool get hasMore => _currentPage <= _lastPage;

  SaleItemViewModel({SaleItemRepository? repository})
      : _repository = repository ?? SaleItemRepositoryImpl();

  Future<void> loadSales({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _sales = [];
    }
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final salesResponse = await _repository.getSales(page: _currentPage);
      final ordersResponse = await _repository.getOrders(page: _currentPage);

      final allItems = [...salesResponse.data, ...ordersResponse.data];
      allItems.sort((a, b) => b.date.compareTo(a.date));

      _sales = _currentPage == 1 ? allItems : [..._sales, ...allItems];

      final salesLastPage = salesResponse.lastPage;
      final ordersLastPage = ordersResponse.lastPage;
      _lastPage = salesLastPage > ordersLastPage ? salesLastPage : ordersLastPage;
      _currentPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(SaleOrder order) async {
    try {
      if (order.status == OrderStatus.alreadySale) {
        await _repository.deleteSale(order.orderId);
      } else {
        await _repository.deleteOrder(order.orderId);
      }
      _sales.removeWhere((o) => o.orderId == order.orderId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
