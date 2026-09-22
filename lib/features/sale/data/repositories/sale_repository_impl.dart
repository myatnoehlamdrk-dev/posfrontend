import 'package:dio/dio.dart';
import 'package:posfrontend/features/sale/data/datasources/sale_remote_data_source.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource _remoteDataSource;

  SaleRepositoryImpl({SaleRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? SaleRemoteDataSource();

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
  }) {
    return _remoteDataSource.createSale(
      userName: userName, voucherNo: voucherNo, orderId: orderId,
      customerName: customerName, customerPhone: customerPhone,
      customerLocation: customerLocation, payMethod: payMethod,
      items: items, grandTotal: grandTotal, discount: discount, notes: notes,
    );
  }
}

class OrderRepositoryImpl implements OrderRepository {
  final SaleRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl({SaleRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? SaleRemoteDataSource();

  @override
  Future<void> createOrder({
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
  }) {
    return _remoteDataSource.createOrder(
      userName: userName, voucherNo: voucherNo, orderId: orderId,
      customerName: customerName, customerPhone: customerPhone,
      payMethod: payMethod, items: items, grandTotal: grandTotal,
      discount: discount, notes: notes, status: status,
    );
  }

  @override
  Future<void> updateOrderStatus({required String orderId, required String status}) {
    return _remoteDataSource.updateOrderStatus(orderId: orderId, status: status);
  }

  @override
  Future<void> deleteOrder(String orderId) {
    return _remoteDataSource.deleteOrder(orderId);
  }
}

class SaleHistoryRepositoryImpl implements SaleHistoryRepository {
  final SaleRemoteDataSource _remoteDataSource;

  SaleHistoryRepositoryImpl({SaleRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? SaleRemoteDataSource();

  @override
  Future<Map<String, dynamic>> getSales({int page = 1, int perPage = 10}) async {
    return await _remoteDataSource.getSales(page: page, perPage: perPage);
  }

  @override
  Future<Map<String, dynamic>> getOrders({int page = 1, int perPage = 10}) async {
    return await _remoteDataSource.getOrders(page: page, perPage: perPage);
  }

  @override
  Future<SaleOrderEntity> getSaleById(String id) async {
    final model = await _remoteDataSource.getSaleById(id);
    return model.toEntity();
  }

  @override
  Future<SaleOrderEntity> getOrderById(String id) async {
    final model = await _remoteDataSource.getSaleById(id);
    return model.toEntity();
  }

  @override
  Future<void> deleteSale(String id) {
    return _remoteDataSource.deleteSale(id);
  }

  @override
  Future<SaleOrderEntity> deleteSaleItem(String saleId, String itemId) async {
    final model = await _remoteDataSource.deleteSaleItem(saleId, itemId);
    return model.toEntity();
  }
}
