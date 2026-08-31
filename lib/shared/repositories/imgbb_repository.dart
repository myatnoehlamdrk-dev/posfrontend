import 'dart:typed_data';

class ImgbbUploadResult {
  final String url;
  final String deleteUrl;
  const ImgbbUploadResult({required this.url, required this.deleteUrl});
}

abstract class ImgbbRepository {
  Future<ImgbbUploadResult> uploadImage(Uint8List bytes, {String? fileName});
}
