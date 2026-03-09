import 'package:html/dom.dart' as dom;
import '../../models/page_data.dart';

class BrowseParser {
  BrowsePageData parse(dom.Element content) {
    final games = <GameEntry>[];
    final seen = <String>{};

    // All anchor elements that link to a Walkthrough: page and contain an img
    for (final a in content.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      if (!href.contains('/wiki/Walkthrough:')) continue;
      // Skip file-description links (clicking box art opens image page)
      if (a.classes.contains('mw-file-description')) continue;

      final img = a.querySelector('img');
      if (img == null) continue;

      // Deduplicate by URL
      if (seen.contains(href)) continue;
      seen.add(href);

      final rawTitle =
          a.attributes['title'] ?? a.text.trim();
      final title = rawTitle
          .replaceFirst(RegExp(r'^Walkthrough:\s*'), '')
          .trim();
      if (title.isEmpty) continue;

      final src = img.attributes['src'] ?? '';
      final imageUrl = src.startsWith('//') ? 'https:$src' : src;

      // Use absolute URL
      final url = href.startsWith('http')
          ? href
          : 'https://m.bulbapedia.bulbagarden.net$href';

      games.add(GameEntry(title: title, imageUrl: imageUrl, url: url));
    }

    return BrowsePageData(games);
  }
}
