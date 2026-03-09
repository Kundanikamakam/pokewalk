import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shows cache status + Refresh / Delete buttons for a page view.
class CacheActionBar extends StatelessWidget {
  final bool fromCache;
  final DateTime? cachedAt;
  final VoidCallback onRefresh;
  final VoidCallback onDeleteCache;

  const CacheActionBar({
    super.key,
    required this.fromCache,
    this.cachedAt,
    required this.onRefresh,
    required this.onDeleteCache,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = fromCache && cachedAt != null
        ? 'Cached ${_formatAge(cachedAt!)}'
        : fromCache
            ? 'Cached'
            : 'Live';

    return Container(
      color: fromCache
          ? Colors.amber.shade50
          : Colors.green.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            fromCache ? Icons.cloud_off : Icons.cloud_done,
            size: 14,
            color: fromCache ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: fromCache ? Colors.orange.shade800 : Colors.green.shade800,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
            ),
          ),
          TextButton.icon(
            onPressed: onDeleteCache,
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text('Delete', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              foregroundColor: Colors.red,
            ),
          ),
        ],
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
