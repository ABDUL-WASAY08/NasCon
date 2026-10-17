import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/config/app_config.dart';
import 'package:nescom/core/storage/local_database.dart';
import 'package:nescom/core/storage/secure_storage_service.dart';
import 'package:nescom/core/theme/app_theme.dart';
import 'package:nescom/repositories/mock/mock_repositories.dart';
import 'package:nescom/repositories/repository_providers.dart';

/// Builds a provider container wired entirely to in-memory doubles, so no test
/// touches the network, platform channels or the device database.
///
/// * mock repositories (no HTTP)
/// * in-memory SQLite-equivalent store (no native dependency)
/// * in-memory session store (no Keychain/Keystore)
/// * zero-latency mock backend (no arbitrary waits)
ProviderContainer testContainer({
  MockBackend? backend,
  SessionStore? sessionStore,
  LocalDatabase? database,
  AppConfig? config,
}) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config ?? AppConfig.mock()),
      localDatabaseProvider.overrideWithValue(database ?? MemoryLocalDatabase()),
      sessionStoreProvider.overrideWithValue(
        sessionStore ?? InMemorySessionStore(),
      ),
      mockBackendProvider.overrideWithValue(
        backend ?? MockBackend(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Wraps a single screen with the theme and the provided container.
Widget wrapScreen(Widget child, ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: child,
      ),
    );
