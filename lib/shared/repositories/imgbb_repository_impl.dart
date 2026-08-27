import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';

class ImgbbRepositoryImpl implements ImgbbRepository {
  final Dio _dio;

  ImgbbRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<String> uploadImage(Uint8List bytes, {String? fileName}) async {
    try {
      final name = fileName ??
          'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
      final MediaType contentType;
      switch (ext) {
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'gif':
          contentType = MediaType('image', 'gif');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg');
      }

      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: name,
          contentType: contentType,
        ),
      });

      // The upload is proxied through our backend (POST /api/images), which forwards
      // to ImgBB server-side. This keeps the ImgBB API key on the server instead
      // of shipping it inside the client app.
      final response = await _dio.post(
        '/api/images',
        data: form,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'Unexpected response from image upload.');
      }
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
