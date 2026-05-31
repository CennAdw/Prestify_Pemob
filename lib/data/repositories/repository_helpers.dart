List<Map<String, dynamic>> asMapList(dynamic data) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  if (data is Map<String, dynamic>) {
    final nested = data['items'] ?? data['rows'] ?? data['data'];
    if (nested is List) {
      return nested.whereType<Map<String, dynamic>>().toList();
    }
  }
  return const [];
}

Map<String, dynamic> asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  return const {};
}
