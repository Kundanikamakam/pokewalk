import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/page_data.dart';
import '../models/pinned_page.dart';
import '../providers/settings_provider.dart';
import '../providers/cache_provider.dart';
import '../providers/service_providers.dart';
import '../widgets/wiki_renderer.dart';
import '../widgets/browse_view.dart';
import '../widgets/walkthrough_index_view.dart';
import '../widgets/chapter_nav_widget.dart';

// ── Local page state ──────────────────────────────────────────────────────────

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
      await cacheService.savePage(url: widget.url, title: result.title, contentHtml: result.rawHtml);
      ref.read(cachedPagesProvider.notifier).refresh();
      if (!mounted) return;
      setState(() => _state = _Loaded(
        title: result.title,
        pageData: result.pageData,
        fromCache: false,
      ));
    } catch (e) {
      if (!mounted) return;
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
        setState(() => _state = _Error(e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  void _handleNavigate(String url) => context.push('/page', extra: url);

  Future<void> _handleDeleteCache() async {
    if (!mounted) return;
    Navigator.of(context).pop(); // close More menu
    await ref.read(cacheServiceProvider).deletePage(widget.url);
    ref.read(cachedPagesProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache deleted')));
    await _load(forceRefresh: true);
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    Navigator.of(context).pop(); // close More menu
    await _load(forceRefresh: true);
  }

  Future<void> _togglePin(String title) async {
    final notifier = ref.read(pinnedPagesProvider.notifier);
    if (notifier.isPinned(widget.url)) {
      await notifier.unpin(widget.url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page unpinned')));
    } else {
      await notifier.pin(PinnedPage(url: widget.url, title: title));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page pinned')));
    }
  }

  Future<void> _maybeAutoPin(String title) async {
    if (!mounted) return;
    final settings = ref.read(settingsServiceProvider);
    if (!settings.hasAutopinnedFirstPage) {
      await settings.setAutopinnedFirstPage();
      if (!mounted) return;
      await ref.read(pinnedPagesProvider.notifier).pin(PinnedPage(url: widget.url, title: title));
    }
  }

  void _showMoreMenu(BuildContext context, _Loaded state) {
    final fontSize = ref.read(fontSizeProvider);
    final nav = state.pageData is ChapterData ? (state.pageData as ChapterData).data.nav : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _MoreMenuSheet(
        fromCache: state.fromCache,
        cachedAt: state.cachedAt,
        currentFontSize: fontSize,
        nav: nav,
        onRefresh: _handleRefresh,
        onDeleteCache: _handleDeleteCache,
        onNavigate: _handleNavigate,
        onFontIncrease: () => ref.read(fontSizeProvider.notifier).increase(),
        onFontDecrease: () => ref.read(fontSizeProvider.notifier).decrease(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final state = _state;
    final canPop = context.canPop();
    final isPinned = ref.watch(pinnedPagesProvider).any((p) => p.url == widget.url);
    final title = state is _Loaded ? state.title : '';

    return Scaffold(
      body: Stack(
        children: [
          // Main content — fills entire screen
          Positioned.fill(
            child: _buildBody(state, fontSize),
          ),

          // Floating back button (bottom-left) — only if we can go back
          if (canPop)
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 16,
              child: _FloatingCircleButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onTap: () => context.pop(),
              ),
            ),

          // Floating action group (bottom-right): More + Pin
          if (state is _Loaded)
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FloatingCircleButton(
                    icon: Icons.more_vert,
                    tooltip: 'More options',
                    onTap: () => _showMoreMenu(context, state),
                  ),
                  const SizedBox(height: 8),
                  _FloatingCircleButton(
                    icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    tooltip: isPinned ? 'Unpin' : 'Pin',
                    onTap: () => _togglePin(title),
                    active: isPinned,
                  ),
                ],
              ),
            ),
        ],
      ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeAutoPin(state.title);
    });
    return _buildContent(state, fontSize);
  }

  Widget _buildContent(_Loaded state, double fontSize) {
    return switch (state.pageData) {
      BrowseData(:final data) => _BrowseContent(
          title: state.title,
          data: data,
          onGameTap: (game) => _handleNavigate(game.url),
        ),
      IndexData(:final data) => _IndexContent(
          title: state.title,
          data: data,
          onChapterTap: (chapter) => _handleNavigate(chapter.url),
        ),
      ChapterData(:final data) => _ChapterContent(
          title: state.title,
          data: data,
          fontSize: fontSize,
          onNavigate: _handleNavigate,
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
            Text('Could not load page', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
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

// ── Floating circle button ────────────────────────────────────────────────────

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _FloatingCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: active ? cs.primary : cs.surface,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: active ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Browse page content (with inline title) ───────────────────────────────────

class _BrowseContent extends StatelessWidget {
  final String title;
  final BrowsePageData data;
  final void Function(GameEntry) onGameTap;

  const _BrowseContent({required this.title, required this.data, required this.onGameTap});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: BrowseView(data: data, onGameTap: onGameTap),
        ),
      ],
    );
  }
}

// ── Index page content ────────────────────────────────────────────────────────

class _IndexContent extends StatelessWidget {
  final String title;
  final IndexPageData data;
  final void Function(ChapterEntry) onChapterTap;

  const _IndexContent({required this.title, required this.data, required this.onChapterTap});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: WalkthroughIndexView(data: data, onChapterTap: onChapterTap),
        ),
      ],
    );
  }
}

