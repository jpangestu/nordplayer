extension IntExtension on int {
  /// Converts milliseconds into a formatted string (e.g., "1:04:30", "4:30", or "0:45").
  /// Standard format for individual track duration section
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

  /// Converts milliseconds into a formatted string (e.g., "2 hr 15 min", "45 min").
  /// Standard format for total aggregated lengths like Playlists or Albums
  String toTotalDurationString() {
    if (this <= 0) return '0 min';

    final duration = Duration(milliseconds: this);

    // For massive collections (like the entire library), you might want to scale up to days
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '$days Day${days > 1 ? 's' : ''} $hours Hour';
    }

    if (duration.inHours > 0) {
      return '${duration.inHours} Hour $minutes Minutes';
    }

    return '$minutes Minutes';
  }

  /// Converts bytes into a human-readable file size string (e.g., "24.1 GB", "850.5 MB", "12 KB")
  String toFileSizeString() {
    if (this <= 0) return '0 B';

    // We use 1024 instead of 1000 because operating systems calculate file sizes in binary.
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    const int tb = gb * 1024;

    final double size = toDouble();

    if (size >= tb) {
      return '${(size / tb).toStringAsFixed(1)} TB';
    } else if (size >= gb) {
      return '${(size / gb).toStringAsFixed(1)} GB';
    } else if (size >= mb) {
      return '${(size / mb).toStringAsFixed(1)} MB';
    } else if (size >= kb) {
      return '${(size / kb).toStringAsFixed(1)} KB';
    } else {
      // Bytes usually don't need decimal points
      return '$this B';
    }
  }
}
