import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import '../../models/page_data.dart';

/// Result of preprocessing a chapter page's HTML.
class ProcessedChapter {
  final String html;
  final ChapterNav? nav;
  final List<PartyContainerData> partyContainers;
  final List<ExpandableSectionData> expandableSections;
  ProcessedChapter({
    required this.html,
    this.nav,
    this.partyContainers = const [],
    this.expandableSections = const [],
  });
}

/// Rewrites Bulbapedia HTML to be safe for flutter_html rendering.
class ChapterPreprocessor {
  ProcessedChapter process(dom.Element content) {
    final nav = _extractChapterNav(content);
    _removeProblematicElements(content);
    _fixAllTables(content);
    _stripUnsupportedCss(content);
    _fixSpanColors(content);
    final expandableSections = _extractExpandableSections(content);
    final partyContainers = _extractPartyContainers(content);
    _unwrapCollapsibleSections(content);
    return ProcessedChapter(
      html: content.outerHtml,
      nav: nav,
      partyContainers: partyContainers,
      expandableSections: expandableSections,
    );
  }

  // ── Chapter navigation extraction ────────────────────────────────────────────

  /// Finds the grid-based chapter nav div, extracts prev/next links, removes it.
  ChapterNav? _extractChapterNav(dom.Element content) {
    // The nav div always has both linear-gradient AND grid-template-columns:1fr 1fr 1fr
    for (final div in content.querySelectorAll('div[style]')) {
      final style = div.attributes['style'] ?? '';
      if (!style.contains('linear-gradient')) continue;
      if (!style.contains('1fr 1fr 1fr')) continue;

      final gradient = _extractGradient(style);
      final children = div.children;
      if (children.length < 2) continue;

      // Left child = prev, right child = next, middle = current (ignored)
      final prevLink = _extractNavLink(children.first);
      final nextLink = children.length >= 3
          ? _extractNavLink(children.last)
          : null;

      div.remove();
      return ChapterNav(
        prevUrl: prevLink?.$1,
        prevLabel: prevLink?.$2,
        nextUrl: nextLink?.$1,
        nextLabel: nextLink?.$2,
        gradientCss: gradient,
      );
    }
    return null;
  }

  /// Returns (href, displayLabel) from the first wiki link inside an element.
  (String, String)? _extractNavLink(dom.Element el) {
    // Look for an <a> containing a plain part label like "Part 1"
    // Prefer the one whose text is NOT just "←" or "→"
    for (final a in el.querySelectorAll('a[href]')) {
      final text = a.text.trim();
      if (text == '←' || text == '→' || text.isEmpty) continue;
      final href = a.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      // Strip protocol-relative or mobile prefix to store canonical href
      return (href, text);
    }
    return null;
  }

  String _extractGradient(String style) {
    final m = RegExp(r'linear-gradient\([^;)]+\)', caseSensitive: false)
        .firstMatch(style);
    return m?.group(0) ?? '';
  }

  // ── Tables ──────────────────────────────────────────────────────────────────

  void _fixAllTables(dom.Element content) {
    for (final table in content.querySelectorAll('table')) {
      table.attributes.remove('width');
      table.attributes.remove('border');
      table.attributes.remove('cellpadding');
      table.attributes.remove('cellspacing');
      table.attributes.remove('align');

      final tableStyle = table.attributes['style'] ?? '';
      var newStyle = _safeTableStyle(tableStyle, isTable: true);
      if (!newStyle.contains('width:')) newStyle += 'width:100%;';
      table.attributes['style'] = newStyle;

      for (final th in table.querySelectorAll('th')) {
        th.attributes['style'] =
            'background:#3B5BA5;color:#fff;padding:4px 6px;';
        th.attributes.remove('width');
        th.attributes.remove('bgcolor');
      }

      for (final td in table.querySelectorAll('td')) {
        final s = td.attributes['style'] ?? '';
        td.attributes['style'] = _safeTableStyle(s, isTable: false);
        td.attributes.remove('width');
        td.attributes.remove('bgcolor');

        // Strip inline styles from all styled descendants inside td — they
        // become WidgetSpans in RichText and can trigger negative-width crashes.
        for (final span in td.querySelectorAll('[style]')) {
          span.attributes.remove('style');
        }
      }
    }
  }

  // ── Strip CSS that flutter_html cannot handle ─────────────────────────────

