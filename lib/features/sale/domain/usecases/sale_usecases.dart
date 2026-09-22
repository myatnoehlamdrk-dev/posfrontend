import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/sale/domain/entities/sale.dart';
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart';

class CreateSaleUseCase extends UseCase<void, CreateSaleParams> {
  final SaleRepository _repository;

  CreateSaleUseCase(this._repository);

  @override
  Future<void> call(CreateSaleParams params) {
    return _repository.createSale(
      userName: params.userName,
      voucherNo: params.voucherNo,
      orderId: params.orderId,
      customerName: params.customerName,
      customerPhone: params.customerPhone,
      customerLocation: params.customerLocation,
      payMethod: params.payMethod,
      items: params.items,
      grandTotal: params.grandTotal,
      discount: params.discount,
      notes: params.notes,
    );
  }
}

class CreateSaleParams {
  final String userName;
  final String voucherNo;
  final String orderId;
  final String? customerName;
  final String? customerPhone;
  final String? customerLocation;
  final String? payMethod;
  final List<SaleItemEntity> items;
  final double grandTotal;
  final int? discount;
  final String? notes;

  const CreateSaleParams({
    required this.userName,
    required this.voucherNo,
    required this.orderId,
    this.customerName,
    this.customerPhone,
    this.customerLocation,
    this.payMethod,
    required this.items,
    required this.grandTotal,
    this.discount,
    this.notes,
  });
}

class CreateOrderUseCase extends UseCase<void, CreateOrderParams> {
  final OrderRepository _repository;

  CreateOrderUseCase(this._repository);

  @override
  Future<void> call(CreateOrderParams params) {
    return _repository.createOrder(
      userName: params.userName,
      voucherNo: params.voucherNo,
      orderId: params.orderId,
      customerName: params.customerName,
      customerPhone: params.customerPhone,
      payMethod: params.payMethod,
      items: params.items,
      grandTotal: params.grandTotal,
      discount: params.discount,
      notes: params.notes,
      status: params.status,
    );
  }
}

class CreateOrderParams {
  final String userName;
  final String voucherNo;
  final String orderId;
  final String? customerName;
  final String? customerPhone;
  final String? payMethod;
  final List<SaleItemEntity> items;
  final double grandTotal;
  final int? discount;
  final String? notes;
  final String status;

  const CreateOrderParams({
    required this.userName,
    required this.voucherNo,
    required this.orderId,
    this.customerName,
    this.customerPhone,
    this.payMethod,
    required this.items,
    required this.grandTotal,
    this.discount,
    this.notes,
    this.status = 'draft',
  });
}

class DeleteOrderUseCase extends UseCase<void, String> {
  final OrderRepository _repository;

  DeleteOrderUseCase(this._repository);

  @override
  Future<void> call(String orderId) {
    return _repository.deleteOrder(orderId);
  }
}

class GetSalesUseCase extends UseCase<Map<String, dynamic>, GetSalesParams> {
  final SaleHistoryRepository _repository;

  GetSalesUseCase(this._repository);

  @override
  Future<Map<String, dynamic>> call(GetSalesParams params) {
    return _repository.getSales(page: params.page, perPage: params.perPage);
  }
}

class GetSalesParams {
  final int page;
  final int perPage;
  const GetSalesParams({this.page = 1, this.perPage = 10});
}

class GetOrdersUseCase extends UseCase<Map<String, dynamic>, GetOrdersParams> {
  final SaleHistoryRepository _repository;

  GetOrdersUseCase(this._repository);

  @override
  Future<Map<String, dynamic>> call(GetOrdersParams params) {
    return _repository.getOrders(page: params.page, perPage: params.perPage);
  }
}

class GetOrdersParams {
  final int page;
  final int perPage;
  const GetOrdersParams({this.page = 1, this.perPage = 10});
}

class DeleteSaleUseCase extends UseCase<void, String> {
  final SaleHistoryRepository _repository;

  DeleteSaleUseCase(this._repository);

  @override
  Future<void> call(String id) {
    return _repository.deleteSale(id);
  }
}

class DeleteSaleItemUseCase extends UseCase<SaleOrderEntity, DeleteSaleItemParams> {
  final SaleHistoryRepository _repository;

  DeleteSaleItemUseCase(this._repository);

  @override
  Future<SaleOrderEntity> call(DeleteSaleItemParams params) {
    return _repository.deleteSaleItem(params.saleId, params.itemId);
  }
}

class DeleteSaleItemParams {
  final String saleId;
  final String itemId;
  const DeleteSaleItemParams({required this.saleId, required this.itemId});
}
