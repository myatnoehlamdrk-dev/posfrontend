import 'dart:convert';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:dio/dio.dart';
import '../model/purchase_models.dart';
import '../repository/purchase_item_repository.dart';

class PurchaseItemViewModel extends BaseViewModel {
  final PurchaseItemRepository _repository;

  List<PurchaseOrder> _purchaseItems = [];
  List<PurchaseOrder> get purchaseItems => _purchaseItems;

  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _currentPage = 1;
  int _lastPage = 1;
  bool get hasMore => _currentPage <= _lastPage;

  PurchaseItemViewModel({PurchaseItemRepository? repository})
      : _repository = repository ?? PurchaseItemRepositoryImpl();

  Future<void> loadPurchaseItems({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _purchaseItems = [];
    }
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getPurchaseItems(page: _currentPage);
      final dynamic rawData = response['data'];
      List<dynamic> itemsList;
      if (rawData is List) {
        itemsList = rawData;
      } else if (rawData is String) {
        itemsList = jsonDecode(rawData) as List<dynamic>;
      } else {
        itemsList = [];
      }
      final items = itemsList.map((e) {
        if (e is Map<String, dynamic>) return PurchaseOrder.fromJson(e);
        return null;
      }).whereType<PurchaseOrder>().toList();
      _purchaseItems = _currentPage == 1 ? items : [..._purchaseItems, ...items];
      final meta = response['meta'];
      if (meta is Map) {
        _lastPage = meta['last_page'] ?? 1;
      } else {
        _lastPage = response['last_page'] ?? 1;
      }
      _currentPage++;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to load purchase items';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSuppliers() async {
    try {
      _suppliers = await _repository.getSuppliers();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Supplier?> createSupplier({
    required String name,
    String? contact,
    String? address,
  }) async {
    try {
      final supplier = await _repository.createSupplier(
        name: name,
        contact: contact,
        address: address,
      );
      _suppliers.insert(0, supplier);
      notifyListeners();
      return supplier;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to create supplier';
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createPurchaseItem({
    required String productName,
    required int quantity,
    required int unitPrice,
    required String date,
    String? supplierId,
    String? notes,
    String? size,
    String? color,
    String? brand,
    String? sku,
  }) async {
    try {
      await _repository.createPurchaseItem(
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        date: date,
        supplierId: supplierId,
        notes: notes,
        size: size,
        color: color,
        brand: brand,
        sku: sku,
      );
      await loadPurchaseItems(refresh: true);
      return true;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to create purchase item';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updatePurchaseItemStatus(id: id, status: status);
      await loadPurchaseItems(refresh: true);
      return true;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to update status';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePurchaseItem(String id) async {
    try {
      await _repository.deletePurchaseItem(id);
      _purchaseItems.removeWhere((item) => item.orderId == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to delete purchase item';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
