import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/settings_service.dart';
import 'services/cache_service.dart';
import 'providers/service_providers.dart';
import 'router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final cacheService = CacheService();
  await cacheService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
        cacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: MaterialApp.router(
        title: 'PokeWalk',
        theme: AppTheme.theme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
