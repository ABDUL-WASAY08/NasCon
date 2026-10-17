import 'package:flutter/foundation.dart';

/// Receipt metadata for a confirmed order.
@immutable
class Receipt {
  const Receipt({
    required this.orderId,
    required this.receiptNumber,
    required this.issuedAt,
    required this.total,
    this.currency = 'PKR',
    this.downloadUrl,
  });

  final String orderId;
  final String receiptNumber;
  final DateTime issuedAt;
  final double total;
  final String currency;

  /// Server-hosted PDF, when the backend offers one. When absent the app
  /// generates the PDF locally.
  final String? downloadUrl;

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    orderId: json['order_id'] as String? ?? '',
    receiptNumber: json['receipt_number'] as String? ?? '',
    issuedAt:
        DateTime.tryParse(json['issued_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    total: (json['total'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? 'PKR',
    downloadUrl: json['download_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'receipt_number': receiptNumber,
    'issued_at': issuedAt.toUtc().toIso8601String(),
    'total': total,
    'currency': currency,
    'download_url': downloadUrl,
  };
}
