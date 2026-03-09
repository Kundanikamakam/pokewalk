import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cached_page.dart';
import 'service_providers.dart';

final cachedPagesProvider =
    NotifierProvider<CachedPagesNotifier, List<CachedPage>>(
  CachedPagesNotifier.new,
);

class CachedPagesNotifier extends Notifier<List<CachedPage>> {
  @override
  List<CachedPage> build() {
    return ref.read(cacheServiceProvider).listCached();
  }

  void refresh() {
    state = ref.read(cacheServiceProvider).listCached();
  }

  Future<void> deletePage(String url) async {
    await ref.read(cacheServiceProvider).deletePage(url);
    refresh();
  }

  Future<void> clearAll() async {
    await ref.read(cacheServiceProvider).clearAll();
    refresh();
  }
}
