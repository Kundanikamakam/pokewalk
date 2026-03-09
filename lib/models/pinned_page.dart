import 'dart:convert';

class PinnedPage {
  final String url;
  final String title;
  final String? thumbnailUrl;

  const PinnedPage({
    required this.url,
    required this.title,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };

  factory PinnedPage.fromJson(Map<String, dynamic> json) => PinnedPage(
        url: json['url'] as String,
        title: json['title'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory PinnedPage.fromJsonString(String s) =>
      PinnedPage.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      other is PinnedPage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
