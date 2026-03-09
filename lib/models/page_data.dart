enum BulbapediaPageType { browse, walkthroughIndex, chapter }

/// Detects which of the three handled page types a URL represents.
BulbapediaPageType detectPageType(String url) {
  if (url.contains('Browse:Walkthroughs')) return BulbapediaPageType.browse;
  if (url.contains('/wiki/Walkthrough:')) {
    // Sub-pages like /Part_N or /Chapter_N are chapter pages
    final afterWalkthrough = url.split('/wiki/Walkthrough:').last;
    if (afterWalkthrough.contains('/')) return BulbapediaPageType.chapter;
    return BulbapediaPageType.walkthroughIndex;
  }
  return BulbapediaPageType.chapter; // fallback: render as generic content
}

// ── Browse:Walkthroughs data ─────────────────────────────────────────────────

class GameEntry {
  final String title;
  final String imageUrl;
  final String url;

  const GameEntry({
    required this.title,
    required this.imageUrl,
    required this.url,
  });
}

class BrowsePageData {
  final List<GameEntry> games;
  const BrowsePageData(this.games);
}

// ── Walkthrough index data ────────────────────────────────────────────────────

class ChapterEntry {
  final String name;
  final String url;
  final String description;

  const ChapterEntry({
    required this.name,
    required this.url,
    required this.description,
  });
}

class WalkthroughSection {
  final String title; // e.g. "Main Storyline", "Post-Elite Four"
  final List<ChapterEntry> chapters;

  const WalkthroughSection({required this.title, required this.chapters});
}

class IndexPageData {
  final String gameTitle;
  final String? gameImageUrl;
  final List<WalkthroughSection> sections;

  const IndexPageData({
    required this.gameTitle,
    required this.sections,
    this.gameImageUrl,
  });
}

// ── Chapter page data ─────────────────────────────────────────────────────────

class ChapterPageData {
  final String title;
  final String processedHtml;

  const ChapterPageData({required this.title, required this.processedHtml});
}

// ── Union ─────────────────────────────────────────────────────────────────────

sealed class PageData {
  const PageData();
}

class BrowseData extends PageData {
  final BrowsePageData data;
  const BrowseData(this.data);
}

class IndexData extends PageData {
  final IndexPageData data;
  const IndexData(this.data);
}

class ChapterData extends PageData {
  final ChapterPageData data;
  const ChapterData(this.data);
}
