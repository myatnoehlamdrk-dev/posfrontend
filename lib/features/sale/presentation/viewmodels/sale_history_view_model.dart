import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/domain/usecases/sale_usecases.dart';

class SaleHistoryViewModel extends BaseViewModel {
  final GetSalesUseCase _getSalesUseCase;
  final GetOrdersUseCase _getOrdersUseCase;
  final DeleteSaleUseCase _deleteSaleUseCase;
  final DeleteOrderUseCase _deleteOrderUseCase;
  final DeleteSaleItemUseCase _deleteSaleItemUseCase;

  SaleHistoryViewModel({
    required GetSalesUseCase getSalesUseCase,
    required GetOrdersUseCase getOrdersUseCase,
    required DeleteSaleUseCase deleteSaleUseCase,
    required DeleteOrderUseCase deleteOrderUseCase,
    required DeleteSaleItemUseCase deleteSaleItemUseCase,
  })  : _getSalesUseCase = getSalesUseCase,
        _getOrdersUseCase = getOrdersUseCase,
        _deleteSaleUseCase = deleteSaleUseCase,
        _deleteOrderUseCase = deleteOrderUseCase,
        _deleteSaleItemUseCase = deleteSaleItemUseCase;

  List<SaleOrderEntity> _allSales = [];
  List<SaleOrderEntity> _allOrders = [];
  String _selectedTab = 'All';
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;

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

    if (_searchQuery.isEmpty) return source;

    final q = _searchQuery.toLowerCase();
    return source.where((o) {
      return o.productName.toLowerCase().contains(q) ||
          o.orderId.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.customerPhone.toLowerCase().contains(q);
    }).toList();
  }

  String get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;
  bool get hasMore => _hasMore;
  int get totalSalesCount => _allSales.length;
  int get totalOrdersCount => _allOrders.length;

  void setTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadAll({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    setLoading(true);
    resetError();
    try {
      final sales = await _getSalesUseCase(_currentPage);
      final orders = await _getOrdersUseCase(_currentPage);
      if (_currentPage == 1) {
        _allSales = sales;
        _allOrders = orders;
      } else {
        _allSales = [..._allSales, ...sales];
        _allOrders = [..._allOrders, ...orders];
      }
      _hasMore = sales.isNotEmpty || orders.isNotEmpty;
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoading) return;
    _currentPage++;
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
