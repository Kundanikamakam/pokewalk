import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/page_data.dart';

class WalkthroughIndexView extends StatelessWidget {
  final IndexPageData data;
  final void Function(ChapterEntry chapter) onChapterTap;

  const WalkthroughIndexView({
    super.key,
    required this.data,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Game header with box art
        _buildHeader(context),
        // Chapter sections
        ...data.sections.expand((s) => [
              _SectionHeader(title: s.title),
              ...s.chapters.map(
                (ch) => _ChapterTile(
                  chapter: ch,
                  onTap: () => onChapterTap(ch),
                ),
              ),
            ]),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF3B5BA5),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          if (data.gameImageUrl != null)
            CachedNetworkImage(
              imageUrl: data.gameImageUrl!,
              height: 72,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(width: 56, height: 72),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.catching_pokemon, color: Colors.white, size: 48),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.gameTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final ChapterEntry chapter;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF3B5BA5).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _partNumber(chapter.name),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3B5BA5),
          ),
        ),
      ),
      title: Text(
        chapter.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: chapter.description.isNotEmpty
          ? Text(
              chapter.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  String _partNumber(String name) {
    final match = RegExp(r'\d+').firstMatch(name);
    return match != null ? match.group(0)! : '?';
  }
}