  /// Removes `display:grid`, `display:flex`, `grid-template-columns`, etc. from
  /// ALL element inline styles. These cause flutter_html layout crashes.
  void _stripUnsupportedCss(dom.Element content) {
    for (final el in content.querySelectorAll('[style]')) {
      var s = el.attributes['style'] ?? '';
      if (s.isEmpty) continue;

      // Replace grid/flex display with block
      s = s.replaceAllMapped(
        RegExp(r'display\s*:\s*(grid|flex|inline-grid|inline-flex)\s*;?',
            caseSensitive: false),
        (_) => 'display:block;',
      );

      // Remove grid & flex layout properties
      for (final prop in [
        r'grid-template-columns',
        r'grid-template-rows',
        r'grid-template',
        r'grid-column',
        r'grid-row',
        r'grid-area',
        r'gap',
        r'row-gap',
        r'column-gap',
        r'justify-content',
        r'justify-items',
        r'justify-self',
        r'align-items',
        r'align-content',
        r'align-self',
        r'flex-direction',
        r'flex-wrap',
        r'flex-flow',
        r'flex',
        r'flex-grow',
        r'flex-shrink',
        r'flex-basis',
        r'order',
        r'box-sizing',
        r'width\s*:\s*fit-content',
        r'min-width\s*:\s*fit-content',
        r'max-width\s*:\s*fit-content',
        r'white-space',
        r'position\s*:\s*(absolute|fixed|sticky)',
        r'top\s*:',
        r'bottom\s*:',
        r'left\s*:',
        r'right\s*:',
        r'overflow\s*:',
        r'transform\s*:',
        r'transition\s*:',
      ]) {
        s = s.replaceAll(
            RegExp('$prop[^;]*;?', caseSensitive: false), '');
      }

      // Remove width:Xpx if it might be narrow (< 100)
      s = s.replaceAllMapped(
        RegExp(r'width\s*:\s*(\d+)px\s*;?', caseSensitive: false),
        (m) {
          final px = int.tryParse(m.group(1) ?? '0') ?? 0;
          return px < 150 ? '' : '${m.group(0)}';
        },
      );

      el.attributes['style'] = s.trim();
      if (el.attributes['style']!.isEmpty) {
        el.attributes.remove('style');
      }
    }

    // Also remove width/height HTML attrs that force narrow layouts
    for (final el in content.querySelectorAll('[width]')) {
      final w = int.tryParse(el.attributes['width'] ?? '') ?? 0;
      if (w > 0 && w < 150) el.attributes.remove('width');
    }
  }

  // ── Inline span colours ─────────────────────────────────────────────────────

  void _fixSpanColors(dom.Element content) {
    for (final el in content.querySelectorAll('[style]')) {
      final s = el.attributes['style'] ?? '';
      if (_isWhiteishColor(s) && !_isDark(s)) {
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
      'script',
      'style',
      'hr', // renders as blank line gap in flutter_html
    ]) {
      for (final el in content.querySelectorAll(sel).toList()) {
        el.remove();
      }
    }
    // Unwrap <center> — keep text content but remove the centering wrapper
    for (final el in content.querySelectorAll('center').toList()) {
      for (final child in el.nodes.toList()) {
        el.parentNode?.insertBefore(child, el);
      }
      el.remove();
    }
    // Remove empty block-level divs (e.g. <div style="margin-bottom:1em"></div>)
    // Only remove divs with NO children at all and no text — never remove image containers.
    for (final el in content.querySelectorAll('div').toList()) {
      if (el.nodes.isEmpty) el.remove();
    }
  }

  // ── Party containers ──────────────────────────────────────────────────────────

