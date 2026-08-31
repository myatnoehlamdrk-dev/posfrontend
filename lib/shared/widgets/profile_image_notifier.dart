import 'package:flutter/foundation.dart';

class ProfileImageNotifier extends ValueNotifier<String> {
  static final ProfileImageNotifier instance = ProfileImageNotifier._();
  ProfileImageNotifier._() : super('');

  void update(String url) {
    value = url;
  }
}
