import 'package:flutter/material.dart';
import '../models/page_data.dart';

/// Native prev/next chapter navigation bar extracted from the chapter nav div.
class ChapterNavWidget extends StatelessWidget {
  final ChapterNav nav;
  final void Function(String url) onNavigate;

  const ChapterNavWidget({
    super.key,
    required this.nav,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _parseGradientColor(nav.gradientCss) ??
        Theme.of(context).colorScheme.secondaryContainer;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Previous
          if (nav.prevUrl != null) ...[
            Expanded(
              child: _NavButton(
                label: nav.prevLabel ?? 'Prev',
                icon: Icons.chevron_left,
                iconLeft: true,
                fgColor: fg,
                onTap: () => onNavigate(nav.prevUrl!),
              ),
            ),
          ] else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(width: 4),

          // Next
          if (nav.nextUrl != null) ...[
            Expanded(
              child: _NavButton(
                label: nav.nextLabel ?? 'Next',
                icon: Icons.chevron_right,
                iconLeft: false,
                fgColor: fg,
                onTap: () => onNavigate(nav.nextUrl!),
              ),
            ),
          ] else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  /// Extracts the first prominent color from a linear-gradient CSS string.
  Color? _parseGradientColor(String gradient) {
    if (gradient.isEmpty) return null;
    final hexMatches = RegExp(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})')
        .allMatches(gradient)
        .toList();
    if (hexMatches.isEmpty) return null;
    try {
      final raw = hexMatches.first.group(1)!;
      final hex = raw.length == 3
          ? '${raw[0]}${raw[0]}${raw[1]}${raw[1]}${raw[2]}${raw[2]}'
          : raw;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconLeft;
  final Color fgColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.iconLeft,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          iconLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (iconLeft) Icon(icon, size: 18, color: fgColor),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!iconLeft) Icon(icon, size: 18, color: fgColor),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: content,
      ),
    );
  }
}
