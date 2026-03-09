import 'package:flutter/material.dart';
import '../models/pinned_page.dart';

/// A compact card displayed on the Home screen for a pinned page.
class PinnedCard extends StatelessWidget {
  final PinnedPage page;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  const PinnedCard({
    super.key,
    required this.page,
    required this.onTap,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: Color(0xFF3B5BA5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  page.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Unpin',
                onPressed: onUnpin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
