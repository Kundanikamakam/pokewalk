import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/page_data.dart';
import '../services/bulbapedia_service.dart';
import 'party_container_widget.dart';
import 'expandable_section_widget.dart';

/// Renders Bulbapedia HTML content natively using Flutter widgets.
/// Internal wiki links trigger [onNavigate]; external links open the browser.
class WikiRenderer extends StatelessWidget {
  final String html;
  final double fontSize;
  final void Function(String url) onNavigate;
  final List<PartyContainerData> partyContainers;
  final List<ExpandableSectionData> expandableSections;

  const WikiRenderer({
    super.key,
    required this.html,
    required this.fontSize,
    required this.onNavigate,
    this.partyContainers = const [],
    this.expandableSections = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _buildStyleSheet();

    return Html(
      data: html,
      style: scheme,
      extensions: [
        TagExtension(
          tagsToExtend: {'partycontainer'},
          builder: (ctx) {
            final idxStr = ctx.styledElement?.element?.attributes['data-idx'] ?? '0';
            final idx = int.tryParse(idxStr) ?? 0;
            if (idx >= partyContainers.length) return const SizedBox.shrink();
            return PartyContainerWidget(
              data: partyContainers[idx],
              onNavigate: onNavigate,
              fontSize: fontSize,
            );
          },
        ),
        TagExtension(
          tagsToExtend: {'expandablesection'},
          builder: (ctx) {
            final idxStr = ctx.styledElement?.element?.attributes['data-idx'] ?? '0';
            final idx = int.tryParse(idxStr) ?? 0;
            if (idx >= expandableSections.length) return const SizedBox.shrink();
            return ExpandableSectionWidget(
              data: expandableSections[idx],
              onNavigate: onNavigate,
              fontSize: fontSize,
            );
          },
        ),
        TagExtension(
          tagsToExtend: {'img'},
          builder: (context) {
            final src = context.styledElement?.element?.attributes['src'] ?? '';
            if (src.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: CachedNetworkImage(
                imageUrl: src,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 24),
              ),
            );
          },
        ),
      ],
      onLinkTap: (url, _, __) => _handleLink(url),
    );
  }

  void _handleLink(String? url) {
    if (url == null) return;
    if (BulbapediaService.isInternalWikiUrl(url)) {
      onNavigate(url);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Map<String, Style> _buildStyleSheet() {
    return {
      'body': Style(
        fontSize: FontSize(fontSize),
        lineHeight: LineHeight(1.5),
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      'h1': Style(fontSize: FontSize(fontSize * 1.6), fontWeight: FontWeight.bold, margin: Margins.only(top: 12, bottom: 6)),
      'h2': Style(fontSize: FontSize(fontSize * 1.4), fontWeight: FontWeight.bold, margin: Margins.only(top: 10, bottom: 4), color: const Color(0xFF3B5BA5)),
      'h3': Style(fontSize: FontSize(fontSize * 1.2), fontWeight: FontWeight.bold, margin: Margins.only(top: 8, bottom: 4)),
      'h4': Style(fontSize: FontSize(fontSize * 1.1), fontWeight: FontWeight.bold),
      'p': Style(margin: Margins.only(bottom: 8)),
      'a': Style(color: const Color(0xFF1565C0), textDecoration: TextDecoration.none),
      'table': Style(
        margin: Margins.only(bottom: 8),
        backgroundColor: Colors.white,
      ),
      'th': Style(
        backgroundColor: const Color(0xFF3B5BA5),
        color: Colors.white,
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
        fontSize: FontSize(fontSize * 0.9),
        fontWeight: FontWeight.bold,
      ),
      'td': Style(
        padding: HtmlPaddings.zero,
        fontSize: FontSize(fontSize * 0.9),
      ),
      'li': Style(margin: Margins.only(bottom: 2)),
      'i': Style(fontStyle: FontStyle.italic),
      'b, strong': Style(fontWeight: FontWeight.bold),
      // Bulbapedia wiki info boxes
      '.roundy': Style(
        border: Border.all(color: Colors.grey.shade400),
        padding: HtmlPaddings.all(8),
        margin: Margins.only(bottom: 8),
      ),
    };
  }
}
