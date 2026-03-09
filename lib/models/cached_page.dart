import 'package:hive/hive.dart';

part 'cached_page.g.dart';

@HiveType(typeId: 0)
class CachedPage extends HiveObject {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String contentHtml;

  @HiveField(3)
  final DateTime fetchedAt;

  CachedPage({
    required this.url,
    required this.title,
    required this.contentHtml,
    required this.fetchedAt,
  });
}
