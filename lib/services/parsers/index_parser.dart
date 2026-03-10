import 'package:html/dom.dart' as dom;
import '../../models/page_data.dart';

class IndexParser {
  IndexPageData parse(dom.Element content, String pageTitle) {
    // Try to find the contents table (.roundy with chapter links)
    final sections = _parseSections(content);

    // Grab the first game image from the infobox if available
    final gameImageUrl = _extractGameImage(content);

    return IndexPageData(
      gameTitle: pageTitle,
      gameImageUrl: gameImageUrl,
      sections: sections.isNotEmpty
          ? sections
          : [_fallbackSection(content)],
    );
  }

  List<WalkthroughSection> _parseSections(dom.Element content) {
    // The contents table is a .roundy table or a table with Walkthrough links
    // Strategy: iterate all tables, find the one with walkthrough part links
    for (final table in content.querySelectorAll('table')) {
      final sections = _tryParseTable(table);
      if (sections.isNotEmpty) return sections;
    }
    return [];
  }

  List<WalkthroughSection> _tryParseTable(dom.Element table) {
    final sections = <WalkthroughSection>[];
    var currentTitle = 'Contents';
    var currentChapters = <ChapterEntry>[];

    for (final row in table.querySelectorAll('tr')) {
      final ths = row.querySelectorAll('th');
      final tds = row.querySelectorAll('td');

      if (ths.isNotEmpty && tds.isEmpty) {
        // Pure header row (colspan th) → new section
        final headerText = ths.first.text.trim();
        if (headerText == 'Contents') continue;
        if (headerText.isEmpty) continue;

        if (currentChapters.isNotEmpty) {
          sections.add(WalkthroughSection(
              title: currentTitle, chapters: currentChapters));
          currentChapters = [];
        }
        currentTitle = headerText;
      } else if (ths.isNotEmpty && tds.isNotEmpty) {
        // Chapter row: <th> holds the link, <td> holds the description
        final a = ths.first.querySelector('a[href]');
        if (a == null) continue;

        final href = a.attributes['href'] ?? '';
        if (!href.contains('/wiki/Walkthrough:')) continue;

        final chapterName = a.text.trim();
        if (chapterName.isEmpty) continue;

        final description = tds.first.text.trim();
        final url = href.startsWith('http')
            ? href
            : 'https://m.bulbapedia.bulbagarden.net$href';

        currentChapters.add(ChapterEntry(
          name: chapterName,
          url: url,
          description: description,
        ));
      } else if (tds.length >= 2) {
        // Fallback: both columns are <td>
        final a = tds.first.querySelector('a[href]');
        if (a == null) continue;

        final href = a.attributes['href'] ?? '';
        if (!href.contains('/wiki/Walkthrough:')) continue;

        final chapterName = a.text.trim();
        if (chapterName.isEmpty) continue;

        final description = tds[1].text.trim();
        final url = href.startsWith('http')
            ? href
            : 'https://m.bulbapedia.bulbagarden.net$href';

        currentChapters.add(ChapterEntry(
          name: chapterName,
          url: url,
          description: description,
        ));
      }
    }

    // Save last section
    if (currentChapters.isNotEmpty) {
      sections.add(
          WalkthroughSection(title: currentTitle, chapters: currentChapters));
    }

    return sections;
  }

  /// Fallback: scan the whole page for any Walkthrough sub-page links
  WalkthroughSection _fallbackSection(dom.Element content) {
    final chapters = <ChapterEntry>[];
    final seen = <String>{};

    for (final a in content.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      // Must be a sub-page link (contains /)
      if (!href.contains('/wiki/Walkthrough:') || !href.contains('/Part')) {
        continue;
      }
      if (seen.contains(href)) continue;
      seen.add(href);

      final url = href.startsWith('http')
          ? href
          : 'https://m.bulbapedia.bulbagarden.net$href';

      chapters.add(ChapterEntry(
        name: a.text.trim(),
        url: url,
        description: '',
      ));
    }

    return WalkthroughSection(title: 'Chapters', chapters: chapters);
  }

  String? _extractGameImage(dom.Element content) {
    // First image inside the infobox
    final infobox = content.querySelector('.infobox, table');
    if (infobox != null) {
      final img = infobox.querySelector('img');
      if (img != null) {
        final src = img.attributes['src'] ?? '';
        if (src.isNotEmpty) {
          return src.startsWith('//') ? 'https:$src' : src;
        }
      }
    }
    return null;
  }
}
