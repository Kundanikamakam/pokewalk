import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/page_data.dart';

class BrowseView extends StatelessWidget {
  final BrowsePageData data;
  final void Function(GameEntry game) onGameTap;

  const BrowseView({super.key, required this.data, required this.onGameTap});

  @override
  Widget build(BuildContext context) {
    if (data.games.isEmpty) {
      return const Center(
        child: Text('No walkthroughs found.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: data.games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _GameCard(
        game: data.games[i],
        onTap: () => onGameTap(data.games[i]),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameEntry game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Box art thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: game.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.catching_pokemon,
                    size: 40,
                    color: Color(0xFF3B5BA5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
