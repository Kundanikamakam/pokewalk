import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/page_data.dart';
import 'service_providers.dart';
import 'cache_provider.dart';

sealed class PageState {
  const PageState();
}

class PageIdle extends PageState {
  const PageIdle();
}

class PageLoading extends PageState {
  const PageLoading();
}

class PageLoaded extends PageState {
  final String title;
  final String url;
  final PageData pageData;
  final bool fromCache;
  final DateTime? cachedAt;

  const PageLoaded({
    required this.title,
    required this.url,
    required this.pageData,
    required this.fromCache,
    this.cachedAt,
  });
}

class PageError extends PageState {
  final String message;
  final String url;

  const PageError({required this.message, required this.url});
}

final currentPageUrlProvider = StateProvider<String?>((ref) => null);

final pageStateProvider =
    NotifierProvider<PageNotifier, PageState>(PageNotifier.new);

class PageNotifier extends Notifier<PageState> {
  @override
  PageState build() => const PageIdle();

  Future<void> loadPage(String url, {bool forceRefresh = false}) async {
    state = const PageLoading();
    ref.read(currentPageUrlProvider.notifier).state = url;

    final cacheService = ref.read(cacheServiceProvider);
    final bulbapediaService = ref.read(bulbapediaServiceProvider);

    // Try cache first (unless forcing refresh)
    if (!forceRefresh) {
      final cached = cacheService.loadPage(url);
      if (cached != null) {
        final parsed =
            bulbapediaService.parseFromCache(url, cached.contentHtml);
        state = PageLoaded(
          title: parsed.title,
          url: url,
          pageData: parsed.pageData,
          fromCache: true,
          cachedAt: cached.fetchedAt,
        );
        return;
      }
    }

    try {
      final result = await bulbapediaService.fetchPage(url);

      // Cache the raw HTML for offline use
      await cacheService.savePage(
        url: url,
        title: result.title,
        contentHtml: result.rawHtml,
      );
      ref.read(cachedPagesProvider.notifier).refresh();

      state = PageLoaded(
        title: result.title,
        url: url,
        pageData: result.pageData,
        fromCache: false,
      );
    } catch (e) {
      // Fall back to cache on network failure
      final cached = cacheService.loadPage(url);
      if (cached != null) {
        final parsed =
            bulbapediaService.parseFromCache(url, cached.contentHtml);
        state = PageLoaded(
          title: parsed.title,
          url: url,
          pageData: parsed.pageData,
          fromCache: true,
          cachedAt: cached.fetchedAt,
        );
      } else {
        state = PageError(
          message: e.toString().replaceFirst('Exception: ', ''),
          url: url,
        );
      }
    }
  }

  void reset() => state = const PageIdle();
}

