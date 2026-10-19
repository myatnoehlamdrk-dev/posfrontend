import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';

class ImgbbRepositoryImpl implements ImgbbRepository {
  final Dio _dio;

  ImgbbRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  @override
  Future<ImgbbUploadResult> uploadImage(
    Uint8List bytes, {
    String? fileName,
    CancelToken? cancelToken,
  }) async {
    try {
      final name =
          fileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ext = name.contains('.')
          ? name.split('.').last.toLowerCase()
          : 'jpg';
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

      final response = await _dio.post(
        '/images',
        data: form,
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'Unexpected response from image upload.');
      }
      final url = data['url'] as String?;
      if (url == null) {
        throw ApiException(message: 'Upload did not return a URL');
      }
      // The local fallback builds its URL from the host this device happened
      // to reach the API on, and writing that into the row is what made the
      // same shop folder show up under three different addresses. Resolving
      // here means what is stored is already host-independent.
      final resolved = resolveMediaUrl(url) ?? url;
      return ImgbbUploadResult(
        url: resolved,
        deleteUrl: (data['delete_url'] as String?) ?? '',
        // Present only when the server fell back to local storage; a response
        // that predates the flag is treated as the ImgBB success it was.
        storedLocally: data['stored_locally'] == true,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