// ── Chapter page content (with inline title + inline nav) ────────────────────

class _ChapterContent extends StatelessWidget {
  final String title;
  final ChapterPageData data;
  final double fontSize;
  final void Function(String url) onNavigate;

  const _ChapterContent({
    required this.title,
    required this.data,
    required this.fontSize,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: topPad + 8,
        bottom: 80 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          WikiRenderer(
            html: data.processedHtml,
            fontSize: fontSize,
            onNavigate: onNavigate,
            partyContainers: data.partyContainers,
            expandableSections: data.expandableSections,
          ),
          if (data.nav != null) ...[
            const SizedBox(height: 12),
            ChapterNavWidget(nav: data.nav!, onNavigate: onNavigate),
          ],
        ],
      ),
    );
  }
}

// ── More menu bottom sheet ────────────────────────────────────────────────────

class _MoreMenuSheet extends ConsumerStatefulWidget {
  final bool fromCache;
  final DateTime? cachedAt;
  final double currentFontSize;
  final ChapterNav? nav;
  final VoidCallback onRefresh;
  final VoidCallback onDeleteCache;
  final void Function(String url) onNavigate;
  final VoidCallback onFontIncrease;
  final VoidCallback onFontDecrease;

  const _MoreMenuSheet({
    required this.fromCache,
    required this.cachedAt,
    required this.currentFontSize,
    required this.nav,
    required this.onRefresh,
    required this.onDeleteCache,
    required this.onNavigate,
    required this.onFontIncrease,
    required this.onFontDecrease,
  });

  @override
  ConsumerState<_MoreMenuSheet> createState() => _MoreMenuSheetState();
}

class _MoreMenuSheetState extends ConsumerState<_MoreMenuSheet> {
  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final cacheStatus = widget.fromCache && widget.cachedAt != null
        ? 'Cached ${_formatAge(widget.cachedAt!)}'
        : widget.fromCache
            ? 'Cached'
            : 'Fetched live';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Font size row
          Row(
            children: [
              const Icon(Icons.text_fields, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              const Expanded(child: Text('Font Size', style: TextStyle(fontWeight: FontWeight.w500))),
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: () { ref.read(fontSizeProvider.notifier).decrease(); setState(() {}); },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              SizedBox(
                width: 32,
                child: Text('${fontSize.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () { ref.read(fontSizeProvider.notifier).increase(); setState(() {}); },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const Divider(height: 16),

          // Cache status row
          Row(
            children: [
              Icon(
                widget.fromCache ? Icons.cloud_off : Icons.cloud_done,
                size: 16,
                color: widget.fromCache ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cacheStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.fromCache ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero),
              ),
              TextButton.icon(
                onPressed: widget.onDeleteCache,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),

          // Chapter navigation (only for chapter pages with nav)
          if (widget.nav != null) ...[
            const Divider(height: 16),
            const Text('Chapter Navigation', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: widget.nav!.prevUrl != null
                      ? OutlinedButton.icon(
                          icon: const Icon(Icons.chevron_left, size: 16),
                          label: Text(
                            widget.nav!.prevLabel ?? 'Previous',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onNavigate(widget.nav!.prevUrl!);
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: widget.nav!.nextUrl != null
                      ? FilledButton.icon(
                          icon: const Icon(Icons.chevron_right, size: 16),
                          label: Text(
                            widget.nav!.nextLabel ?? 'Next',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onNavigate(widget.nav!.nextUrl!);
                          },
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
        ),
      ),
    );
  }

  String _formatAge(DateTime cachedAt) {
    final diff = DateTime.now().difference(cachedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(cachedAt);
  }
}
