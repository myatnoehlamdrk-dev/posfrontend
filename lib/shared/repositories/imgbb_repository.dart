import 'dart:typed_data';

import 'package:dio/dio.dart';

class ImgbbUploadResult {
  final String url;
  final String deleteUrl;

  /// True when the bytes are being served by the API host's own disk.
  ///
  /// True for every upload under the default local-first storage, where that
  /// is the plan and not a degradation — see [fellBack] for the case worth
  /// telling the user about.
  final bool storedLocally;

  /// True only when local storage happened *because ImgBB failed*.
  ///
  /// That is the case worth a warning: the photo exists and the URL works,
  /// but the file lives on one machine and disappears with it, and no other
  /// device on the shop's network is guaranteed to reach that host at all.
  /// Under local-first storage this stays false — keeping the photo on the
  /// shop server is the designed path there, and warning about every upload
  /// would train the warning away.
  final bool fellBack;

  const ImgbbUploadResult({
    required this.url,
    required this.deleteUrl,
    this.storedLocally = false,
    this.fellBack = false,
  });
}

/// Reports how much of an upload has left the device.
///
/// [sent] and [total] are bytes; [total] is 0 when the length is not known
/// ahead of time (it always is for the multipart image upload, which carries an
/// explicit content length).
typedef UploadProgressCallback = void Function(int sent, int total);

abstract class ImgbbRepository {
  Future<ImgbbUploadResult> uploadImage(
    Uint8List bytes, {
    String? fileName,
    CancelToken? cancelToken,

    /// Called as the bytes go out, so a UI can draw a determinate progress bar
    /// instead of an indeterminate spinner. A shop on a slow connection is the
    /// case this exists for: the upload can run for a minute, and "waiting with
    /// no number" is what makes people tap again or assume it failed.
    UploadProgressCallback? onProgress,
  });
}
