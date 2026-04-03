extension StringCasingExtension on String {
  String get pascalCase {
    if (trim().isEmpty) return this;

    // Split the string by spaces, hyphens, or underscores
    List<String> words = trim().split(RegExp(r'[\s_-]+'));

    if (words.isEmpty) return this;

    String result = '';

    // Capitalize the first letter of all subsequent words, and lowercase the rest
    for (int i = 0; i < words.length; i++) {
      if (words[i].isEmpty) continue;
      result += words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
    }

    return result;
  }
}
