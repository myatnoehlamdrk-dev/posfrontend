import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
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
  }) : _getSalesUseCase =
           getSalesUseCase ?? GetSalesUseCase(SaleHistoryRepositoryImpl()),
       _getOrdersUseCase =
           getOrdersUseCase ?? GetOrdersUseCase(SaleHistoryRepositoryImpl()),
       _deleteSaleUseCase =
           deleteSaleUseCase ?? DeleteSaleUseCase(SaleHistoryRepositoryImpl()),
       _deleteOrderUseCase =
           deleteOrderUseCase ?? DeleteOrderUseCase(OrderRepositoryImpl()),
       _deleteSaleItemUseCase =
           deleteSaleItemUseCase ??
           DeleteSaleItemUseCase(SaleHistoryRepositoryImpl());

  List<SaleOrderEntity> _allSales = [];
  List<SaleOrderEntity> _allOrders = [];
  String _selectedTab = 'All';
  int? _selectedYear;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _pendingLoadMore = false;
  bool get hasMore => _currentPage <= _lastPage;

  int? _yearOf(SaleOrderEntity order) {
    final raw = order.date.isNotEmpty ? order.date : order.createdAt;
    if (raw.isEmpty) return null;
    // Local, not UTC: the year shown is the year the sale happened *here*. A
    // sale at 6:30am on Jan 1 in Myanmar is Dec 31 UTC, and grouping on the UTC
    // year would file it under the previous year.
    return DateTime.tryParse(raw)?.toLocal().year;
  }

  List<SaleOrderEntity> _applyYear(Iterable<SaleOrderEntity> source) {
    if (_selectedYear == null) return source.toList();
    return source.where((o) => _yearOf(o) == _selectedYear).toList();
  }

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

    return _applyYear(source);
  }

  String get selectedTab => _selectedTab;
  int? get selectedYear => _selectedYear;
  int get totalSalesCount => _applyYear(_allSales).length;
  int get totalOrdersCount => _applyYear(_allOrders).length;

  List<int> get availableYears {
    final years = <int>{};
    for (final o in [..._allSales, ..._allOrders]) {
      final y = _yearOf(o);
      if (y != null) years.add(y);
    }
    years.add(DateTime.now().year);
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  void setTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setYear(int? year) {
    _selectedYear = year;
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
      setError(formatApiError(e));
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
      setError(formatApiError(e));
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
      setError(formatApiError(e));
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
      setError(formatApiError(e));
      return null;
    }
  }
}
