import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository.dart';
import 'package:posfrontend/modules/sale/repository/sale_repository.dart';

class SaleViewModel extends BaseViewModel {
  final SaleProductRepository _productRepository;
  final SaleRepository _saleRepository;

  List<CatalogProduct> _products = [];
  List<CatalogProduct> get products => _products;

  SaleViewModel({
    required SaleProductRepository productRepository,
    required SaleRepository saleRepository,
  })  : _productRepository = productRepository,
        _saleRepository = saleRepository;

  Future<void> loadProducts() async {
    setLoading(true);
    resetError();
    try {
      _products = await _productRepository.getProducts();
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<void> submitSale({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? payMethod,
    required List<SaleItem> items,
    required double grandTotal,
    String? notes,
  }) async {
    setLoading(true);
    resetError();
    try {
      await _saleRepository.createSale(
        userName: userName,
        voucherNo: voucherNo,
        orderId: orderId,
        customerName: customerName,
        payMethod: payMethod,
        items: items,
        grandTotal: grandTotal,
        notes: notes,
      );
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      rethrow;
    }
  }
}
