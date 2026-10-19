import 'dart:typed_data';

import 'package:dio/dio.dart';

class ImgbbUploadResult {
  final String url;
  final String deleteUrl;

  /// True when the bytes never reached ImgBB and are being served by the API
  /// host instead.
  ///
  /// Such a file lives on one machine and disappears with it, and no other
  /// device on the shop's network is guaranteed to reach that host at all --
  /// so it is worth telling the user rather than passing silently. The URL is
  /// still usable in the meantime, which is why this is a warning and not an
  /// error.
  final bool storedLocally;

  const ImgbbUploadResult({
    required this.url,
    required this.deleteUrl,
    this.storedLocally = false,
  });
}

abstract class ImgbbRepository {
  Future<ImgbbUploadResult> uploadImage(
    Uint8List bytes, {
    String? fileName,
    CancelToken? cancelToken,
  });
}
