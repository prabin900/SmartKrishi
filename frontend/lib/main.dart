import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/firebase/firebase_service.dart';
import 'core/firebase/remote_config_service.dart';
import 'core/firebase/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase App and FCM
  await FirebaseService.initialize();

  // Initialize Remote Config
  await RemoteConfigService.initialize();

  // Log App Open in Analytics
  await AnalyticsService.logAppOpen();

  // Set up Crashlytics crash detection (supported on mobile only)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(
    const ProviderScope(
      child: SmartKrishiApp(),
    ),
  );
}

class SmartKrishiApp extends StatelessWidget {
  const SmartKrishiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartKrishi',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
