import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:suara/models/song.dart';
import 'package:suara/services/audio_file_scanner.dart';
import 'package:suara/services/audio_manager.dart';
import 'package:suara/services/metadata_service.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<Song> songs = [];
  bool _isLoading = true;

  Future<void> loadMusic() async {
    String musicPath = '';

    final prefs = await SharedPreferences.getInstance();
    musicPath = prefs.getString('music_path') ?? '';

    List<File> tempFiles = [];
    List<Song> tempSongs = [];

    if (musicPath.isNotEmpty) {
      tempFiles = await scanAudio(musicPath, ['.mp3']);

      // Sequential parse
      // for (File song in tempFiles) {
      //   tempSongs.add(await parseMetadata(song));
      // }

      // Concurrent parse
      tempSongs = await Future.wait(
        tempFiles.map((file) => parseMetadata(file)),
      );

      tempSongs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }

    if (mounted) {
      setState(() {
        songs = tempSongs;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadMusic();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return Center(child: CircularProgressIndicator());
    }

    if (songs.isEmpty) {
      return const Center(
        child: Text(
          "No songs found.\nMake sure you've added your music directory path in the settings",
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.music_note),
          title: Text(songs[index].title, maxLines: 1, overflow: .ellipsis),
          subtitle: Text(songs[index].artist, maxLines: 1, overflow: .ellipsis),
          onTap: () {
            final audioManager = AudioManager();
            audioManager.play(songs[index].path);
          },
        );
      },
    );
  }
}
