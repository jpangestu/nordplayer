import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/core/models/library_section_config.dart';
import 'package:nordplayer/core/system/config_service.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';

/// Provider exposing the current list of configured library sections.
final librarySectionsProvider = Provider<List<LibrarySectionConfig>>((ref) {
  final config = ref.watch(configServiceProvider);
  return config.librarySections;
});

/// Computes and caches up to 6 sample tracks for the library overview panel.
final librarySampleTracksProvider = Provider<List<TrackWithArtists>>((ref) {
  final libraryAsync = ref.watch(libraryStreamProvider);
  final tracks = libraryAsync.value ?? [];
  if (tracks.isEmpty) return const [];
  final list = List<TrackWithArtists>.from(tracks)..shuffle();
  return list.take(6).toList();
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
