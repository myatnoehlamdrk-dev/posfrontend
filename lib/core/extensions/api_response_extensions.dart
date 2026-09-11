List<dynamic> parseApiList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    final inner = data['data'];
    return inner is List ? inner : [];
  }
  return [];
}

List<T> parseTypedList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) =>
    parseApiList(data)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