  List<PartyContainerData> _extractPartyContainers(dom.Element content) {
    final result = <PartyContainerData>[];
    int idx = 0;

    for (final pc in content.querySelectorAll('.partycontainer').toList()) {
      final captionEl = pc.querySelector('.partycaption');
      final caption = captionEl?.text.trim() ?? '';

      final boxes = <PartyBoxData>[];
      for (final box in pc.querySelectorAll('.partybox').toList()) {
        final trainerImg = box.querySelector('.partyimage img');
        final trainerImageUrl = trainerImg?.attributes['src'];

        final partyNameEl = box.querySelector('.partyname');
        final trainerName = partyNameEl?.text.trim() ?? '';

        String? trainerClass;
        for (final classEl in box.querySelectorAll('.partyclass')) {
          final s = classEl.attributes['style'] ?? '';
          if (!s.contains('none')) {
            final text = classEl.text.trim();
            if (text.isNotEmpty) {
              trainerClass = text;
              break;
            }
          }
        }

        final location = box.querySelector('.partylocation')?.text.trim();
        final reward = box.querySelector('.partyreward')?.text.trim();

        final boxStyle = box.attributes['style'] ?? '';
        final bgMatch = RegExp(r'background:\s*([^;]+)').firstMatch(boxStyle);
        final bgColor = bgMatch?.group(1)?.trim() ?? '#E1E1E1';

        final pokemonEl = box.querySelector('.mw-collapsible-content');
        final pokemon = pokemonEl != null ? _parsePokemonEntries(pokemonEl) : <PartyPokemonData>[];

        if (trainerName.isNotEmpty) {
          boxes.add(PartyBoxData(
            trainerName: trainerName,
            trainerClass: trainerClass,
            trainerImageUrl: trainerImageUrl,
            location: location,
            reward: reward,
            bgColor: bgColor,
            pokemon: pokemon,
          ));
        }
      }

      if (boxes.isNotEmpty) {
        result.add(PartyContainerData(caption: caption, boxes: boxes));
      }

      final replacement = dom.Element.tag('partycontainer');
      replacement.attributes['data-idx'] = '$idx';
      pc.replaceWith(replacement);
      idx++;
    }

    return result;
  }

  // ── Expandable sections ───────────────────────────────────────────────────────

  List<ExpandableSectionData> _extractExpandableSections(dom.Element content) {
    final result = <ExpandableSectionData>[];
    int idx = 0;

    for (final table in content.querySelectorAll('table.expandable').toList()) {
      final th = table.querySelector('th');
      final title = th?.text.trim() ?? 'Details';

      ExpandableSectionData section;
      final titleLower = title.toLowerCase();
      if (titleLower.contains('trainer')) {
        section = TrainersExpandableData(title, _parseTrainers(table));
      } else if (titleLower.contains('available') ||
          titleLower.contains('pokémon') ||
          titleLower.contains('pokemon')) {
        section = AvailablePokemonExpandableData(title, _parseAvailablePokemon(table));
      } else if (titleLower.contains('item')) {
        section = ItemsExpandableData(title, _parseItems(table));
      } else {
        final contentParts = <String>[];
        for (final tr in table.querySelectorAll('tr')) {
          final tds = tr.querySelectorAll('td');
          if (tds.isEmpty) continue;
          for (final td in tds) { contentParts.add(td.innerHtml); }
        }
        section = GenericExpandableData(title, contentParts.join(''));
      }

      if (section is! GenericExpandableData || section.contentHtml.trim().isNotEmpty) {
        result.add(section);
      }

      final replacement = dom.Element.tag('expandablesection');
      replacement.attributes['data-idx'] = '$idx';
      table.replaceWith(replacement);
      idx++;
    }

    return result;
  }

