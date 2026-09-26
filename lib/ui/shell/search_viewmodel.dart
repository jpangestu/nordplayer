import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// Notifier managing active search text input state.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Provider for the active search query string.
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Reactive stream provider returning search results matching the active query.
final searchResultsProvider = StreamProvider.autoDispose<List<TrackWithArtists>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(trackRepositoryProvider).searchTracks(query);
});
