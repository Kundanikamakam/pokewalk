import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/page_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/cache_provider.dart';
import '../providers/service_providers.dart';
import '../models/page_data.dart';
import '../models/pinned_page.dart';
import '../widgets/wiki_renderer.dart';
import '../widgets/browse_view.dart';
import '../widgets/walkthrough_index_view.dart';
import '../widgets/cache_action_bar.dart';

class WalkthroughScreen extends ConsumerStatefulWidget {
  final String url;

  const WalkthroughScreen({super.key, required this.url});

  @override
  ConsumerState<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends ConsumerState<WalkthroughScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pageStateProvider.notifier).loadPage(widget.url);
    });
  }

  void _handleNavigate(String url) {
    context.push('/page', extra: url);
  }

  Future<void> _handleRefresh() async {
    await ref
        .read(pageStateProvider.notifier)
        .loadPage(widget.url, forceRefresh: true);
  }

  Future<void> _handleDeleteCache() async {
    await ref.read(cacheServiceProvider).deletePage(widget.url);
    ref.read(cachedPagesProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache deleted')),
      );
    }
    await ref
        .read(pageStateProvider.notifier)
        .loadPage(widget.url, forceRefresh: true);
  }

  Future<void> _togglePin(String title) async {
    final notifier = ref.read(pinnedPagesProvider.notifier);
    if (notifier.isPinned(widget.url)) {
      await notifier.unpin(widget.url);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Page unpinned')));
      }
    } else {
      await notifier.pin(PinnedPage(url: widget.url, title: title));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Page pinned')));
      }
    }
  }

  Future<void> _maybeAutoPin(String title) async {
    final settings = ref.read(settingsServiceProvider);
    if (!settings.hasAutopinnedFirstPage) {
      await settings.setAutopinnedFirstPage();
      await ref
          .read(pinnedPagesProvider.notifier)
          .pin(PinnedPage(url: widget.url, title: title));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(pageStateProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final isPinned = ref.watch(pinnedPagesProvider.notifier).isPinned(widget.url);

    return Scaffold(
      appBar: _buildAppBar(pageState, isPinned),
      body: _buildBody(pageState, fontSize),
    );
  }

  PreferredSizeWidget _buildAppBar(PageState state, bool isPinned) {
    String title = 'Loading…';
    if (state is PageLoaded) title = state.title;
    if (state is PageError) title = 'Error';

    // Only show font controls on chapter pages
    final isChapter = state is PageLoaded && state.pageData is ChapterData;

    return AppBar(
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
        if (state is PageLoaded)
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
            ),
            tooltip: isPinned ? 'Unpin' : 'Pin',
            onPressed: () => _togglePin(state.title),
          ),
      ],
    );
  }

  Widget _buildBody(PageState state, double fontSize) {
    return switch (state) {
      PageIdle() => const Center(child: CircularProgressIndicator()),
      PageLoading() => const Center(child: CircularProgressIndicator()),
      PageError(:final message, :final url) => _buildError(message, url),
      PageLoaded() => _buildLoaded(state, fontSize),
    };
  }

  Widget _buildChapterData(ChapterPageData data, double fontSize) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: WikiRenderer(
        html: data.processedHtml,
        fontSize: fontSize,
        onNavigate: _handleNavigate,
      ),
    );
  }

  Widget _buildLoaded(PageLoaded state, double fontSize) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeAutoPin(state.title));

    return Column(
      children: [
        CacheActionBar(
          fromCache: state.fromCache,
          cachedAt: state.cachedAt,
          onRefresh: _handleRefresh,
          onDeleteCache: _handleDeleteCache,
        ),
        Expanded(
          child: _buildPageContent(state.pageData, state.url, fontSize),
        ),
      ],
    );
  }

  Widget _buildPageContent(PageData pageData, String url, double fontSize) {
    return switch (pageData) {
      BrowseData(:final data) => BrowseView(
          data: data,
          onGameTap: (game) => _handleNavigate(game.url),
        ),
      IndexData(:final data) => WalkthroughIndexView(
          data: data,
          onChapterTap: (chapter) => _handleNavigate(chapter.url),
        ),
      ChapterData(:final data) => _buildChapterData(data, fontSize),
    };
  }

  Widget _buildError(String message, String url) {
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
              onPressed: () => ref
                  .read(pageStateProvider.notifier)
                  .loadPage(url, forceRefresh: true),
            ),
          ],
        ),
      ),
    );
  }
}

