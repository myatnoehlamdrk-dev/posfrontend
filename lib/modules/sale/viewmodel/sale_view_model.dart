import 'dart:math';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/customer/repository/customer_repository.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/sale/repository/order_repository.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository.dart';
import 'package:posfrontend/modules/sale/repository/sale_repository.dart';

class SaleViewModel extends BaseViewModel {
  final SaleProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final OrderRepository _orderRepository;
  final CustomerRepository _customerRepository;

  SaleViewModel({
    required SaleProductRepository productRepository,
    required SaleRepository saleRepository,
    required OrderRepository orderRepository,
    required CustomerRepository customerRepository,
  })  : _productRepository = productRepository,
        _saleRepository = saleRepository,
        _orderRepository = orderRepository,
        _customerRepository = customerRepository;

  List<CatalogProduct> _products = [];
  List<CatalogProduct> get products => _products;

  final List<SaleItem> _items = [];
  List<SaleItem> get items => List.unmodifiable(_items);

  String _paymentMethod = 'Cash';
  String get paymentMethod => _paymentMethod;

  late String _voucherRandom;
  late String _orderRandom;
  String get voucherRandom => _voucherRandom;
  String get orderRandom => _orderRandom;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  List<Map<String, dynamic>> _customerSuggestions = [];
  List<Map<String, dynamic>> get customerSuggestions => _customerSuggestions;

  bool _showSuggestions = false;
  bool get showSuggestions => _showSuggestions;

  String _customerName = 'Customer';
  String get customerName => _customerName;

  String _customerPhone = '';
  String get customerPhone => _customerPhone;

  String _customerLocation = '';
  String get customerLocation => _customerLocation;

  double _discountPercent = 0;
  double get discountPercent => _discountPercent;

  String _notes = '';
  String get notes => _notes;

  double get subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  int get totalItems => _items.fold(0, (s, i) => s + i.quantity);
  double get discountAmount => subtotal * (_discountPercent / 100);
  double get totalPayable => subtotal - discountAmount;
  bool get hasItems => _items.isNotEmpty;

  String _generateRandom5() {
    final rand = Random();
    return (10000 + rand.nextInt(90000)).toString();
  }

  void init({
    List<SaleItem>? initialItems,
    String? initialCustomerName,
    String? initialCustomerPhone,
    String? initialPaymentMethod,
  }) {
    _voucherRandom = _generateRandom5();
    _orderRandom = _generateRandom5();
    if (initialItems != null) _items.addAll(initialItems);
    if (initialCustomerName?.isNotEmpty == true) _customerName = initialCustomerName!;
    if (initialCustomerPhone != null) _customerPhone = initialCustomerPhone;
    if (initialPaymentMethod != null) _paymentMethod = initialPaymentMethod;
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    _paymentMethod = value;
    notifyListeners();
  }

  void setCustomerName(String value) => _customerName = value;
  void setCustomerPhone(String value) => _customerPhone = value;
  void setCustomerLocation(String value) => _customerLocation = value;
  void setDiscountPercent(double value) {
    _discountPercent = value;
    notifyListeners();
  }
  void setNotes(String value) => _notes = value;

  void refreshRandoms() {
    _voucherRandom = _generateRandom5();
    _orderRandom = _generateRandom5();
    notifyListeners();
  }

  void addItem(SaleItem item) {
    _items.add(item);
    notifyListeners();
  }

  void addItems(List<SaleItem> newItems) {
    _items.addAll(newItems);
    notifyListeners();
  }

  void updateItemQuantity(int index, int delta) {
    if (index < 0 || index >= _items.length) return;
    final newQty = _items[index].quantity + delta;
    if (newQty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = newQty;
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _customerName = 'Customer';
    _customerPhone = '';
    _customerLocation = '';
    _discountPercent = 0;
    _notes = '';
    refreshRandoms();
    notifyListeners();
  }

  Future<void> searchCustomers(String query) async {
    if (query.length < 2) {
      _customerSuggestions = [];
      _showSuggestions = false;
      notifyListeners();
      return;
    }
    try {
      final results = await _customerRepository.searchCustomers(query: query);
      _customerSuggestions = results;
      _showSuggestions = results.isNotEmpty;
    } catch (_) {
      _customerSuggestions = [];
      _showSuggestions = false;
    }
    notifyListeners();
  }

  void selectCustomer(Map<String, dynamic> customer) {
    _customerName = customer['name'] ?? '';
    if (customer['phone'] != null && (customer['phone'] as String).isNotEmpty) {
      _customerPhone = customer['phone'];
    }
    _showSuggestions = false;
    _customerSuggestions = [];
    notifyListeners();
  }

  void hideSuggestions() {
    _showSuggestions = false;
    notifyListeners();
  }

  void showCustomerSuggestions() {
    if (_customerSuggestions.isNotEmpty) {
      _showSuggestions = true;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    setLoading(true);
    resetError();
    try {
      _products = await _productRepository.getProducts(cancelToken: cancelToken);
    } on ApiException catch (e) {
      setError(e.message);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> submitSale({
    required String staffName,
    String? existingOrderId,
  }) async {
    if (_items.isEmpty) return false;
    _isSubmitting = true;
    resetError();
    notifyListeners();

    try {
      final voucherNo = 'INV-$_voucherRandom';
      final orderId = existingOrderId ?? 'ORD-$_orderRandom';

      await _saleRepository.createSale(
        userName: staffName,
        customerName: _customerName,
        customerPhone: _customerPhone.isNotEmpty ? _customerPhone : null,
        customerLocation: _customerLocation.isNotEmpty ? _customerLocation : null,
        payMethod: _paymentMethod,
        voucherNo: voucherNo,
        orderId: orderId,
        items: List<SaleItem>.from(_items),
        grandTotal: totalPayable,
        discount: _discountPercent.toInt(),
        notes: _notes.isNotEmpty ? _notes : null,
        cancelToken: cancelToken,
      );

      if (existingOrderId != null) {
        try {
          await _orderRepository.deleteOrder(existingOrderId);
        } catch (_) {
          // Original order deletion failure is non-critical
        }
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitDraft({required String staffName}) async {
    if (_items.isEmpty) return false;
    _isSubmitting = true;
    resetError();
    notifyListeners();

    try {
      await _orderRepository.createOrder(
        userName: staffName,
        customerName: _customerName,
        customerPhone: _customerPhone.isNotEmpty ? _customerPhone : null,
        payMethod: _paymentMethod,
        voucherNo: 'INV-$_voucherRandom',
        orderId: 'ORD-$_orderRandom',
        items: List<SaleItem>.from(_items),
        grandTotal: totalPayable,
        discount: _discountPercent.toInt(),
        notes: _notes.isNotEmpty ? _notes : null,
        status: 'draft',
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
