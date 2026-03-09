import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../core/constants.dart';

class ParsedPage {
  final String title;
  final String contentHtml;
  final String url;

  const ParsedPage({
    required this.title,
    required this.contentHtml,
    required this.url,
  });
}

class BulbapediaService {
  static final _client = http.Client();

  /// Fetches a Bulbapedia page and returns its parsed content.
  /// [url] should be a full URL (mobile or desktop).
  Future<ParsedPage> fetchPage(String url) async {
    final mobileUrl = _toMobileUrl(url);
    final response = await _client.get(
      Uri.parse(mobileUrl),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load page: HTTP ${response.statusCode}');
    }

    return _parsePage(mobileUrl, response.body);
  }

  ParsedPage _parsePage(String url, String rawHtml) {
    final doc = html_parser.parse(rawHtml);

    // Extract page title
    final title = _extractTitle(doc);

    // Extract main content
    final content = _extractContent(doc);

    // Rewrite relative URLs to absolute
    _rewriteUrls(content, kBulbapediaBase);

    // Remove unwanted elements (ads, nav, edit links, etc.)
    _cleanContent(content);

    return ParsedPage(
      title: title,
      contentHtml: content.outerHtml,
      url: url,
    );
  }

  String _extractTitle(dom.Document doc) {
    final h1 = doc.querySelector('#firstHeading, .firstHeading, h1');
    if (h1 != null) return h1.text.trim();
    final titleTag = doc.querySelector('title');
    if (titleTag != null) {
      final raw = titleTag.text.trim();
      return raw.replaceAll(' - Bulbapedia, the community-driven Pokémon encyclopedia', '');
    }
    return 'Bulbapedia';
  }

  dom.Element _extractContent(dom.Document doc) {
    // Try to find the main article content
    final selectors = [
      '.mw-parser-output',
      '#mw-content-text',
      '#content',
      '.content',
    ];

    for (final sel in selectors) {
      final el = doc.querySelector(sel);
      if (el != null) return el;
    }

    // Fallback: return body
    return doc.body ?? doc.createElement('div');
  }

  void _rewriteUrls(dom.Element content, String base) {
    // Rewrite image src
    for (final img in content.querySelectorAll('img[src]')) {
      final src = img.attributes['src']!;
      if (src.startsWith('//')) {
        img.attributes['src'] = 'https:$src';
      } else if (src.startsWith('/')) {
        img.attributes['src'] = '$base$src';
      }
    }

    // Rewrite anchor hrefs (mark internal wiki links)
    for (final a in content.querySelectorAll('a[href]')) {
      final href = a.attributes['href']!;
      if (href.startsWith('/wiki/')) {
        a.attributes['href'] = '$kBulbapediaBase$href';
        a.attributes['data-internal'] = 'true';
      } else if (href.startsWith('//')) {
        a.attributes['href'] = 'https:$href';
      } else if (href.startsWith('/')) {
        a.attributes['href'] = '$base$href';
      }
    }
  }

  void _cleanContent(dom.Element content) {
    // Remove edit links, navigation boxes, ad containers, collapsible nav
    const removeSelectors = [
      '.mw-editsection',
      '.noprint',
      '.navbox',
      '#catlinks',
      '.printfooter',
      '.mw-empty-elt',
      '[role="navigation"]',
      '.sister-wiki',
      '.toc',         // table of contents (navigated natively)
      '.hatnote',
    ];

    for (final sel in removeSelectors) {
      for (final el in content.querySelectorAll(sel)) {
        el.remove();
      }
    }
  }

  /// Normalises a URL to use the mobile Bulbapedia subdomain.
  String _toMobileUrl(String url) {
    return url
        .replaceFirst('https://bulbapedia.bulbagarden.net',
            'https://m.bulbapedia.bulbagarden.net')
        .replaceFirst('http://bulbapedia.bulbagarden.net',
            'https://m.bulbapedia.bulbagarden.net');
  }

  /// Returns true if the URL is an internal Bulbapedia wiki page.
  static bool isInternalWikiUrl(String url) {
    return url.contains('bulbapedia.bulbagarden.net/wiki/');
  }

  void dispose() {
    _client.close();
  }
}