  List<TrainerEntry> _parseTrainers(dom.Element expandableTable) {
    final result = <TrainerEntry>[];

    // Get direct tbody/tr children to avoid descending into nested tables
    final tbody = expandableTable.children
        .whereType<dom.Element>()
        .where((e) => e.localName == 'tbody')
        .toList();
    final topRows = tbody.isNotEmpty
        ? tbody.first.children.whereType<dom.Element>().where((e) => e.localName == 'tr').toList()
        : expandableTable.children.whereType<dom.Element>().where((e) => e.localName == 'tr').toList();

    for (final outerRow in topRows) {
      final outerTds = outerRow.children.whereType<dom.Element>().where((e) => e.localName == 'td').toList();
      for (final outerTd in outerTds) {
        // Find roundy table directly inside this td
        final roundyMatches = outerTd.children.whereType<dom.Element>()
            .where((e) => e.localName == 'table' && (e.attributes['class'] ?? '').contains('roundy'))
            .toList();
        if (roundyMatches.isEmpty) continue;
        final roundy = roundyMatches.first;

        final roundyTbody = roundy.children.whereType<dom.Element>()
            .where((e) => e.localName == 'tbody')
            .toList();
        final roundyRows = roundyTbody.isNotEmpty
            ? roundyTbody.first.children.whereType<dom.Element>().where((e) => e.localName == 'tr').toList()
            : roundy.children.whereType<dom.Element>().where((e) => e.localName == 'tr').toList();

        for (final tr in roundyRows) {
          final tds = tr.children.whereType<dom.Element>().where((e) => e.localName == 'td').toList();
          if (tds.length < 2) continue;

          final trainerTd = tds[0];
          final pokemonTd = tds[1];

          final trainerImg = trainerTd.querySelector('img');
          final trainerImageUrl = trainerImg?.attributes['src'];

          final boldEl = trainerTd.querySelector('b');
          final classLink = boldEl?.querySelector('a');
          final trainerClass = classLink?.text.trim();
          final fullName = boldEl?.text.trim() ?? '';
          if (fullName.isEmpty) continue;

          final fullText = trainerTd.text;
          final rewardMatch = RegExp(r'Reward:.*?(\d[\d,]+)').firstMatch(fullText);
          final reward = rewardMatch?.group(1);

          final pokemon = <TrainerPokemonEntry>[];
          final innerTable = pokemonTd.querySelector('table');
          if (innerTable != null) {
            final innerTbodyMatches = innerTable.children.whereType<dom.Element>()
                .where((e) => e.localName == 'tbody').toList();
            final innerTbody = innerTbodyMatches.isNotEmpty ? innerTbodyMatches.first : innerTable;
            final innerRows = innerTbody.children.whereType<dom.Element>()
                .where((e) => e.localName == 'tr').toList();
            int i = 0;
            while (i < innerRows.length) {
              final mainRow = innerRows[i];
              final mainCells = mainRow.children.whereType<dom.Element>()
                  .where((e) => e.localName == 'td').toList();
              if (mainCells.length >= 2) {
                final pkmImg = mainCells[0].querySelector('img');
                final pkmImageUrl = pkmImg?.attributes['src'];
                final pkmName = mainCells[1].querySelector('a')?.text.trim() ?? '';
                final levelText = mainCells.length > 2 ? mainCells[2].text.trim() : '';
                final levelMatch = RegExp(r'\d+').firstMatch(levelText);
                final level = levelMatch?.group(0) ?? '';

                String? heldItem;
                if (i + 1 < innerRows.length) {
                  final itemText = innerRows[i + 1].text.trim().replaceAll(RegExp(r'\s+'), ' ');
                  if (itemText.isNotEmpty && itemText.toLowerCase() != 'no item') {
                    heldItem = itemText;
                  }
                  i += 2;
                } else {
                  i++;
                }

                if (pkmName.isNotEmpty) {
                  pokemon.add(TrainerPokemonEntry(
                    name: pkmName,
                    imageUrl: pkmImageUrl,
                    level: level,
                    heldItem: heldItem,
                  ));
                }
              } else {
                i++;
              }
            }
          }

          result.add(TrainerEntry(
            name: fullName,
            trainerClass: trainerClass,
            imageUrl: trainerImageUrl,
            reward: reward,
            pokemon: pokemon,
          ));
        }
      }
    }

    return result;
  }

