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
    UploadProgressCallback? onProgress,
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
        // A shop on a slow connection is the case this exists for: without it
        // the card can only say "waiting", which is what makes people tap
        // again mid-upload. Setting the callback also stops Dio's default
        // receiveTimeout from killing a slow-but-working transfer -- see
        // ApiClient's upload timeout.
        onSendProgress: onProgress,
        options: Options(
          // Sent in both directions on purpose: this is the *send* timeout for
          // a multi-megabyte body, not the request timeout an ordinary JSON
          // call wants. 20s is plenty for a small payload and far too short
          // for a 5MB photo on a 1Mbps line.
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
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
        // Present only when the bytes are on the API host's disk.
        storedLocally: data['stored_locally'] == true,
        // `fallback` is sent only when local storage caught an ImgBB failure;
        // a response that predates the flag is treated as the ImgBB success
        // it was, so nothing warns spuriously.
        fellBack: data['fallback'] == true,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
