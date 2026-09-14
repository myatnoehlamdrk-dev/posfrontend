import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:dio/dio.dart';
import '../model/purchase_models.dart';
import '../repository/purchase_item_repository.dart';

class PurchaseItemViewModel extends BaseViewModel {
  final PurchaseItemRepository _repository;

  List<PurchaseOrder> _purchaseItems = [];
  List<PurchaseOrder> get purchaseItems => _purchaseItems;

  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

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
    if (isLoading) return;

    setLoading(true);
    resetError();

    try {
      final response = await _repository.getPurchaseItems(page: _currentPage, cancelToken: cancelToken);
      final paginated = PaginatedResponse.fromJson(response, PurchaseOrder.fromJson);
      _purchaseItems = _currentPage == 1
          ? paginated.data
          : [..._purchaseItems, ...paginated.data];
      _lastPage = paginated.lastPage;
      _currentPage++;
    } on DioException catch (e) {
      setError(e.message ?? 'Failed to load purchase items');
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadSuppliers() async {
    try {
      _suppliers = await _repository.getSuppliers(cancelToken: cancelToken);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
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
        cancelToken: cancelToken,
      );
      _suppliers.insert(0, supplier);
      notifyListeners();
      return supplier;
    } on DioException catch (e) {
      setError(e.message ?? 'Failed to create supplier');
      notifyListeners();
      return null;
    } catch (e) {
      setError(e.toString());
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
        cancelToken: cancelToken,
      );
      await loadPurchaseItems(refresh: true);
      return true;
    } on DioException catch (e) {
      setError(e.message ?? 'Failed to create purchase item');
      notifyListeners();
      return false;
    } catch (e) {
      setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updatePurchaseItemStatus(id: id, status: status, cancelToken: cancelToken);
      await loadPurchaseItems(refresh: true);
      return true;
    } on DioException catch (e) {
      setError(e.message ?? 'Failed to update status');
      notifyListeners();
      return false;
    } catch (e) {
      setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePurchaseItem(String id) async {
    try {
      await _repository.deletePurchaseItem(id, cancelToken: cancelToken);
      _purchaseItems.removeWhere((item) => item.orderId == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      setError(e.message ?? 'Failed to delete purchase item');
      notifyListeners();
      return false;
    } catch (e) {
      setError(e.toString());
      notifyListeners();
      return false;
    }
  }
}
