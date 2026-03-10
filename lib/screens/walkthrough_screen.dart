import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/page_data.dart';
import '../models/pinned_page.dart';
import '../providers/settings_provider.dart';
import '../providers/cache_provider.dart';
import '../providers/service_providers.dart';
import '../widgets/wiki_renderer.dart';
import '../widgets/browse_view.dart';
import '../widgets/walkthrough_index_view.dart';
import '../widgets/chapter_nav_widget.dart';
import '../widgets/cache_action_bar.dart';

// ── Local page state (per-screen, not shared) ─────────────────────────────────

sealed class _PageState {}
class _Loading extends _PageState {}
class _Loaded extends _PageState {
  final String title;
  final PageData pageData;
  final bool fromCache;
  final DateTime? cachedAt;
  _Loaded({required this.title, required this.pageData, required this.fromCache, this.cachedAt});
}
class _Error extends _PageState {
  final String message;
  _Error(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────

class WalkthroughScreen extends ConsumerStatefulWidget {
  final String url;

  const WalkthroughScreen({super.key, required this.url});

  @override
  ConsumerState<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends ConsumerState<WalkthroughScreen> {
  _PageState _state = _Loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _state = _Loading());

    final cacheService = ref.read(cacheServiceProvider);
    final bulbapediaService = ref.read(bulbapediaServiceProvider);

    // Serve from cache first unless refreshing
    if (!forceRefresh) {
      final cached = cacheService.loadPage(widget.url);
      if (cached != null) {
        final parsed = bulbapediaService.parseFromCache(widget.url, cached.contentHtml);
        if (!mounted) return;
        setState(() => _state = _Loaded(
              title: parsed.title,
              pageData: parsed.pageData,
              fromCache: true,
              cachedAt: cached.fetchedAt,
            ));
        return;
      }
    }

    try {
      final result = await bulbapediaService.fetchPage(widget.url);
      if (!mounted) return;

      await cacheService.savePage(
        url: widget.url,
        title: result.title,
        contentHtml: result.rawHtml,
      );
      ref.read(cachedPagesProvider.notifier).refresh();

      if (!mounted) return;
      setState(() => _state = _Loaded(
            title: result.title,
            pageData: result.pageData,
            fromCache: false,
          ));
    } catch (e) {
      if (!mounted) return;
      // Fallback to cache
      final cached = cacheService.loadPage(widget.url);
      if (cached != null) {
        final parsed = bulbapediaService.parseFromCache(widget.url, cached.contentHtml);
        if (!mounted) return;
        setState(() => _state = _Loaded(
              title: parsed.title,
              pageData: parsed.pageData,
              fromCache: true,
              cachedAt: cached.fetchedAt,
            ));
      } else {
        setState(() => _state = _Error(
              e.toString().replaceFirst('Exception: ', ''),
            ));
      }
    }
  }

  void _handleNavigate(String url) => context.push('/page', extra: url);

  Future<void> _handleDeleteCache() async {
    await ref.read(cacheServiceProvider).deletePage(widget.url);
    ref.read(cachedPagesProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cache deleted')));
    await _load(forceRefresh: true);
  }

  Future<void> _togglePin(String title) async {
    final notifier = ref.read(pinnedPagesProvider.notifier);
    if (notifier.isPinned(widget.url)) {
      await notifier.unpin(widget.url);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Page unpinned')));
    } else {
      await notifier.pin(PinnedPage(url: widget.url, title: title));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Page pinned')));
    }
  }

  Future<void> _maybeAutoPin(String title) async {
    if (!mounted) return;
    final settings = ref.read(settingsServiceProvider);
    if (!settings.hasAutopinnedFirstPage) {
      await settings.setAutopinnedFirstPage();
      if (!mounted) return;
      await ref
          .read(pinnedPagesProvider.notifier)
          .pin(PinnedPage(url: widget.url, title: title));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final state = _state;

    // Derived values for AppBar
    final title = state is _Loaded ? state.title : 'Loading…';
    final isPinned = ref.watch(pinnedPagesProvider).any((p) => p.url == widget.url);
    final isChapter = state is _Loaded && state.pageData is ChapterData;

    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14)),
        actions: [
          if (isChapter) ...[
            IconButton(
              icon: const Icon(Icons.text_decrease, size: 18),
              tooltip: 'Smaller text',
              onPressed: () => ref.read(fontSizeProvider.notifier).decrease(),
            ),
            IconButton(
              icon: const Icon(Icons.text_increase, size: 18),
              tooltip: 'Larger text',
              onPressed: () => ref.read(fontSizeProvider.notifier).increase(),
            ),
          ],
          if (state is _Loaded)
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18),
              tooltip: isPinned ? 'Unpin' : 'Pin',
              onPressed: () => _togglePin(state.title),
            ),
        ],
      ),
      body: _buildBody(state, fontSize),
    );
  }

  Widget _buildBody(_PageState state, double fontSize) {
    return switch (state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Error(:final message) => _buildError(message),
      _Loaded() => _buildLoaded(state, fontSize),
    };
  }

  Widget _buildLoaded(_Loaded state, double fontSize) {
    // Auto-pin after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeAutoPin(state.title);
    });

    return Column(
      children: [
        CacheActionBar(
          fromCache: state.fromCache,
          cachedAt: state.cachedAt,
          onRefresh: () => _load(forceRefresh: true),
          onDeleteCache: _handleDeleteCache,
        ),
        Expanded(child: _buildContent(state.pageData, fontSize)),
      ],
    );
  }

  Widget _buildContent(PageData pageData, double fontSize) {
    return switch (pageData) {
      BrowseData(:final data) => BrowseView(
          data: data,
          onGameTap: (game) => _handleNavigate(game.url),
        ),
      IndexData(:final data) => WalkthroughIndexView(
          data: data,
          onChapterTap: (chapter) => _handleNavigate(chapter.url),
        ),
      ChapterData(:final data) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: WikiRenderer(
                  html: data.processedHtml,
                  fontSize: fontSize,
                  onNavigate: _handleNavigate,
                  partyContainers: data.partyContainers,
                  expandableSections: data.expandableSections,
                ),
              ),
            ),
            if (data.nav != null)
              ChapterNavWidget(
                nav: data.nav!,
                onNavigate: _handleNavigate,
              ),
          ],
        ),
    };
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Could not load page',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _load(forceRefresh: true),
            ),
          ],
        ),
      ),
    );
  }
}

