import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart';

class SaleProductRepositoryImpl implements SaleProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  SaleProductRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<Map<String, dynamic>> getProducts({int page = 1, int perPage = 10, CancelToken? cancelToken}) async {
    return await _remoteDataSource.getProducts(
      page: page,
      perPage: perPage,
      cancelToken: cancelToken,
    );
  }
}
