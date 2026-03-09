import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../services/cache_service.dart';
import '../services/bulbapedia_service.dart';

// ── Service singletons ───────────────────────────────────────────────────────

final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('Override this provider in ProviderScope');
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError('Override this provider in ProviderScope');
});

final bulbapediaServiceProvider = Provider<BulbapediaService>((ref) {
  final service = BulbapediaService();
  ref.onDispose(service.dispose);
  return service;
});
