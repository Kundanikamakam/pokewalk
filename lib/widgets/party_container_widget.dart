import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/page_data.dart';

class PartyContainerWidget extends StatelessWidget {
  final PartyContainerData data;
  final void Function(String url) onNavigate;
  final double fontSize;

  const PartyContainerWidget({super.key, required this.data, required this.onNavigate, this.fontSize = 14.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              data.caption,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 13),
            ),
          ),
        ...data.boxes.map((box) => _PartyBoxCard(box: box, onNavigate: onNavigate, fontSize: fontSize)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PartyBoxCard extends StatelessWidget {
  final PartyBoxData box;
  final void Function(String url) onNavigate;
  final double fontSize;
  const _PartyBoxCard({required this.box, required this.onNavigate, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(box.bgColor) ?? const Color(0xFFE1E1E1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _TrainerAvatar(imageUrl: box.trainerImageUrl, bgColor: bgColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (box.trainerClass != null)
                    Text(box.trainerClass!, style: TextStyle(fontSize: fontSize - 3, color: Colors.black54)),
                  Text(
                    box.trainerName,
                    style: TextStyle(fontSize: fontSize + 1, fontWeight: FontWeight.bold),
                  ),
                  if (box.location != null)
                    Text(box.location!, style: TextStyle(fontSize: fontSize - 2, color: Colors.black54)),
                  if (box.reward != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(box.reward!, style: TextStyle(fontSize: fontSize - 2, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
            if (box.pokemon.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.catching_pokemon, size: 16),
                label: Text('Party (${box.pokemon.length})', style: TextStyle(fontSize: fontSize - 3)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showPartyModal(context, box),
              ),
          ],
        ),
      ),
    );
  }

  void _showPartyModal(BuildContext context, PartyBoxData box) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PartyModal(box: box, onNavigate: onNavigate, fontSize: fontSize),
    );
  }

  Color? _parseColor(String cssColor) {
    final m = RegExp(r'#([0-9a-fA-F]{3,6})').firstMatch(cssColor);
    if (m == null) return null;
    try {
      var hex = m.group(1)!;
      if (hex.length == 3) hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _TrainerAvatar extends StatelessWidget {
  final String? imageUrl;
  final Color bgColor;
  const _TrainerAvatar({this.imageUrl, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.6),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Icon(Icons.person, color: Colors.grey),
                errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
              )
            : const Icon(Icons.person, color: Colors.grey),
      ),
    );
  }
}

class _PartyModal extends StatelessWidget {
  final PartyBoxData box;
  final void Function(String url) onNavigate;
  final double fontSize;
  const _PartyModal({required this.box, required this.onNavigate, required this.fontSize});

  static const _typeColors = {
    'Normal': Color(0xFF9FA19F),
    'Fire': Color(0xFFE62829),
    'Water': Color(0xFF2980EF),
    'Grass': Color(0xFF3FA129),
    'Electric': Color(0xFFFAC000),
    'Ice': Color(0xFF3DC6C9),
    'Fighting': Color(0xFF99461B),
    'Poison': Color(0xFF923FCE),
    'Ground': Color(0xFF915122),
    'Flying': Color(0xFF89AAE3),
    'Psychic': Color(0xFFEF4179),
    'Bug': Color(0xFF91A119),
    'Rock': Color(0xFFA38C21),
    'Ghost': Color(0xFF705898),
    'Dragon': Color(0xFF5060E1),
    'Dark': Color(0xFF624D4E),
    'Steel': Color(0xFF60A1B8),
    'Fairy': Color(0xFFEF70EF),
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
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
                const Icon(Icons.catching_pokemon, color: Color(0xFF3B5BA5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${box.trainerName}'s Party (${box.pokemon.length})",
                    style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.all(12),
              itemCount: box.pokemon.length,
              itemBuilder: (context, i) => _PokemonCard(pokemon: box.pokemon[i], typeColors: _typeColors, fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final PartyPokemonData pokemon;
  final Map<String, Color> typeColors;
  final double fontSize;
  const _PokemonCard({required this.pokemon, required this.typeColors, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pokemon.bgColor) ?? const Color(0xFFC1C2C1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: bgColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PokemonAvatar(imageUrl: pokemon.imageUrl, bgColor: bgColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pokemon.name,
                              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (pokemon.level != null)
                            Text(
                              'Lv.${pokemon.level}',
                              style: TextStyle(fontSize: fontSize - 2, color: Colors.black54),
                            ),
                        ],
                      ),
                      if (pokemon.typeNames.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            children: pokemon.typeNames.map((t) => _TypeChip(type: t, color: typeColors[t] ?? const Color(0xFF9FA19F), fontSize: fontSize - 3)).toList(),
                          ),
                        ),
                      if (pokemon.ability != null && pokemon.ability!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Text('Ability: ', style: TextStyle(fontSize: fontSize - 4, color: Colors.black54)),
                              Text(pokemon.ability!, style: TextStyle(fontSize: fontSize - 4, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      if (pokemon.heldItem != null && pokemon.heldItem!.isNotEmpty)
                        Row(
                          children: [
                            Text('Item: ', style: TextStyle(fontSize: fontSize - 4, color: Colors.black54)),
                            Text(pokemon.heldItem!, style: TextStyle(fontSize: fontSize - 4, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (pokemon.moveNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _MovesGrid(moves: pokemon.moveNames, fontSize: fontSize - 3),
              ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String cssColor) {
    final m = RegExp(r'#([0-9a-fA-F]{3,6})').firstMatch(cssColor);
    if (m == null) return null;
    try {
      var hex = m.group(1)!;
      if (hex.length == 3) hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _PokemonAvatar extends StatelessWidget {
  final String? imageUrl;
  final Color bgColor;
  const _PokemonAvatar({this.imageUrl, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.5),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Icon(Icons.catching_pokemon, color: Colors.grey, size: 32),
                errorWidget: (_, __, ___) => const Icon(Icons.catching_pokemon, color: Colors.grey, size: 32),
              )
            : const Icon(Icons.catching_pokemon, color: Colors.grey, size: 32),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  final Color color;
  final double fontSize;
  const _TypeChip({required this.type, required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type,
        style: TextStyle(fontSize: fontSize - 4, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MovesGrid extends StatelessWidget {
  final List<String> moves;
  final double fontSize;
  const _MovesGrid({required this.moves, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: moves.map((move) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(move, style: TextStyle(fontSize: fontSize)),
      )).toList(),
    );
  }
}

