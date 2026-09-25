import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/features/sale/data/models/sale_order_api_model.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/domain/usecases/sale_usecases.dart';

class SaleHistoryViewModel extends BaseViewModel {
  final GetSalesUseCase _getSalesUseCase;
  final GetOrdersUseCase _getOrdersUseCase;
  final DeleteSaleUseCase _deleteSaleUseCase;
  final DeleteOrderUseCase _deleteOrderUseCase;
  final DeleteSaleItemUseCase _deleteSaleItemUseCase;

  SaleHistoryViewModel({
    GetSalesUseCase? getSalesUseCase,
    GetOrdersUseCase? getOrdersUseCase,
    DeleteSaleUseCase? deleteSaleUseCase,
    DeleteOrderUseCase? deleteOrderUseCase,
    DeleteSaleItemUseCase? deleteSaleItemUseCase,
  })  : _getSalesUseCase =
            getSalesUseCase ?? GetSalesUseCase(SaleHistoryRepositoryImpl()),
        _getOrdersUseCase =
            getOrdersUseCase ?? GetOrdersUseCase(SaleHistoryRepositoryImpl()),
        _deleteSaleUseCase =
            deleteSaleUseCase ?? DeleteSaleUseCase(SaleHistoryRepositoryImpl()),
        _deleteOrderUseCase =
            deleteOrderUseCase ?? DeleteOrderUseCase(OrderRepositoryImpl()),
        _deleteSaleItemUseCase = deleteSaleItemUseCase ??
            DeleteSaleItemUseCase(SaleHistoryRepositoryImpl());

  List<SaleOrderEntity> _allSales = [];
  List<SaleOrderEntity> _allOrders = [];
  String _selectedTab = 'All';
  int _currentPage = 1;
  int _lastPage = 1;
  bool _pendingLoadMore = false;
  bool get hasMore => _currentPage <= _lastPage;

  List<SaleOrderEntity> get filteredOrders {
    List<SaleOrderEntity> source;
    switch (_selectedTab) {
      case 'Sold':
        source = _allSales;
        break;
      case 'Order':
        source = _allOrders;
        break;
      default:
        source = [..._allSales, ..._allOrders];
    }

    return source;
  }

  String get selectedTab => _selectedTab;
  int get totalSalesCount => _allSales.length;
  int get totalOrdersCount => _allOrders.length;

  void setTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  Future<void> loadAll({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _lastPage = 1;
      _pendingLoadMore = false;
      _allSales = [];
      _allOrders = [];
    }
    if (isLoading) return;
    setLoading(true);
    resetError();
    try {
      final salesResponse = await _getSalesUseCase(
        GetSalesParams(page: _currentPage),
      );
      final ordersResponse = await _getOrdersUseCase(
        GetOrdersParams(page: _currentPage),
      );

      final salesPaginated = PaginatedResponse.fromJson(
        salesResponse,
        (json) => SaleOrderApiModel.fromJson(json).toEntity(),
      );
      final ordersPaginated = PaginatedResponse.fromJson(
        ordersResponse,
        (json) => SaleOrderApiModel.fromOrderJson(json).toEntity(),
      );

      if (_currentPage == 1) {
        _allSales = salesPaginated.data;
        _allOrders = ordersPaginated.data;
      } else {
        _allSales = [..._allSales, ...salesPaginated.data];
        _allOrders = [..._allOrders, ...ordersPaginated.data];
      }

      final maxSalesPage = salesPaginated.lastPage;
      final maxOrdersPage = ordersPaginated.lastPage;
      _lastPage = maxSalesPage > maxOrdersPage ? maxSalesPage : maxOrdersPage;
      _currentPage++;
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
      if (_pendingLoadMore) {
        _pendingLoadMore = false;
        loadMore();
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading) {
      _pendingLoadMore = true;
      return;
    }
    await loadAll();
  }

  Future<bool> deleteSale(String id) async {
    try {
      await _deleteSaleUseCase(id);
      _allSales.removeWhere((s) => s.orderId == id);
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      await _deleteOrderUseCase(id);
      _allOrders.removeWhere((o) => o.orderId == id);
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<SaleOrderEntity?> deleteSaleItem(String saleId, String itemId) async {
    try {
      final updated = await _deleteSaleItemUseCase(
        DeleteSaleItemParams(saleId: saleId, itemId: itemId),
      );
      final idx = _allSales.indexWhere((s) => s.orderId == saleId);
      if (idx != -1) _allSales[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }
}