  List<AvailablePokemonEntry> _parseAvailablePokemon(dom.Element expandableTable) {
    final result = <AvailablePokemonEntry>[];
    final roundyTables = expandableTable.querySelectorAll('table.roundy');

    for (final roundy in roundyTables) {
      final tbodyMatches = roundy.children.whereType<dom.Element>()
          .where((e) => e.localName == 'tbody').toList();
      final tbody = tbodyMatches.isNotEmpty ? tbodyMatches.first : roundy;
      final rows = tbody.children.whereType<dom.Element>()
          .where((e) => e.localName == 'tr').toList();

      int locationCol = -1;
      int levelCol = -1;
      int headerRowCount = 0;
      for (final row in rows) {
        final ths = row.children.whereType<dom.Element>().where((e) => e.localName == 'th').toList();
        final tds = row.children.whereType<dom.Element>().where((e) => e.localName == 'td').toList();
        // A true header row has only <th> elements (no <td>).
        // Data rows may mix <th> (game version markers) and <td>, so stop there.
        if (ths.isEmpty || tds.isNotEmpty) break;
        headerRowCount++;
        // Scan only the first header row for column positions.
        // Account for colspan so the computed index matches actual td positions in data rows.
        if (headerRowCount == 1) {
          int colOffset = 0;
          for (final th in ths) {
            final text = th.text.trim().toLowerCase();
            final colspan = int.tryParse(th.attributes['colspan'] ?? '1') ?? 1;
            if (text == 'location' || text == 'locations') locationCol = colOffset;
            if (text == 'levels' || text == 'level') levelCol = colOffset;
            colOffset += colspan;
          }
        }
      }

      for (final row in rows.skip(headerRowCount)) {
        final tds = row.children.whereType<dom.Element>()
            .where((e) => e.localName == 'td').toList();
        if (tds.isEmpty) continue;

        final pkmTd = tds[0];
        // Real pokemon cells have a nested roundy table for the icon circle.
        // Legend/note rows only have a plain td — skip them.
        if (pkmTd.querySelector('table') == null) continue;
        final pkmImg = pkmTd.querySelector('img');
        final pkmImageUrl = pkmImg?.attributes['src'];
        // Skip File: / image links; find the actual Pokémon article link.
        final pkmLink = pkmTd.querySelectorAll('a').where((a) {
          final href = a.attributes['href'] ?? '';
          return !href.toLowerCase().contains('file:') &&
              !href.toLowerCase().contains('special:') &&
              a.text.trim().isNotEmpty;
        }).firstOrNull;
        final pkmName = pkmLink?.text.trim() ?? '';
        if (pkmName.isEmpty) continue;

        String? location;
        String? levelRange;
        String? rate;

        if (tds.length > 2) {
          if (locationCol >= 0 && locationCol < tds.length) {
            location = tds[locationCol].text.trim();
          } else if (tds.length > 8) {
            location = tds[7].text.trim();
          } else if (tds.length > 2) {
            location = tds[tds.length - 3].text.trim();
          }

          if (levelCol >= 0 && levelCol < tds.length) {
            levelRange = tds[levelCol].text.trim();
          } else if (tds.length > 9) {
            levelRange = tds[8].text.trim();
          } else if (tds.length > 1) {
            levelRange = tds[tds.length - 2].text.trim();
          }

          // Rate is always the last td
          final rateTd = tds[tds.length - 1].text.trim();
          if (rateTd.contains('%')) rate = rateTd;
        }

        if (location?.isEmpty == true) location = null;
        if (levelRange?.isEmpty == true) levelRange = null;
        if (levelRange != null && levelRange.contains('%')) levelRange = null;

        result.add(AvailablePokemonEntry(
          name: pkmName,
          imageUrl: pkmImageUrl,
          location: location,
          levelRange: levelRange,
          rate: rate,
        ));
      }
    }

    final seen = <String>{};
    return result.where((e) => seen.add(e.name)).toList();
  }

  List<ItemEntry> _parseItems(dom.Element expandableTable) {
    final result = <ItemEntry>[];

    for (final roundy in expandableTable.querySelectorAll('table.roundy')) {
      final tbodyMatches = roundy.children.whereType<dom.Element>()
          .where((e) => e.localName == 'tbody').toList();
      final tbody = tbodyMatches.isNotEmpty ? tbodyMatches.first : roundy;

      for (final tr in tbody.children.whereType<dom.Element>().where((e) => e.localName == 'tr')) {
        final tds = tr.children.whereType<dom.Element>().where((e) => e.localName == 'td').toList();
        final ths = tr.children.whereType<dom.Element>().where((e) => e.localName == 'th').toList();
        if (ths.isNotEmpty || tds.length < 2) continue;

        final itemImg = tds[0].querySelector('img');
        final imageUrl = itemImg?.attributes['src'];

        final itemName = tds[1].querySelector('a')?.text.trim() ?? tds[1].text.trim();
        if (itemName.isEmpty) continue;

        final location = tds.length > 2 ? tds[2].text.trim() : '';

        result.add(ItemEntry(
          name: itemName,
          imageUrl: imageUrl,
          location: location,
        ));
      }
    }

    return result;
  }

