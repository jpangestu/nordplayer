import 'dart:io';
import 'dart:isolate';

import 'package:metadata_god/metadata_god.dart';

import 'package:suara/models/song.dart';
import 'package:suara/services/audio_file_scanner.dart';
import 'package:suara/services/metadata_service.dart';

/// Scan all song in list of music path and return list of song
Future<List<Song>> scanLibrary(List<String> musicPath) async {
  if (musicPath.isEmpty) return [];

  // Run library scan in isolates
  return await Isolate.run(() => _internalScanTask(musicPath));
}

Future<List<Song>> _internalScanTask(List<String> musicPath) async {
  await MetadataGod.initialize();

  List<File> tempFiles = [];
  List<Song> tempSongs = [];

  // List directories
  for (String path in musicPath) {
    tempFiles.addAll(await scanAudio(path, ['.mp3']));
  }

  // Parse each file
  for (File file in tempFiles) {
    try {
      final song = await parseMetadata(file);
      tempSongs.add(song);
    } catch (e) {
      print("Skipping corrupt file: ${file.path}");
    }
  }

  tempSongs.sort(
    (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  );

  return tempSongs;
}
