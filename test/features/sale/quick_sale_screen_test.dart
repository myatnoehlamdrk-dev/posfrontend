import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/category/data/models/category_api_model.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/features/customer/domain/repositories/customer_repository.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart';
import 'package:posfrontend/features/sale/presentation/screens/quick_sale_screen.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/quick_sale_view_model.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_view_model.dart';
import 'package:posfrontend/shared/theme/app_theme.dart';

/// The quick-sale screen as the drawer opens it: search and the category filter
/// are on the first frame, and the cart surface — the bar a phone has room for
/// — appears as soon as a category is picked.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Built for one pump: the screen owns and disposes both view models, and
  /// nothing here may reach `ApiClient.instance`, whose base URL is a
  /// compile-time define the test runner does not set.
  QuickSaleScreen buildScreen() {
    return QuickSaleScreen(
      catalog: QuickSaleViewModel(
        remoteDataSource: _FakeProductRemote(),
        categorySource: _FakeCategoryRemote(),
      ),
      sale: SaleViewModel(
        productRepository: _FakeSaleProductRepository(),
        saleRepository: _FakeSaleRepository(),
        orderRepository: _FakeOrderRepository(),
        customerRepository: _FakeCustomerRepository(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: buildScreen(),
      ),
    );
    // First frame (loading), then the catalog's own load — both answers come
    // from the fakes, so a couple of pumps is the whole fetch.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders the search field and the All filter chip', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Quick Sale'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    // The chips come from the plain categories list — no product join.
    expect(find.text('Fashion'), findsOneWidget);
    // Nothing selected yet, so no cart surface and the grid owns the height.
    expect(find.text('View Cart'), findsNothing);
  });

  testWidgets('picking a category reveals the cart bar', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('View Cart'), findsOneWidget);
    expect(find.text('No items added yet.'), findsOneWidget);
  });
}

// ---------------------------------------------------------------- fixtures

/// A dio that is never used: every method the quick-sale feed calls is
/// overridden, so no request is issued. The default constructor would build
/// the real `ApiClient`, whose baseUrl is empty outside a `--dart-define`
/// build and rejected by dio at construction.
class _FakeProductRemote extends ProductRemoteDataSource {
  _FakeProductRemote()
    : super(Dio(BaseOptions(baseUrl: 'http://localhost/api/v1')));

  @override
  Future<Map<String, dynamic>> getProducts({
    String? packageId,
    String? categoryId,
    String? search,
    String? sort,
    String? order,
    int page = 1,
    int perPage = 10,
    CancelToken? cancelToken,
  }) async => {
    'data': <dynamic>[],
    'meta': {'current_page': page, 'last_page': 1, 'total': 0},
  };
}

/// The chips' source: the plain categories list, never the product-joining
/// endpoint. A dio is passed for the same reason as above.
class _FakeCategoryRemote extends CategoryRemoteDataSource {
  _FakeCategoryRemote()
    : super(dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1')));

  @override
  Future<List<CategoryApiModel>> getCategories({
    String? type,
    String? inventoryId,
    CancelToken? cancelToken,
  }) async => const [CategoryApiModel(id: '390001', name: 'Fashion')];
}

class _FakeSaleProductRepository implements SaleProductRepository {
  @override
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int perPage = 10,
    CancelToken? cancelToken,
  }) async => {
    'data': <dynamic>[],
    'meta': {'current_page': page, 'last_page': 1, 'total': 0},
  };
}

/// Nothing in this screen submits, so every write path says so rather than
/// quietly succeeding.
class _FakeSaleRepository implements SaleRepository {
  @override
  Future<void> createSale({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
    CancelToken? cancelToken,
    String? idempotencyKey,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> enqueueLocalCardSale({
    required String userName,
    required String voucherNo,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
    String? idempotencyKey,
  }) async =>
      throw UnimplementedError();
}

class _FakeOrderRepository implements OrderRepository {
  @override
  Future<String> createOrder({
    required String userName,
    required String voucherNo,
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? payMethod,
    required List<SaleItemEntity> items,
    required double grandTotal,
    int? discount,
    String? notes,
    String status = 'draft',
    bool allowLocalFallback = true,
    String? idempotencyKey,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<String> addOrderItems({
    required String orderId,
    required List<SaleItemEntity> items,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteOrder(String orderId) async =>
      throw UnimplementedError();
}

class _FakeCustomerRepository implements CustomerRepository {
  @override
  Future<Map<String, dynamic>> getCustomers({String? search, int page = 1}) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getCustomer(String id) async =>
      throw UnimplementedError();

  @override
  Future<CustomerAnalyticsEntity> getAnalytics() async =>
      throw UnimplementedError();

  @override
  Future<List<CustomerSearchResultEntity>> searchCustomers({
    String? query,
  }) async =>
      throw UnimplementedError();
}
