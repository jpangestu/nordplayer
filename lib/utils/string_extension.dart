extension StringExtension on String {
  String toTitleCase() {
    if (trim().isEmpty) return this;

    // Split the string by spaces, hyphens, or underscores
    final words = trim().split(RegExp(r'[\s_-]+'));

    if (words.isEmpty) return this;

    // Capitalize the first letter of each word and lowercase the rest
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' '); // We join with a space to keep it human-readable
  }

  String toPascalCase() {
    if (trim().isEmpty) return this;

    // Split the string by spaces, hyphens, or underscores
    final words = trim().split(RegExp(r'[\s_-]+'));

    if (words.isEmpty) return this;

    // Capitalize the first letter of all subsequent words, and lowercase the rest
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join('');
  }
}
