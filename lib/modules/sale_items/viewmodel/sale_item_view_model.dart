import 'dart:convert';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:dio/dio.dart';
import '../model/sale_item_models.dart';
import '../repository/sale_item_repository.dart';

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

      final List<SaleOrder> salesList = _parseItems(salesResponse, fromOrder: false);
      final List<SaleOrder> ordersList = _parseItems(ordersResponse, fromOrder: true);

      final allItems = [...salesList, ...ordersList];
      allItems.sort((a, b) => b.date.compareTo(a.date));

      _sales = _currentPage == 1 ? allItems : [..._sales, ...allItems];

      final salesMeta = salesResponse['meta'];
      final ordersMeta = ordersResponse['meta'];
      final salesLastPage = (salesMeta is Map) ? (salesMeta['last_page'] ?? 1) : 1;
      final ordersLastPage = (ordersMeta is Map) ? (ordersMeta['last_page'] ?? 1) : 1;
      _lastPage = salesLastPage > ordersLastPage ? salesLastPage : ordersLastPage;
      _currentPage++;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to load sales';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SaleOrder> _parseItems(Map<String, dynamic> response, {required bool fromOrder}) {
    final dynamic rawData = response['data'];
    List<dynamic> itemsList;
    if (rawData is List) {
      itemsList = rawData;
    } else if (rawData is String) {
      itemsList = jsonDecode(rawData) as List<dynamic>;
    } else {
      itemsList = [];
    }
    return itemsList.map((e) {
      if (e is Map<String, dynamic>) {
        return fromOrder ? SaleOrder.fromOrderJson(e) : SaleOrder.fromJson(e);
      }
      return null;
    }).whereType<SaleOrder>().toList();
  }
}
