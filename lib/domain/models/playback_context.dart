import 'package:flutter/foundation.dart';

/// Represents the navigation / collection context from which playback originated.
///
/// Implemented as a sealed class hierarchy to provide exhaustive compile-time
/// checking while preserving 100% backward-compatible properties, copyWith, and string formats.
@immutable
sealed class PlaybackContext {
  const PlaybackContext._();

  /// Type identifier string (e.g., 'album', 'playlist', 'all_tracks').
  String get type;

  /// Associated collection database ID, if applicable.
  int? get id => null;

  /// Underlying collection title or query string, if applicable.
  String? get title => null;

  /// Human-readable title for UI presentation (e.g., "Playing from Album: Abbey Road").
  String get displayTitle;

  /// Checks whether playback originated from the specified collection.
  bool isPlaying(String targetType, int? targetId) => type == targetType && id == targetId;

  /// Checks if another context represents the exact same collection.
  bool isSameContext(PlaybackContext other);

  /// Creates a copy of this context with the given fields replaced.
  PlaybackContext copyWith({String? type, int? id, String? title});

  /// Default redirecting constructor preserving 100% backward compatibility.
  const factory PlaybackContext({required String type, int? id, String? title}) = RawPlaybackContext;

  const factory PlaybackContext.album({required int id, required String title}) = AlbumPlaybackContext;

  const factory PlaybackContext.playlist({required int id, required String title}) = PlaylistPlaybackContext;

  const factory PlaybackContext.allTracks() = AllTracksPlaybackContext;

  const factory PlaybackContext.search({required String query}) = SearchPlaybackContext;

  const factory PlaybackContext.manual() = ManualPlaybackContext;
}

/// Generic playback context used for legacy string-based callers and tests.
class const RawPlaybackContext(
    {@override required final String type, @override final int? id, @override final String? title})
    extends PlaybackContext {
  this : super._();

  @override
  String get displayTitle => title ?? (type.isEmpty ? 'Queue' : type);

  @override
  bool isSameContext(PlaybackContext other) => other.type == type && other.id == id;

  @override
  PlaybackContext copyWith({String? type, int? id, String? title}) {
    return RawPlaybackContext(type: type ?? this.type, id: id ?? this.id, title: title ?? this.title);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlaybackContext && other.type == type && other.id == id);

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}

/// Playback context originating from a specific [Album].
class const AlbumPlaybackContext({@override required final int id, @override required final String title})
    extends PlaybackContext {
  this : super._();

  @override
  String get type => 'album';

  @override
  String get displayTitle => 'Album: $title';

  @override
  bool isSameContext(PlaybackContext other) => other is AlbumPlaybackContext && other.id == id;

  @override
  PlaybackContext copyWith({String? type, int? id, String? title}) {
    if (type != null && type != this.type) {
      return RawPlaybackContext(type: type, id: id ?? this.id, title: title ?? this.title);
    }
    return AlbumPlaybackContext(id: id ?? this.id, title: title ?? this.title);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is AlbumPlaybackContext && other.id == id);

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}

/// Playback context originating from a user [Playlist].
class const PlaylistPlaybackContext({@override required final int id, @override required final String title})
    extends PlaybackContext {
  this : super._();

  @override
  String get type => 'playlist';

  @override
  String get displayTitle => 'Playlist: $title';

  @override
  bool isSameContext(PlaybackContext other) => other is PlaylistPlaybackContext && other.id == id;

  @override
  PlaybackContext copyWith({String? type, int? id, String? title}) {
    if (type != null && type != this.type) {
      return RawPlaybackContext(type: type, id: id ?? this.id, title: title ?? this.title);
    }
    return PlaylistPlaybackContext(id: id ?? this.id, title: title ?? this.title);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is PlaylistPlaybackContext && other.id == id);

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}

/// Playback context originating from the entire tracks library view.
class const AllTracksPlaybackContext() extends PlaybackContext {
  this : super._();

  @override
  String get type => 'all_tracks';

  @override
  String get displayTitle => 'All Tracks';

  @override
  bool isSameContext(PlaybackContext other) => other is AllTracksPlaybackContext;

  @override
  PlaybackContext copyWith({String? type, int? id, String? title}) {
    if (type != null && type != this.type) {
      return RawPlaybackContext(type: type, id: id ?? this.id, title: title ?? '');
    }
    return const AllTracksPlaybackContext();
  }

  @override
  bool operator ==(Object other) => other is AllTracksPlaybackContext;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}

/// Playback context originating from a search query.
class const SearchPlaybackContext({required final String query}) extends PlaybackContext {
  this : super._();

  @override
  String get type => 'search';

  @override
  String? get title => query;

  @override
  String get displayTitle => query.isEmpty ? 'Search Results' : 'Search: "$query"';

  @override
  bool isSameContext(PlaybackContext other) => other is SearchPlaybackContext && other.query == query;

  @override
  PlaybackContext copyWith({String? type, int? id, String? title}) {
    if (type != null && type != this.type) {
      return RawPlaybackContext(type: type, id: id ?? this.id, title: title ?? query);
    }
    return SearchPlaybackContext(query: title ?? query);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is SearchPlaybackContext && other.query == query);

  @override
  int get hashCode => Object.hash(runtimeType, query);

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}

/// Fallback or ad-hoc queue context (e.g. standalone play action).
class const ManualPlaybackContext() extends PlaybackContext {
  this : super._();

  @override
  String get type => 'manual';

  @override
  String get displayTitle => 'Queue';

  @override
  bool isSameContext(PlaybackContext other) => other is ManualPlaybackContext;

  @override
  PlaybackContext copyWith({String? type, int? id, String? title}) {
    if (type != null && type != this.type) {
      return RawPlaybackContext(type: type, id: id ?? this.id, title: title ?? '');
    }
    return const ManualPlaybackContext();
  }

  @override
  bool operator ==(Object other) => other is ManualPlaybackContext;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}
