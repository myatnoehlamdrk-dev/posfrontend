class PaginatedResponse<T> {
  final List<T> data;
  final int lastPage;
  final int currentPage;
  final int total;

  const PaginatedResponse({
    required this.data,
    required this.lastPage,
    required this.currentPage,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final meta = json['meta'];
    final rawList = json['data'];
    final List<dynamic> items = rawList is List ? rawList : [];

    int lastPage = 1;
    int currentPage = 1;
    int total = 0;

    if (meta is Map<String, dynamic>) {
      lastPage = meta['last_page'] ?? 1;
      currentPage = meta['current_page'] ?? 1;
      total = meta['total'] ?? 0;
    }

    return PaginatedResponse(
      data: items
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(),
      lastPage: lastPage,
      currentPage: currentPage,
      total: total,
    );
  }
}
