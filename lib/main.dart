import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NescomApp()));
}

/// The application root.
///
/// Configures [MaterialApp] with the custom light/dark themes (both built from
/// [AppColors] + [AppTextStyles] via [AppTheme]), the global smooth page
/// transition, and starts on the splash.
class NescomApp extends StatelessWidget {
  const NescomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: const SplashScreen(),
    );
  }
}
