import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/models/library_section_config.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/core/services/logger.dart';

/// Provider exposing the current list of configured library sections.
final librarySectionsProvider = Provider<List<LibrarySectionConfig>>((ref) {
  final config = ref.watch(configServiceProvider);
  return config.librarySections;
});

/// ViewModel coordinating library section ordering, visibility, and preferences.
class LibraryViewModel(final Ref _ref) with LoggerMixin {
  ConfigService get _configService => _ref.read(configServiceProvider.notifier);

  /// Moves a library section from [oldIndex] to [newIndex] and persists configuration.
  void reorderSections(int oldIndex, int newIndex) {
    final currentSections = List<LibrarySectionConfig>.from(_ref.read(librarySectionsProvider));
    if (oldIndex < 0 || oldIndex >= currentSections.length) return;

    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    targetIndex = targetIndex.clamp(0, currentSections.length - 1);

    final item = currentSections.removeAt(oldIndex);
    currentSections.insert(targetIndex, item);

    log.i('Reordered library section "${item.id}" from $oldIndex to $targetIndex');
    _configService.updateConfig(librarySections: currentSections);
  }

  /// Toggles visibility for the section with [sectionId] and persists configuration.
  void toggleSectionVisibility(String sectionId) {
    final currentSections = List<LibrarySectionConfig>.from(_ref.read(librarySectionsProvider));
    final index = currentSections.indexWhere((s) => s.id == sectionId);
    if (index == -1) return;

    final target = currentSections[index];
    final updated = target.copyWith(isVisible: !target.isVisible);
    currentSections[index] = updated;

    log.i('Toggled visibility for library section "$sectionId": ${updated.isVisible}');
    _configService.updateConfig(librarySections: currentSections);
  }
}

/// Riverpod provider exposing [LibraryViewModel].
final libraryViewModelProvider = Provider<LibraryViewModel>((ref) => LibraryViewModel(ref));
