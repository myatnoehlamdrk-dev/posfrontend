import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';

class ImgbbRepositoryImpl implements ImgbbRepository {
  final Dio _dio;

  ImgbbRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<String> uploadImage(Uint8List bytes, {String? fileName}) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename:
              fileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // The upload is proxied through our backend (POST /api/images), which forwards
      // to ImgBB server-side. This keeps the ImgBB API key on the server instead
      // of shipping it inside the client app.
      final response = await _dio.post(
        '/api/images',
        data: form,
      );

      final data = response.data as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null) {
        throw ApiException(message: 'Upload did not return a URL');
      }
      return url;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
