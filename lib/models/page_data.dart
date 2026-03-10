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

class PartyPokemonData {
  final String name;
  final String? imageUrl;
  final String? level;
  final List<String> typeNames;
  final List<String> moveNames;
  final String bgColor;
  final String? ability;
  final String? heldItem;
  const PartyPokemonData({
    required this.name,
    this.imageUrl,
    this.level,
    this.typeNames = const [],
    this.moveNames = const [],
    this.bgColor = '#C1C2C1',
    this.ability,
    this.heldItem,
  });
}

// ── Trainer section data ──────────────────────────────────────────────────────

class TrainerPokemonEntry {
  final String name;
  final String? imageUrl;
  final String level;
  final String? heldItem;
  const TrainerPokemonEntry({
    required this.name,
    this.imageUrl,
    required this.level,
    this.heldItem,
  });
}

class TrainerEntry {
  final String name;
  final String? trainerClass;
  final String? imageUrl;
  final String? reward;
  final List<TrainerPokemonEntry> pokemon;
  const TrainerEntry({
    required this.name,
    this.trainerClass,
    this.imageUrl,
    this.reward,
    this.pokemon = const [],
  });
}

class AvailablePokemonEntry {
  final String name;
  final String? imageUrl;
  final String? location;
  final String? levelRange;
  final String? rate;
  const AvailablePokemonEntry({
    required this.name,
    this.imageUrl,
    this.location,
    this.levelRange,
    this.rate,
  });
}

class ItemEntry {
  final String name;
  final String? imageUrl;
  final String location;
  const ItemEntry({
    required this.name,
    this.imageUrl,
    required this.location,
  });
}

// ── Expandable section data (sealed) ─────────────────────────────────────────

sealed class ExpandableSectionData {
  final String title;
  const ExpandableSectionData(this.title);
}

class TrainersExpandableData extends ExpandableSectionData {
  final List<TrainerEntry> trainers;
  const TrainersExpandableData(super.title, this.trainers);
}

class AvailablePokemonExpandableData extends ExpandableSectionData {
  final List<AvailablePokemonEntry> pokemon;
  const AvailablePokemonExpandableData(super.title, this.pokemon);
}

class ItemsExpandableData extends ExpandableSectionData {
  final List<ItemEntry> items;
  const ItemsExpandableData(super.title, this.items);
}

class GenericExpandableData extends ExpandableSectionData {
  final String contentHtml;
  const GenericExpandableData(super.title, this.contentHtml);
}

class ChapterNav {
  final String? prevUrl;
  final String? prevLabel;
  final String? nextUrl;
  final String? nextLabel;
  /// Raw CSS gradient string extracted from the nav div (e.g. "linear-gradient(135deg,#FFE57A 50%,#FFE57A 50%)")
  final String gradientCss;

  const ChapterNav({
    this.prevUrl,
    this.prevLabel,
    this.nextUrl,
    this.nextLabel,
    this.gradientCss = '',
  });
}

class PartyBoxData {
  final String trainerName;
  final String? trainerClass;
  final String? trainerImageUrl;
  final String? location;
  final String? reward;
  final String bgColor;
  final List<PartyPokemonData> pokemon;
  const PartyBoxData({
    required this.trainerName,
    this.trainerClass,
    this.trainerImageUrl,
    this.location,
    this.reward,
    this.bgColor = '#E1E1E1',
    this.pokemon = const [],
  });
}

class PartyContainerData {
  final String caption;
  final List<PartyBoxData> boxes;
  const PartyContainerData({required this.caption, required this.boxes});
}

class ChapterPageData {
  final String title;
  final String processedHtml;
  final ChapterNav? nav;
  final List<PartyContainerData> partyContainers;
  final List<ExpandableSectionData> expandableSections;

  const ChapterPageData({
    required this.title,
    required this.processedHtml,
    this.nav,
    this.partyContainers = const [],
    this.expandableSections = const [],
  });
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
