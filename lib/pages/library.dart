import 'package:flutter/material.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_manager.dart';
import 'package:suara/services/library_manager.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  @override
  void initState() {
    super.initState();
    syncLibrary();
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
