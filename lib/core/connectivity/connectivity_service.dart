import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports **device connectivity only**.
///
/// This is deliberately not a measure of backend reachability — a device can be
/// online while the API is unreachable, and vice versa. Screens must still
/// handle request failures.
abstract interface class ConnectivityService {
  Stream<bool> get onStatusChange;

  Future<bool> isOnline();
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnlineResult).distinct();

  @override
  Future<bool> isOnline() async =>
      _isOnlineResult(await _connectivity.checkConnectivity());

  static bool _isOnlineResult(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}

/// Deterministic connectivity for tests and previews.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool online = true}) : _online = online;

  final _controller = StreamController<bool>.broadcast();
  bool _online;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<bool> isOnline() async => _online;

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}
