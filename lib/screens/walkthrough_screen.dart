import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/page_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/cache_provider.dart';
import '../providers/service_providers.dart';
import '../models/pinned_page.dart';
import '../widgets/wiki_renderer.dart';
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
    // Reload from network
    await ref
        .read(pageStateProvider.notifier)
        .loadPage(widget.url, forceRefresh: true);
  }

  Future<void> _togglePin(String title) async {
    final notifier = ref.read(pinnedPagesProvider.notifier);
    if (notifier.isPinned(widget.url)) {
      await notifier.unpin(widget.url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page unpinned')),
        );
      }
    } else {
      await notifier.pin(PinnedPage(url: widget.url, title: title));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page pinned')),
        );
      }
    }
  }

  /// Auto-pin the first page the user ever opens.
  Future<void> _maybeAutoPin(String title) async {
    final settings = ref.read(settingsServiceProvider);
    if (!settings.hasAutopinnedFirstPage) {
      await settings.setAutopinnedFirstPage();
      await ref.read(pinnedPagesProvider.notifier).pin(
            PinnedPage(url: widget.url, title: title),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(pageStateProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: _buildAppBar(pageState),
      body: _buildBody(pageState, fontSize),
    );
  }

  PreferredSizeWidget _buildAppBar(PageState state) {
    final isPinned = ref.watch(pinnedPagesProvider.notifier).isPinned(widget.url);
    String title = 'Loading…';
    if (state is PageLoaded) title = state.page.title;
    if (state is PageError) title = 'Error';

    return AppBar(
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        if (state is PageLoaded) ...[
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 18),
            tooltip: 'Decrease font',
            onPressed: () => ref.read(fontSizeProvider.notifier).decrease(),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, size: 18),
            tooltip: 'Increase font',
            onPressed: () => ref.read(fontSizeProvider.notifier).increase(),
          ),
          // Pin toggle
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
            ),
            tooltip: isPinned ? 'Unpin' : 'Pin',
            onPressed: () => _togglePin(state.page.title),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(PageState state, double fontSize) {
    return switch (state) {
      PageIdle() => const Center(child: CircularProgressIndicator()),
      PageLoading() => const Center(child: CircularProgressIndicator()),
      PageError(:final message, :final url) => _buildError(message, url),
      PageLoaded(:final page, :final fromCache, :final cachedAt) =>
        _buildContent(page.contentHtml, fromCache, cachedAt, fontSize, page.title),
    };
  }

  Widget _buildContent(
    String html,
    bool fromCache,
    DateTime? cachedAt,
    double fontSize,
    String title,
  ) {
    // Auto-pin on first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoPin(title));

    return Column(
      children: [
        CacheActionBar(
          fromCache: fromCache,
          cachedAt: cachedAt,
          onRefresh: _handleRefresh,
          onDeleteCache: _handleDeleteCache,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: WikiRenderer(
              html: html,
              fontSize: fontSize,
              onNavigate: _handleNavigate,
            ),
          ),
        ),
      ],
    );
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
            Text(
              'Could not load page',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
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
