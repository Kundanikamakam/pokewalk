import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'router.dart';
import 'providers/service_providers.dart';
import 'services/settings_service.dart';
import 'services/cache_service.dart';

class PokeWalkApp extends ConsumerWidget {
  final SettingsService settingsService;
  final CacheService cacheService;

  const PokeWalkApp({
    super.key,
    required this.settingsService,
    required this.cacheService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
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
    );
  }
}
