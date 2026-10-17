import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nescom/core/config/app_config.dart';
import 'package:nescom/core/network/api_client.dart';

void main() {
  group('ApiClient authorization interceptor', () {
    test('attaches the bearer token to protected requests', () async {
      final adapter = _RecordingAdapter();
      final client = ApiClient(
        config: AppConfig.mock(),
        accessToken: () async => 'test-access-token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      await client.getObject('/user/profile');

      expect(
        adapter.lastRequest?.headers['Authorization'],
        'Bearer test-access-token',
      );
    });

    test(
      'does not attach the saved token to public authentication requests',
      () async {
        final adapter = _RecordingAdapter();
        final client = ApiClient(
          config: AppConfig.mock(),
          accessToken: () async => 'test-access-token',
          dio: Dio()..httpClientAdapter = adapter,
        );

        await client.post(
          '/auth/login',
          body: {'email': 'demo@example.com', 'password': 'demo-password'},
        );

        expect(
          adapter.lastRequest?.headers.containsKey('Authorization'),
          false,
        );
      },
    );
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