  List<PartyPokemonData> _parsePokemonEntries(dom.Element container) {
    final result = <PartyPokemonData>[];
    for (final pkmBox in container.querySelectorAll('.PKMNbox')) {
      final nameEl = pkmBox.querySelector('.PKMNnamebox');
      final nameLink = nameEl?.querySelector('b a') ?? nameEl?.querySelector('b');
      final name = nameLink?.text.trim() ??
          nameEl?.text
              .replaceAll(RegExp(r'[♀♂]'), '')
              .replaceAll(RegExp(r'Lv\.\s*\d+'), '')
              .trim() ??
          '';
      if (name.isEmpty) continue;

      final artImg = pkmBox.querySelector('.PKMNartbox img');
      final imageUrl = artImg?.attributes['src'];

      final levelText = pkmBox.querySelector('.PKMNlevel')?.text.trim() ?? '';
      final levelMatch = RegExp(r'\d+').firstMatch(levelText);
      final level = levelMatch?.group(0);

      final typeNames = pkmBox
          .querySelectorAll('.PKMNtypebox')
          .where((e) {
            final classes = e.attributes['class'] ?? '';
            final text = e.text.trim();
            return !classes.contains('PKMNnone') && text.isNotEmpty;
          })
          .map((e) => e.text.trim())
          .toList();

      final moveNames = pkmBox
          .querySelectorAll('.PKMNmovename')
          .map((e) => e.querySelector('a')?.text.trim() ?? e.text.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      final boxStyle = pkmBox.attributes['style'] ?? '';
      final bgMatch =
          RegExp(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b').firstMatch(boxStyle);
      final bgColor = bgMatch?.group(0) ?? '#C1C2C1';

      final abilityEl = pkmBox.querySelector('.PKMNability');
      final abilityRaw =
          (abilityEl?.querySelector('b a') ?? abilityEl?.querySelector('b'))?.text.trim();
      final ability = (abilityRaw == null || abilityRaw.isEmpty) ? null : abilityRaw;

      final heldEl = pkmBox.querySelector('.PKMNheld');
      final heldRaw = heldEl?.querySelector('b')?.text.trim() ?? '';
      final heldItem =
          (heldRaw.isEmpty || heldRaw.toLowerCase() == 'none') ? null : heldRaw;

      result.add(PartyPokemonData(
        name: name,
        imageUrl: imageUrl,
        level: level,
        typeNames: typeNames,
        moveNames: moveNames,
        bgColor: bgColor,
        ability: ability,
        heldItem: heldItem,
      ));
    }
    return result;
  }

  // ── Unwrap collapsed mobile sections ─────────────────────────────────────────

  void _unwrapCollapsibleSections(dom.Element content) {
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
  static final _bgColorRe = RegExp(
      r'background(?:-color)?\s*:[^;]+;?',
      caseSensitive: false);
  static final _whiteColorRe = RegExp(
      r'(?<![a-z-])color\s*:\s*(?:#[Ff]{3,6}|white|rgba\(\s*25[0-5]\s*,\s*25[0-5]\s*,\s*25[0-5][^)]*\))\s*;?',
      caseSensitive: false);

  bool _isDark(String style) =>
      _gradientRe.hasMatch(style) ||
      _darkColorRe.hasMatch(style) ||
      _rgbaDarkRe.hasMatch(style);

  bool _isWhiteishColor(String style) => _whiteColorRe.hasMatch(style);

  /// Strips dangerous CSS properties from a table/td/th style string.
  String _safeTableStyle(String style, {required bool isTable}) {
    String bg = '';
    final bgMatch = _bgColorRe.firstMatch(style);
    if (bgMatch != null) {
      final raw = bgMatch.group(0)!;
      if (!_isDark(raw)) bg = raw.endsWith(';') ? raw : '$raw;';
    }
    if (_isDark(style)) bg = 'background:#f8f8f8;';

    final textColor = _isWhiteishColor(style) ? '' : _extractColor(style);

    final parts = <String>[];
    if (isTable) parts.add('border-collapse:collapse;');
    if (bg.isNotEmpty) parts.add(bg);
    if (textColor.isNotEmpty) parts.add(textColor);
    return parts.join('');
  }

  String _extractColor(String style) {
    final m = RegExp(r'(?<![a-z-])color\s*:[^;]+;?', caseSensitive: false)
        .firstMatch(style);
    if (m == null) return '';
    final raw = m.group(0)!;
    return raw.endsWith(';') ? raw : '$raw;';
  }

  String _removeWhiteColor(String style) =>
      style.replaceAll(_whiteColorRe, '');
}
