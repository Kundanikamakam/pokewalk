import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../core/constants.dart';
import '../models/page_data.dart';
import 'parsers/browse_parser.dart';
import 'parsers/index_parser.dart';
import 'parsers/chapter_preprocessor.dart';

class BulbapediaService {
  static final _client = http.Client();

  final _browseParser = BrowseParser();
  final _indexParser = IndexParser();
  final _chapterPreprocessor = ChapterPreprocessor();

  /// Fetches a Bulbapedia page and returns typed [PageData].
  Future<({String title, PageData pageData, String rawHtml})> fetchPage(
      String url) async {
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

    return _parsePage(url, response.body);
  }

  ({String title, PageData pageData, String rawHtml}) _parsePage(
      String url, String rawHtml) {
    final doc = html_parser.parse(rawHtml);
    final title = _extractTitle(doc);
    final content = _extractContent(doc);
    _rewriteUrls(content, kBulbapediaBase);

    final pageType = detectPageType(url);
    late PageData pageData;

    switch (pageType) {
      case BulbapediaPageType.browse:
        pageData = BrowseData(_browseParser.parse(content));

      case BulbapediaPageType.walkthroughIndex:
        pageData = IndexData(_indexParser.parse(content, title));

      case BulbapediaPageType.chapter:
        _removeNoise(content);
        final processed = _chapterPreprocessor.process(content);
        pageData = ChapterData(ChapterPageData(
          title: title,
          processedHtml: processed.html,
          nav: processed.nav,
          partyContainers: processed.partyContainers,
          expandableSections: processed.expandableSections,
        ));
    }

    return (title: title, pageData: pageData, rawHtml: rawHtml);
  }

  /// Re-parses cached raw HTML into [PageData] without a network request.
  ({String title, PageData pageData}) parseFromCache(
      String url, String rawHtml) {
    final result = _parsePage(url, rawHtml);
    return (title: result.title, pageData: result.pageData);
  }

  String _extractTitle(dom.Document doc) {
    final h1 = doc.querySelector('#firstHeading, .firstHeading, h1');
    if (h1 != null) return h1.text.trim();
    final titleTag = doc.querySelector('title');
    if (titleTag != null) {
      return titleTag.text
          .trim()
          .replaceAll(
              ' - Bulbapedia, the community-driven Pokémon encyclopedia', '')
          .trim();
    }
    return 'Bulbapedia';
  }

  dom.Element _extractContent(dom.Document doc) {
    for (final sel in ['.mw-parser-output', '#mw-content-text', '#content']) {
      final el = doc.querySelector(sel);
      if (el != null) return el;
    }
    return doc.body ?? doc.createElement('div');
  }

  void _rewriteUrls(dom.Element content, String base) {
    for (final img in content.querySelectorAll('img[src]')) {
      final src = img.attributes['src']!;
      if (src.startsWith('//')) img.attributes['src'] = 'https:$src';
      if (src.startsWith('/')) img.attributes['src'] = '$base$src';
    }
    for (final a in content.querySelectorAll('a[href]')) {
      final href = a.attributes['href']!;
      if (href.startsWith('/wiki/')) {
        a.attributes['href'] = '$kBulbapediaBase$href';
      } else if (href.startsWith('//')) {
        a.attributes['href'] = 'https:$href';
      } else if (href.startsWith('/')) {
        a.attributes['href'] = '$base$href';
      }
    }
  }

  void _removeNoise(dom.Element content) {
    for (final sel in [
      '.mw-editsection',
      '.noprint',
      '#catlinks',
      '.printfooter',
      '.mw-empty-elt',
      '[role="navigation"]',
      '.navbox',
      '.sister-wiki',
      '.toc',
      '.hatnote',
    ]) {
      for (final el in content.querySelectorAll(sel)) {
        el.remove();
      }
    }
  }

  String _toMobileUrl(String url) {
    return url
        .replaceFirst('https://bulbapedia.bulbagarden.net',
            'https://m.bulbapedia.bulbagarden.net')
        .replaceFirst('http://bulbapedia.bulbagarden.net',
            'https://m.bulbapedia.bulbagarden.net');
  }

  static bool isInternalWikiUrl(String url) =>
      url.contains('bulbapedia.bulbagarden.net/wiki/');

  void dispose() => _client.close();
}

