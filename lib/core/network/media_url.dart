import 'package:posfrontend/core/network/api_client.dart';

/// Resolves a media URL so it works across every device.
///
/// Backend-local uploads are stored either as a relative path (`/uploads/...`)
/// or as an absolute URL derived from the uploading device's request host
/// (e.g. `http://localhost:8000/uploads/...`). On another device those hosts
/// are unresolvable, so they are rewritten against the API origin. Absolute
/// third-party URLs (ImgBB) are returned unchanged.
///
/// The `/uploads/` rewrite deliberately ignores the host it was written with.
/// The database is shared across machines while `public/uploads` is not, so a
/// row can carry a LAN address that has since changed (the same shop folder
/// has been recorded under `.104`, `.112` and `.109`) or a machine that is no
/// longer running. Every one of those points at a file the configured API
/// origin is the only thing likely to still serve — and on the old rule a
/// stale-but-public-looking host was left alone, which is how uploaded photos
/// turned into broken-image icons everywhere. ImgBB and any other real
/// third-party host never serves `/uploads/`, so nothing legitimate is
/// hijacked by this.
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  final value = url.trim();
  if (value.isEmpty) return null;

  if (value.startsWith('/')) {
    return _withApiOrigin(value);
  }

  final uri = Uri.tryParse(value);
  if (uri == null || !value.startsWith('http')) return value;

  if (uri.path.startsWith('/uploads/')) {
    return _withApiOrigin(uri.path, uri.hasQuery ? uri.query : null);
  }

  final host = uri.host.toLowerCase();
  final isLoopback =
      host.isEmpty ||
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host == '10.0.2.2';
  final isPrivate =
      host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      _isPrivate172(host);

  // Not an upload path, but still served from the box that uploaded it: an
  // image the backend put somewhere else under its own origin. A bare host
  // with no path is not media at all, so it is left alone.
  if (uri.path.isEmpty) return value;
  if (isLoopback || isPrivate) {
    return _withApiOrigin(uri.path, uri.hasQuery ? uri.query : null);
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
  return Uri.parse(base).replace(path: path, query: query).toString();
}
