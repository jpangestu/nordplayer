extension IntExtension on int {
  /// Converts milliseconds into a formatted string (e.g., "1:04:30", "4:30", or "0:45")
  String toDurationString() {
    final duration = Duration(milliseconds: this);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // Has hours -> H:mm:ss
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // No hours, has minutes -> m:ss
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    // No hours, no minutes -> 0:ss
    // Standard for music players, e.g., "0:45" is clearer than just "45"
    return '0:${seconds.toString().padLeft(2, '0')}';
  }
}
