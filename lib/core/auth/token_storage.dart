import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _key = 'auth_token';

  /// Persist the raw bearer token (without the "Bearer " prefix).
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// Read the stored bearer token, or null if not logged in.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_key);
    return (token == null || token.isEmpty) ? null : token;
  }

  /// Remove the stored token (used on logout).
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
