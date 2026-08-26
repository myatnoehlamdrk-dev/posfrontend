import 'dart:typed_data';

abstract class ImgbbRepository {
  Future<String> uploadImage(Uint8List bytes, {String? fileName});
}
