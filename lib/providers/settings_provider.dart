import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pinned_page.dart';
import 'service_providers.dart';

final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(
  FontSizeNotifier.new,
);

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() {
    return ref.read(settingsServiceProvider).fontSize;
  }

  Future<void> setSize(double size) async {
    await ref.read(settingsServiceProvider).setFontSize(size);
    state = size;
  }

  void increase() => setSize((state + 1).clamp(11, 22));
  void decrease() => setSize((state - 1).clamp(11, 22));
}

final pinnedPagesProvider =
    NotifierProvider<PinnedPagesNotifier, List<PinnedPage>>(
  PinnedPagesNotifier.new,
);

class PinnedPagesNotifier extends Notifier<List<PinnedPage>> {
  @override
  List<PinnedPage> build() {
    return ref.read(settingsServiceProvider).getPinnedPages();
  }

  Future<void> pin(PinnedPage page) async {
    await ref.read(settingsServiceProvider).addPinnedPage(page);
    state = ref.read(settingsServiceProvider).getPinnedPages();
  }

  Future<void> unpin(String url) async {
    await ref.read(settingsServiceProvider).removePinnedPage(url);
    state = ref.read(settingsServiceProvider).getPinnedPages();
  }

  bool isPinned(String url) => state.any((p) => p.url == url);
}
