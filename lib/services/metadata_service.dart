import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:metadata_god/metadata_god.dart';

import 'package:suara/models/song.dart';

Future<Song> parseMetadata(File file) async {
  try {
    Metadata metadata = await MetadataGod.readMetadata(file: file.path);

    return Song(
      title: metadata.title ?? p.basenameWithoutExtension(file.path),
      artist: metadata.artist ?? 'unknown artist',
      path: file.path,
      duration: metadata.durationMs,
    );
  } catch (e) {
    print("Error parsing ${file.path}: $e");
    return Song.fromFile(file);
  }
}
