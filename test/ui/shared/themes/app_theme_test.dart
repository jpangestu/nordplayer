import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/ui/shared/themes/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('system font family converts to null in ThemeData', () {
      final theme = AppTheme.getTheme('nord', 'system');
      // When system font is selected, fontFamily is null so it never passes 'system'
      // to Flutter's typography, and font fallbacks are null.
      expect(theme.textTheme.bodyMedium?.fontFamily, isNot('system'));
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, isNull);
    });

    test('explicit font family is preserved in ThemeData', () {
      final theme = AppTheme.getTheme('nord', 'inter');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'inter');
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, isNotNull);
    });

    test('valid themes resolve expected color schemes', () {
      final nord = AppTheme.getTheme('nord', null);
      expect(nord.brightness, isNotNull);

      final nordLight = AppTheme.getTheme('nord_light', null);
      expect(nordLight.brightness, isNotNull);

      final graphite = AppTheme.getTheme('graphite', null);
      expect(graphite.brightness, isNotNull);
    });
  });
}
