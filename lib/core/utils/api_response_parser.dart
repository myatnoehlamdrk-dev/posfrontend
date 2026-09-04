class ApiResponseParser {
  ApiResponseParser._();

  /// Extract a list from various API response formats.
  /// Handles: List, Map with 'data' key, or empty.
  static List<dynamic> asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      return inner is List ? inner : [];
    }
    return [];
  }

  /// Extract a map from various API response formats.
  /// If the response is already a Map, return it.
  /// If it has a 'data' key, return that.
  static Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return {};
  }
}
