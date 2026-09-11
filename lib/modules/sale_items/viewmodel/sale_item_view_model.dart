import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import '../model/sale_item_models.dart';
import '../repository/sale_item_repository.dart';
import '../repository/sale_item_repository_impl.dart';

class SaleItemViewModel extends BaseViewModel {
  final SaleItemRepository _repository;

  List<SaleOrder> _sales = [];
  List<SaleOrder> get sales => _sales;

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
    if (isLoading) return;

    setLoading(true);
    resetError();

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
      setError(e.message);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
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
      setError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<SaleOrder?> deleteSaleItem(String saleId, String itemId) async {
    try {
      final updatedOrder = await _repository.deleteSaleItem(saleId, itemId);
      final index = _sales.indexWhere((o) => o.orderId == saleId);
      if (index != -1) {
        _sales[index] = updatedOrder;
      }
      notifyListeners();
      return updatedOrder;
    } on ApiException catch (e) {
      setError(e.message);
      notifyListeners();
      return null;
    } catch (e) {
      setError(e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<SaleOrder?> getOrderById(String id) async {
    try {
      return await _repository.getOrderById(id);
    } on ApiException catch (e) {
      setError(e.message);
      notifyListeners();
      return null;
    } catch (e) {
      setError(e.toString());
      notifyListeners();
      return null;
    }
  }
}
