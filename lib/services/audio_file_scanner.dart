import 'dart:io';
import 'package:path/path.dart' as p;

Future<List<File>> scanAudio(
  String directoryPath,
  List<String> extensions, {
  bool recursive = true,
}) async {
  if (directoryPath.isEmpty) {
    return [];
  }

  if (!await Directory(directoryPath).exists()) {
    return [];
  }

  final List<File> matchingFiles = [];

  try {
    final directory = Directory(directoryPath);
    final entities = directory.list(recursive: recursive, followLinks: false);

    await for (final entity in entities) {
      if (entity is File) {
        final fileExtension = p.extension(entity.path).toLowerCase();
        // Check if the file extension is in the desired list (case-insensitive)
        if (extensions.contains(fileExtension)) {
          matchingFiles.add(entity);
        }
      }
    }
  } catch (e) {
    print("Error: $e");
  }

  return matchingFiles;
}
