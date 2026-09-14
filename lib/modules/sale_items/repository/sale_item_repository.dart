import 'package:dio/dio.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';
import 'package:posfrontend/modules/sale_items/model/sale_list_response.dart';

abstract class SaleItemRepository {
  Future<PaginatedSalesResponse> getSales({int page = 1, CancelToken? cancelToken});
  Future<PaginatedOrdersResponse> getOrders({int page = 1, CancelToken? cancelToken});
  Future<SaleDetailResponse> getSaleById(String id, {CancelToken? cancelToken});
  Future<SaleOrder> getOrderById(String id, {CancelToken? cancelToken});
  Future<void> deleteSale(String id, {CancelToken? cancelToken});
  Future<void> deleteOrder(String id, {CancelToken? cancelToken});
  Future<SaleOrder> deleteSaleItem(String saleId, String itemId, {CancelToken? cancelToken});
}
