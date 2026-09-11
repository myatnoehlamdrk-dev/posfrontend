import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/modules/sale_items/model/sale_item_models.dart';

typedef PaginatedSalesResponse = PaginatedResponse<SaleOrder>;
typedef PaginatedOrdersResponse = PaginatedResponse<SaleOrder>;

class SaleDetailResponse {
  final SaleOrder data;

  const SaleDetailResponse({required this.data});

  factory SaleDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      return SaleDetailResponse(data: SaleOrder.fromJson(rawData));
    }
    return SaleDetailResponse(data: SaleOrder.fromJson(json));
  }
}
