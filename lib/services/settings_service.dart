import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../models/pinned_page.dart';

class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  double get fontSize =>
      _prefs.getDouble(kPrefFontSize) ?? kFontSizeDefault;

  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(kPrefFontSize, size.clamp(kFontSizeMin, kFontSizeMax));
  }

  List<PinnedPage> getPinnedPages() {
    final raw = _prefs.getStringList(kPrefPinnedPages) ?? [];
    return raw
        .map((s) {
          try {
            return PinnedPage.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<PinnedPage>()
        .toList();
  }

  Future<void> addPinnedPage(PinnedPage page) async {
    final pages = getPinnedPages();
    if (!pages.any((p) => p.url == page.url)) {
      pages.insert(0, page);
      await _savePinnedPages(pages);
    }
  }

  Future<void> removePinnedPage(String url) async {
    final pages = getPinnedPages()..removeWhere((p) => p.url == url);
    await _savePinnedPages(pages);
  }

  Future<void> clearPinnedPages() async {
    await _prefs.remove(kPrefPinnedPages);
  }

  bool isPinned(String url) => getPinnedPages().any((p) => p.url == url);

  bool get hasAutopinnedFirstPage =>
      _prefs.getBool(kPrefFirstPagePinned) ?? false;

  Future<void> setAutopinnedFirstPage() async {
    await _prefs.setBool(kPrefFirstPagePinned, true);
  }

  Future<void> _savePinnedPages(List<PinnedPage> pages) async {
    await _prefs.setStringList(
      kPrefPinnedPages,
      pages.map((p) => p.toJsonString()).toList(),
    );
  }

  // ── Orientation ──────────────────────────────────────────────────────────

  /// Returns 'auto', 'portrait', or 'landscape'.
  String get orientation => _prefs.getString(kPrefOrientation) ?? 'auto';

  Future<void> setOrientation(String value) async {
    await _prefs.setString(kPrefOrientation, value);
    _applyOrientation(value);
  }

  static void _applyOrientation(String value) {
    switch (value) {
      case 'portrait':
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      case 'landscape':
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      default:
        SystemChrome.setPreferredOrientations([]);
    }
  }

  void applyStoredOrientation() => _applyOrientation(orientation);
}
