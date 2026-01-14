import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:suara/services/audio_file_scanner.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<File> songs = [];
  bool _isLoading = true;

  Future<void> loadMusic() async {
    String musicPath = '';

    final prefs = await SharedPreferences.getInstance();
    musicPath = prefs.getString('music_path') ?? '';

    List<File> foundSongs = [];

    if (musicPath.isNotEmpty) {
      foundSongs = await scanAudio(musicPath, ['.mp3']);
    }

    if (mounted) {
      setState(() {
        songs = foundSongs;
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
        child: Text("No songs found.\nMake sure you've added your music directory path in the settings"),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final file = songs[index];
        return ListTile(title: Text(file.path));
      },
    );
  }
}
