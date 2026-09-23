import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/utils/datetime_extension.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/utils/stream_extension.dart';
import 'package:nordplayer/utils/string_extension.dart';

void main() {
  group('StringExtension Tests', () {
    test('toTitleCase converts delimiters into capitalized title', () {
      expect('hello_world'.toTitleCase(), 'Hello World');
      expect('hello-world'.toTitleCase(), 'Hello World');
      expect('hello world'.toTitleCase(), 'Hello World');
      expect(''.toTitleCase(), '');
    });

    test('toPascalCase converts delimiters into PascalCase', () {
      expect('hello_world'.toPascalCase(), 'HelloWorld');
      expect('hello-world'.toPascalCase(), 'HelloWorld');
      expect(''.toPascalCase(), '');
    });

    test('normalizePath handles file URI and normal paths', () {
      expect('path/to/file.mp3'.normalizePath(), isNotEmpty);
      expect('FILE:///C:/music/song.mp3'.normalizePath(), isNotEmpty);
    });
  });

  group('DateTimeExtension Tests', () {
    test('toStandardFormat formats as DD MMM YYYY', () {
      final date = DateTime(2026, 9, 19);
      expect(date.toStandardFormat(), '19 Sep 2026');
    });

    test('toRelativeTime handles future dates and relative ranges safely', () {
      final now = DateTime.now();

      // Future date
      final future = now.add(const Duration(minutes: 5));
      expect(future.toRelativeTime(), 'Just now');

      // Seconds
      final recent = now.subtract(const Duration(seconds: 10));
      expect(recent.toRelativeTime(), 'Just now');

      // Minutes
      final minutesAgo = now.subtract(const Duration(minutes: 15));
      expect(minutesAgo.toRelativeTime(), '15m ago');

      // Hours
      final hoursAgo = now.subtract(const Duration(hours: 3));
      expect(hoursAgo.toRelativeTime(), '3h ago');

      // Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      expect(yesterday.toRelativeTime(), 'Yesterday');

      // Days
      final daysAgo = now.subtract(const Duration(days: 4));
      expect(daysAgo.toRelativeTime(), '4 days ago');

      // Weeks
      final oneWeek = now.subtract(const Duration(days: 8));
      expect(oneWeek.toRelativeTime(), '1 week ago');

      final fourWeeks = now.subtract(const Duration(days: 29));
      expect(fourWeeks.toRelativeTime(), '4 weeks ago');

      // Beyond a month
      final longAgo = now.subtract(const Duration(days: 60));
      expect(longAgo.toRelativeTime(), longAgo.toStandardFormat());
    });
  });

  group('IntExtension Tests', () {
    test('toDurationString formats correctly and clamps negative values', () {
      expect((-500).toDurationString(), '0:00');
      expect(45000.toDurationString(), '0:45');
      expect((4 * 60 * 1000 + 30 * 1000).toDurationString(), '4:30');
      expect((64 * 60 * 1000 + 30 * 1000).toDurationString(), '1:04:30');
    });

    test('toTotalDurationString formats with correct pluralization', () {
      expect(0.toTotalDurationString(), '0 min');
      expect((45 * 60 * 1000).toTotalDurationString(), '45 Minutes');
      expect((60 * 60 * 1000).toTotalDurationString(), '1 Hour');
      expect((135 * 60 * 1000).toTotalDurationString(), '2 Hours 15 Minutes');
      expect((25 * 60 * 60 * 1000).toTotalDurationString(), '1 Day 1 Hour');
      expect((48 * 60 * 60 * 1000).toTotalDurationString(), '2 Days');
    });

    test('toFileSizeString formats binary sizes', () {
      expect(0.toFileSizeString(), '0 B');
      expect(512.toFileSizeString(), '512 B');
      expect((1024 * 1024).toFileSizeString(), '1.0 MB');
      expect((1024 * 1024 * 1024 * 2).toFileSizeString(), '2.0 GB');
    });
  });

  group('StreamExtension Tests', () {
    test('debounceTime debounces events and preserves broadcast ability', () async {
      final controller = StreamController<int>.broadcast();
      final debounced = controller.stream.debounceTime(const Duration(milliseconds: 50));

      final results1 = <int>[];
      final results2 = <int>[];

      debounced.listen(results1.add);
      debounced.listen(results2.add);

      controller.add(1);
      controller.add(2);
      controller.add(3);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(results1, [3]);
      expect(results2, [3]);

      await controller.close();
    });
  });
}
