import 'package:flutter/foundation.dart';

/// A page of results.
@immutable
class Paged<T> {
  const Paged({
    required this.items,
    this.page = 1,
    this.pageSize = 50,
    this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;

  /// Total rows on the server, when reported.
  final int? total;

  bool get hasMore {
    final total = this.total;
    if (total == null) return items.length >= pageSize;
    return page * pageSize < total;
  }

  static Paged<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final rawItems = (json['items'] as List?) ?? const [];
    return Paged<T>(
      items: rawItems
          .whereType<Map>()
          .map((item) => parse(item.cast<String, dynamic>()))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 50,
      total: (json['total'] as num?)?.toInt(),
    );
  }
}
