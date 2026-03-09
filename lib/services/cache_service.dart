import 'package:hive_flutter/hive_flutter.dart';
import '../models/cached_page.dart';

class CacheService {
  static const _boxName = 'cached_pages';

  Box<CachedPage>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedPageAdapter());
    }
    _box = await Hive.openBox<CachedPage>(_boxName);
  }

  Box<CachedPage> get _safeBox {
    assert(_box != null, 'CacheService.init() must be called first');
    return _box!;
  }

  Future<void> savePage({
    required String url,
    required String title,
    required String contentHtml,
  }) async {
    final page = CachedPage(
      url: url,
      title: title,
      contentHtml: contentHtml,
      fetchedAt: DateTime.now(),
    );
    await _safeBox.put(url, page);
  }

  CachedPage? loadPage(String url) => _safeBox.get(url);

  Future<void> deletePage(String url) async {
    await _safeBox.delete(url);
  }

  Future<void> clearAll() async {
    await _safeBox.clear();
  }

  List<CachedPage> listCached() {
    return _safeBox.values.toList()
      ..sort((a, b) => b.fetchedAt.compareTo(a.fetchedAt));
  }

  int get cacheCount => _safeBox.length;
}
