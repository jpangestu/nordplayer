import 'package:path/path.dart' as p;

// Split the string by spaces, hyphens, or underscores
final RegExp _wordSplitRegex = RegExp(r'[\s_-]+');

extension StringExtension on String {
  String toTitleCase() {
    final trimmed = trim();
    if (trimmed.isEmpty) return this;

    final words = trimmed.split(_wordSplitRegex);

    if (words.isEmpty) return this;

    // Capitalize the first letter of each word and lowercase the rest
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String toPascalCase() {
    final trimmed = trim();
    if (trimmed.isEmpty) return this;

    final words = trimmed.split(_wordSplitRegex);

    if (words.isEmpty) return this;

    // Capitalize the first letter of all subsequent words, and lowercase the rest
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join('');
  }

  /// Normalizes a file path or file URI into a standard platform-native path.
  String normalizePath() {
    String path = this;
    if (toLowerCase().startsWith('file:/')) {
      try {
        path = Uri.parse(this).toFilePath();
      } catch (_) {}
    }
    return p.normalize(path);
  }
}
