import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/modules/purchase_items/model/purchase_models.dart';

typedef PaginatedPurchaseItemsResponse = PaginatedResponse<PurchaseOrder>;

class PurchaseItemDetailResponse {
  final PurchaseOrder data;

  const PurchaseItemDetailResponse({required this.data});

  factory PurchaseItemDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      return PurchaseItemDetailResponse(data: PurchaseOrder.fromJson(rawData));
    }
    return PurchaseItemDetailResponse(data: PurchaseOrder.fromJson(json));
  }
}
