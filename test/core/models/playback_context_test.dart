import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/models/playback_context.dart';

void main() {
  group('PlaybackContext Tests', () {
    test('instantiates with type and optional id', () {
      const ctx1 = PlaybackContext(type: 'all_tracks');
      expect(ctx1.type, equals('all_tracks'));
      expect(ctx1.id, isNull);

      const ctx2 = PlaybackContext(type: 'playlist', id: 42);
      expect(ctx2.type, equals('playlist'));
      expect(ctx2.id, equals(42));
    });

    test('value equality and hashCode match for identical properties', () {
      const a = PlaybackContext(type: 'album', id: 10);
      const b = PlaybackContext(type: 'album', id: 10);
      const c = PlaybackContext(type: 'album', id: 11);
      const d = PlaybackContext(type: 'playlist', id: 10);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('isPlaying correctly compares target type and id', () {
      const ctx = PlaybackContext(type: 'playlist', id: 5);

      expect(ctx.isPlaying('playlist', 5), isTrue);
      expect(ctx.isPlaying('playlist', 6), isFalse);
      expect(ctx.isPlaying('album', 5), isFalse);
      expect(ctx.isPlaying('all_tracks', null), isFalse);

      const allTracksCtx = PlaybackContext(type: 'all_tracks');
      expect(allTracksCtx.isPlaying('all_tracks', null), isTrue);
      expect(allTracksCtx.isPlaying('all_tracks', 1), isFalse);
      expect(allTracksCtx.isPlaying('album', null), isFalse);
    });

    test('copyWith produces updated instances without modifying original', () {
      const original = PlaybackContext(type: 'album', id: 7);
      final updatedType = original.copyWith(type: 'playlist');
      final updatedId = original.copyWith(id: 15);

      expect(updatedType.type, equals('playlist'));
      expect(updatedType.id, equals(7));
      expect(original.type, equals('album'));

      expect(updatedId.type, equals('album'));
      expect(updatedId.id, equals(15));
    });

    test('toString formats readable representation', () {
      const ctx = PlaybackContext(type: 'playlist', id: 3);
      expect(ctx.toString(), equals('PlaybackContext(type: playlist, id: 3)'));
    });
  });
}
