import 'package:html/dom.dart' as dom;

/// Rewrites Bulbapedia HTML to be safe for flutter_html rendering.
/// Focuses on fixing dark-gradient tables, white-text issues, and cleaning
/// up elements that don't render well in a native Flutter context.
class ChapterPreprocessor {
  String process(dom.Element content) {
    _fixAllTables(content);
    _fixSpanColors(content);
    _removeProblematicElements(content);
    _unwrapCollapsibleSections(content);
    return content.outerHtml;
  }

  // ── Tables ──────────────────────────────────────────────────────────────────

  void _fixAllTables(dom.Element content) {
    for (final table in content.querySelectorAll('table')) {
      final style = table.attributes['style'] ?? '';
      final hasDarkBg = _isDark(style);

      if (hasDarkBg) {
        // Replace gradient/dark background on the table with light
        table.attributes['style'] =
            _replaceBg(style, 'background:#f0f4ff;border-radius:8px;');
      }

      // Fix all th cells
      for (final th in table.querySelectorAll('th')) {
        final s = th.attributes['style'] ?? '';
        // Give th a solid primary colour + white text regardless
        final cleaned = _stripBgAndColor(s);
        th.attributes['style'] =
            'background:#3B5BA5;color:#fff;padding:4px 6px;$cleaned';
      }

      // Fix all td cells
      for (final td in table.querySelectorAll('td')) {
        final s = td.attributes['style'] ?? '';
        final hasDarkBgTd = _isDark(s);
        var newStyle = hasDarkBgTd ? _replaceBg(s, 'background:#fff;') : s;
        // Remove white/light text colours
        newStyle = _removeWhiteColor(newStyle);
        td.attributes['style'] = newStyle;
      }
    }
  }

  // ── Inline span colours ─────────────────────────────────────────────────────

  void _fixSpanColors(dom.Element content) {
    for (final el in content.querySelectorAll('[style]')) {
      final s = el.attributes['style'] ?? '';
      if (_isWhiteishColor(s) && !_isDark(s)) {
        // Strip white/near-white text colour if no dark background on same el
        el.attributes['style'] = _removeWhiteColor(s);
      }
    }
  }

  // ── Remove noise ─────────────────────────────────────────────────────────────

  void _removeProblematicElements(dom.Element content) {
    for (final sel in [
      '.mw-editsection',
      '.noprint',
      '#catlinks',
      '.printfooter',
      '[role="navigation"]',
      '.navbox',
      '.sister-wiki',
    ]) {
      for (final el in content.querySelectorAll(sel)) {
        el.remove();
      }
    }
  }

  // ── Unwrap collapsed mobile sections ─────────────────────────────────────────

  void _unwrapCollapsibleSections(dom.Element content) {
    // Mobile Minerva wraps content in <section class="mf-section-N">
    // These are fine structurally, just make sure they're all visible
    for (final section in content.querySelectorAll('section')) {
      section.attributes.remove('style');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static final _gradientRe = RegExp(
      r'background(?:-color)?\s*:\s*linear-gradient\([^;]+\)',
      caseSensitive: false);
  static final _darkColorRe = RegExp(
      r'background(?:-color)?\s*:\s*#(?:[0-3][0-9a-fA-F]{5}|[0-3][0-9a-fA-F]{2})\b',
      caseSensitive: false);
  static final _rgbaDarkRe = RegExp(
      r'background(?:-color)?\s*:\s*rgba\(\s*0\s*,\s*0\s*,\s*0\s*,[^)]+\)',
      caseSensitive: false);
  static final _anyBgRe = RegExp(
      r'background(?:-color)?\s*:[^;]+;?',
      caseSensitive: false);
  static final _whiteColorRe = RegExp(
      r'color\s*:\s*(?:#[Ff]{3,6}|white|rgba\(\s*25[0-5]\s*,\s*25[0-5]\s*,\s*25[0-5][^)]*\))\s*;?',
      caseSensitive: false);

  bool _isDark(String style) =>
      _gradientRe.hasMatch(style) ||
      _darkColorRe.hasMatch(style) ||
      _rgbaDarkRe.hasMatch(style);

  bool _isWhiteishColor(String style) => _whiteColorRe.hasMatch(style);

  String _replaceBg(String style, String replacement) =>
      _anyBgRe.hasMatch(style)
          ? style.replaceAll(_anyBgRe, replacement)
          : '$replacement $style';

  String _stripBgAndColor(String style) => style
      .replaceAll(_anyBgRe, '')
      .replaceAll(_whiteColorRe, '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  String _removeWhiteColor(String style) =>
      style.replaceAll(_whiteColorRe, '');
}
