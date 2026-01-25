import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_manager.dart';
import 'package:suara/services/library_scanner_task.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  Future<void> loadMusic() async {
    List<String> musicPath = [];

    final prefs = await SharedPreferences.getInstance();
    musicPath = prefs.getStringList('music_path') ?? [];

    List<Song> tempSongs = await scanLibrary(musicPath);

    Database().insertSongs(tempSongs);
  }

  @override
  void initState() {
    super.initState();
    loadMusic();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Song>>(
      stream: Database().watchAllSongs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final songs = snapshot.data!;

        if (songs.isEmpty) {
          return const Center(child: Text("No songs found in Library."));
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.music_note),
              title: Text(songs[index].title, maxLines: 1, overflow: .ellipsis),
              subtitle: Text(
                songs[index].artist,
                maxLines: 1,
                overflow: .ellipsis,
              ),
              onTap: () {
                final audioManager = AudioManager();
                audioManager.setQueueAndPlay(songs, index);
              },
            );
          },
        );
      },
    );
  }
}
