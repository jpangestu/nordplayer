import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('executes action after specified duration', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() {
        callCount++;
      });

      expect(callCount, 0);
      expect(debouncer.isActive, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(callCount, 1);
      expect(debouncer.isActive, isFalse);
    });

    test('coalesces rapid calls and executes only the last action', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      int lastValue = 0;

      debouncer.call(() => lastValue = 1);
      debouncer.call(() => lastValue = 2);
      debouncer.call(() => lastValue = 3);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(lastValue, 3);
    });

    test('cancel drops the pending action and stops the timer', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(debouncer.isActive, isTrue);

      debouncer.cancel();
      expect(debouncer.isActive, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(callCount, 0);
    });

    test('flush immediately executes the pending action and cancels timer', () {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(debouncer.isActive, isTrue);
      expect(callCount, 0);

      debouncer.flush();
      expect(callCount, 1);
      expect(debouncer.isActive, isFalse);

      // Calling flush again does nothing
      debouncer.flush();
      expect(callCount, 1);
    });

    test('flush does nothing when no action is pending', () {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.flush();
      expect(callCount, 0);
    });

    test('dispose marks debouncer disposed and prevents further execution', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.dispose();
      expect(debouncer.isDisposed, isTrue);

      debouncer.call(() => callCount++);
      expect(debouncer.isActive, isFalse);
      debouncer.flush();

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(callCount, 0);
    });
  });
}
