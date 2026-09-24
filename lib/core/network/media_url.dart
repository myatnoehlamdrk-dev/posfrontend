import 'package:posfrontend/core/network/api_client.dart';

/// Resolves a media URL so it works across every device.
///
/// Backend-local uploads are stored either as a relative path (`/uploads/...`)
/// or as an absolute URL derived from the uploading device's request host
/// (e.g. `http://localhost:8000/uploads/...`). On another device those hosts
/// are unresolvable, so they are rewritten against the API origin. Absolute
/// third-party URLs (ImgBB) are returned unchanged.
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  final value = url.trim();
  if (value.isEmpty) return null;

  if (value.startsWith('/')) {
    return _withApiOrigin(value);
  }

  final uri = Uri.tryParse(value);
  if (uri == null || !value.startsWith('http')) return value;

  final host = uri.host.toLowerCase();
  final isLoopback = host.isEmpty ||
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host == '10.0.2.2';
  final isPrivate = host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      _isPrivate172(host);

  if (uri.path.startsWith('/uploads/') && (isLoopback || isPrivate)) {
    return _withApiOrigin(
      uri.path,
      uri.hasQuery ? uri.query : null,
    );
  }

  return value;
}

bool _isPrivate172(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  return first == 172 && second != null && second >= 16 && second <= 31;
}

String _withApiOrigin(String path, [String? query]) {
  final base = ApiClient.baseUrl.trim();
  if (base.isEmpty) return path;
  return Uri.parse(base).replace(
    path: path,
    query: query,
  ).toString();
}