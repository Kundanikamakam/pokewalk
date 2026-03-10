import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../providers/cache_provider.dart';
import '../core/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final orientation = ref.watch(orientationProvider);
    final cachedPages = ref.watch(cachedPagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Font Size ─────────────────────────────────────────────────────
          const _SectionHeader(title: 'DISPLAY'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Font Size'),
                    Text(
                      fontSize.toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: fontSize,
                  min: kFontSizeMin,
                  max: kFontSizeMax,
                  divisions: (kFontSizeMax - kFontSizeMin).toInt(),
                  label: fontSize.toStringAsFixed(0),
                  onChanged: (v) =>
                      ref.read(fontSizeProvider.notifier).setSize(v),
                ),
                // Preview text
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade50,
                  ),
                  child: Text(
                    'Route 2 introduces a new Pokémon: the Dark-type Purrloin.',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Orientation ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Screen Orientation'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'auto', icon: Icon(Icons.screen_rotation), label: Text('Auto')),
                    ButtonSegment(value: 'portrait', icon: Icon(Icons.stay_current_portrait), label: Text('Portrait')),
                    ButtonSegment(value: 'landscape', icon: Icon(Icons.stay_current_landscape), label: Text('Landscape')),
                  ],
                  selected: {orientation},
                  onSelectionChanged: (s) => ref.read(orientationProvider.notifier).set(s.first),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Cache ─────────────────────────────────────────────────────────
          _SectionHeader(
            title: 'OFFLINE CACHE',
            trailing: cachedPages.isNotEmpty
                ? TextButton(
                    child: const Text('Clear All',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmClearAll(context, ref),
                  )
                : null,
          ),

          if (cachedPages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No pages cached yet. Pages you open will be stored here for offline access.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${cachedPages.length} page${cachedPages.length == 1 ? '' : 's'} cached',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            ...cachedPages.map(
              (page) => ListTile(
                dense: true,
                title: Text(
                  page.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Cached ${DateFormat('MMM d, HH:mm').format(page.fetchedAt)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete cache',
                  onPressed: () => ref
                      .read(cachedPagesProvider.notifier)
                      .deletePage(page.url),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all cache?'),
        content: const Text(
            'This will remove all offline copies of pages. You will need an internet connection to view them again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cachedPagesProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear All',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
