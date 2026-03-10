import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/page_data.dart';

// ── Entry point widget (the tappable card in the chapter page) ────────────────

class ExpandableSectionWidget extends StatelessWidget {
  final ExpandableSectionData data;
  final void Function(String url) onNavigate;
  const ExpandableSectionWidget({super.key, required this.data, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showModal(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(_icon, color: _color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _color)),
                    Text(_subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    return switch (data) {
      TrainersExpandableData d => '${d.trainers.length} trainer${d.trainers.length == 1 ? '' : 's'}',
      AvailablePokemonExpandableData d => '${d.pokemon.length} Pokémon',
      ItemsExpandableData d => '${d.items.length} item${d.items.length == 1 ? '' : 's'}',
      GenericExpandableData _ => 'Tap to expand',
    };
  }

  Color get _color {
    if (data.title.toLowerCase().contains('trainer')) return const Color(0xFF388E3C);
    if (data.title.toLowerCase().contains('available') || data.title.toLowerCase().contains('pokémon')) return const Color(0xFF1976D2);
    if (data.title.toLowerCase().contains('item')) return const Color(0xFFE65100);
    return const Color(0xFF3B5BA5);
  }

  IconData get _icon {
    if (data.title.toLowerCase().contains('trainer')) return Icons.sports_kabaddi;
    if (data.title.toLowerCase().contains('available')) return Icons.catching_pokemon;
    if (data.title.toLowerCase().contains('item')) return Icons.inventory_2;
    return Icons.info_outline;
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SectionModal(data: data, color: _color, icon: _icon, onNavigate: onNavigate),
    );
  }
}

// ── Modal shell ───────────────────────────────────────────────────────────────

class _SectionModal extends StatelessWidget {
  final ExpandableSectionData data;
  final Color color;
  final IconData icon;
  final void Function(String url) onNavigate;
  const _SectionModal({required this.data, required this.color, required this.icon, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(data.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildContent(controller)),
        ],
      ),
    );
  }

  Widget _buildContent(ScrollController controller) {
    return switch (data) {
      TrainersExpandableData d => _TrainersView(trainers: d.trainers, controller: controller, themeColor: color),
      AvailablePokemonExpandableData d => _AvailablePokemonView(pokemon: d.pokemon, controller: controller, themeColor: color),
      ItemsExpandableData d => _ItemsView(items: d.items, controller: controller, themeColor: color),
      GenericExpandableData d => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: Text(d.contentHtml, style: const TextStyle(fontSize: 13)),
        ),
    };
  }
}

// ── Trainers view ─────────────────────────────────────────────────────────────

class _TrainersView extends StatelessWidget {
  final List<TrainerEntry> trainers;
  final ScrollController controller;
  final Color themeColor;
  const _TrainersView({required this.trainers, required this.controller, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    if (trainers.isEmpty) {
      return const Center(child: Text('No trainers found', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(12),
      itemCount: trainers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TrainerCard(trainer: trainers[i], themeColor: themeColor),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final TrainerEntry trainer;
  final Color themeColor;
  const _TrainerCard({required this.trainer, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: themeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trainer.imageUrl != null)
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: trainer.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.sports_kabaddi, size: 32),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (trainer.reward != null)
                        Text(
                          'Reward: \$${trainer.reward}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (trainer.pokemon.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: trainer.pokemon.map((p) => _PokemonChip(pokemon: p)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PokemonChip extends StatelessWidget {
  final TrainerPokemonEntry pokemon;
  const _PokemonChip({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pokemon.imageUrl != null)
            CachedNetworkImage(
              imageUrl: pokemon.imageUrl!,
              width: 24,
              height: 24,
              errorWidget: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 16),
            ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(pokemon.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              Text('Lv.${pokemon.level}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              if (pokemon.heldItem != null)
                Text(pokemon.heldItem!, style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Available Pokémon view ────────────────────────────────────────────────────

class _AvailablePokemonView extends StatelessWidget {
  final List<AvailablePokemonEntry> pokemon;
  final ScrollController controller;
  final Color themeColor;
  const _AvailablePokemonView({required this.pokemon, required this.controller, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    if (pokemon.isEmpty) {
      return const Center(child: Text('No Pokémon data found', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: pokemon.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 52),
      itemBuilder: (_, i) => _PokemonRow(entry: pokemon[i], themeColor: themeColor),
    );
  }
}

class _PokemonRow extends StatelessWidget {
  final AvailablePokemonEntry entry;
  final Color themeColor;
  const _PokemonRow({required this.entry, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor.withValues(alpha: 0.1),
              border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: entry.imageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: entry.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Icon(Icons.catching_pokemon, color: themeColor, size: 20),
                    ),
                  )
                : Icon(Icons.catching_pokemon, color: themeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (entry.levelRange != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lv.${entry.levelRange}',
                          style: TextStyle(fontSize: 10, color: themeColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.location != null && entry.location!.isNotEmpty)
                  Text(
                    entry.location!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Items view ────────────────────────────────────────────────────────────────

class _ItemsView extends StatelessWidget {
  final List<ItemEntry> items;
  final ScrollController controller;
  final Color themeColor;
  const _ItemsView({required this.items, required this.controller, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 44),
      itemBuilder: (_, i) => _ItemRow(item: items[i], themeColor: themeColor),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ItemEntry item;
  final Color themeColor;
  const _ItemRow({required this.item, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Icon(Icons.inventory_2, color: themeColor, size: 18),
                  )
                : Icon(Icons.inventory_2, color: themeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (item.location.isNotEmpty)
                  Text(item.location, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
