import 'package:posfrontend/modules/sale_items/model/sale_list_response.dart';

abstract class SaleItemRepository {
  Future<PaginatedSalesResponse> getSales({int page = 1});
  Future<PaginatedOrdersResponse> getOrders({int page = 1});
  Future<SaleDetailResponse> getSaleById(String id);
  Future<void> deleteSale(String id);
  Future<void> deleteOrder(String id);
}
