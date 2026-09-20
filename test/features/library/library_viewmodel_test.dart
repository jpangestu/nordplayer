import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/models/library_section_config.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/features/library/library_viewmodel.dart';

void main() {
  group('LibraryViewModel', () {
    late ProviderContainer container;

    setUp(() {
      final initialSections = [
        const LibrarySectionConfig(id: 'recently_added', isVisible: true),
        const LibrarySectionConfig(id: 'albums', isVisible: true),
        const LibrarySectionConfig(id: 'tracks', isVisible: false),
      ];

      container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(
            AppConfig(librarySections: initialSections),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('reorderSections moves section to target index', () {
      final vm = container.read(libraryViewModelProvider);
      vm.reorderSections(0, 2);

      final sections = container.read(librarySectionsProvider);
      expect(sections.map((s) => s.id).toList(), equals(['albums', 'recently_added', 'tracks']));
    });

    test('toggleSectionVisibility flips boolean visibility', () {
      final vm = container.read(libraryViewModelProvider);

      // 'tracks' was false, now true
      vm.toggleSectionVisibility('tracks');
      var sections = container.read(librarySectionsProvider);
      expect(sections.firstWhere((s) => s.id == 'tracks').isVisible, isTrue);

      // Flip back to false
      vm.toggleSectionVisibility('tracks');
      sections = container.read(librarySectionsProvider);
      expect(sections.firstWhere((s) => s.id == 'tracks').isVisible, isFalse);
    });
  });
}
