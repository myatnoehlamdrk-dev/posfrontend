import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/features/purchase/domain/entities/purchase.dart';
import 'package:posfrontend/features/purchase/domain/repositories/purchase_repository.dart';
import 'package:posfrontend/features/purchase/data/repositories/purchase_repository_impl.dart';

class PurchaseItemViewModel extends BaseViewModel {
  final PurchaseItemRepository _repository;

  List<PurchaseOrder> _purchaseItems = [];
  List<PurchaseOrder> get purchaseItems => _purchaseItems;

  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

  int _currentPage = 1;
  bool _reachedEnd = false;

  /// Whether another page might exist.
  ///
  /// The list endpoint returns a bare array with no pagination meta, so
  /// `last_page` is always the default 1 and cannot be trusted. A page that
  /// came back full is the only honest signal that the next one may hold
  /// anything; a short or empty page means we are done.
  bool get hasMore => !_reachedEnd;

  PurchaseItemViewModel({PurchaseItemRepository? repository})
    : _repository = repository ?? PurchaseRepositoryImpl();

  /// Kept in step with the backend's default `per_page`; a full page is what
  /// marks the response as "there may be more".
  static const int _pageSize = 10;

  Future<void> loadPurchaseItems({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _purchaseItems = [];
      _reachedEnd = false;
    }
    // Without this guard the scroll listener re-fires on every scroll end
    // once the last page is loaded, each time paying for a page the server
    // answers with nothing -- on the slowest endpoint in the API that is a
    // lot of wasted seconds per scroll.
    if (!refresh && !hasMore) return;
    if (isLoading) return;

    setLoading(true);
    resetError();

    try {
      final response = await _repository.getPurchaseItems(
        page: _currentPage,
        cancelToken: cancelToken,
      );
      final paginated = PaginatedResponse.fromJson(
        response,
        PurchaseOrder.fromJson,
      );
      _purchaseItems = _currentPage == 1
          ? paginated.data
          : [..._purchaseItems, ...paginated.data];
      _reachedEnd = paginated.data.length < _pageSize;
      _currentPage++;
    } catch (e) {
      setError(formatApiError(e));
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadSuppliers() async {
    try {
      _suppliers = await _repository.getSuppliers(cancelToken: cancelToken);
      notifyListeners();
    } catch (e) {
      setError(formatApiError(e));
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
    } catch (e) {
      setError(formatApiError(e));
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
    } catch (e) {
      setError(formatApiError(e));
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updatePurchaseItemStatus(
        id: id,
        status: status,
        cancelToken: cancelToken,
      );
      await loadPurchaseItems(refresh: true);
      return true;
    } catch (e) {
      setError(formatApiError(e));
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
    } catch (e) {
      setError(formatApiError(e));
      notifyListeners();
      return false;
    }
  }
}
