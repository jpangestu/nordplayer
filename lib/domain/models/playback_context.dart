/// Represents the navigation / collection context from which playback originated
/// (e.g., 'all_tracks', 'playlist', 'album').
class const PlaybackContext({
  required final String type,
  final int? id,
}) {
  /// Checks whether playback is currently sourced from the specified collection.
  bool isPlaying(String targetType, int? targetId) =>
      type == targetType && id == targetId;

  /// Returns a copy of this context with the given fields replaced.
  PlaybackContext copyWith({String? type, int? id}) => PlaybackContext(
    type: type ?? this.type,
    id: id ?? this.id,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackContext &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'PlaybackContext(type: $type, id: $id)';
}
