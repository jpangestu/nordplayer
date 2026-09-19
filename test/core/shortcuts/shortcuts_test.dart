import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/shortcuts/shortcuts.dart';

void main() {
  group('Shortcuts Intents & Providers', () {
    test('searchFocusNodeProvider lifecycle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final node = container.read(searchFocusNodeProvider);
      expect(node, isNotNull);
      expect(node.hasFocus, isFalse);
    });

    test('Intents can be instantiated as const', () {
      expect(const PlayOrPauseIntent(), isA<PlayOrPauseIntent>());
      expect(const SkipToNextIntent(), isA<SkipToNextIntent>());
      expect(const SkipToPreviousIntent(), isA<SkipToPreviousIntent>());
      expect(const ToggleShuffleIntent(), isA<ToggleShuffleIntent>());
      expect(const CycleLoopIntent(), isA<CycleLoopIntent>());
      expect(const VolumeUpIntent(), isA<VolumeUpIntent>());
      expect(const VolumeDownIntent(), isA<VolumeDownIntent>());
      expect(const MuteIntent(), isA<MuteIntent>());
      expect(const FocusSearchIntent(), isA<FocusSearchIntent>());
      expect(const PlaySelectedIntent(), isA<PlaySelectedIntent>());
    });
  });
}
