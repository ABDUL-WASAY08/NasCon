import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/storage/local_database.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/theme_mode_provider.dart';
import 'repositories/repository_providers.dart';

/// Bootstraps the app.
///
/// Order matters: bindings → configuration → persistent store → preferences →
/// secure storage → session restore → run. Nothing is deferred to the splash,
/// so startup cannot get stuck behind a network call.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();

  final database = SqfliteLocalDatabase();
  await database.open();

  final preferences = PreferencesService();
  await preferences.init();

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      localDatabaseProvider.overrideWithValue(database),
      preferencesServiceProvider.overrideWithValue(preferences),
      sessionStoreProvider.overrideWithValue(SecureStorageService()),
    ],
  );

  // Restore the persisted theme and resolve any stored session before the first
  // frame, so the router can redirect without a visible flash.
  await container.read(themeModeProvider.notifier).load();
  await container.read(sessionProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NescomApp(),
    ),
  );
}
