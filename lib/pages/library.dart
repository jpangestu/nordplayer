import 'package:flutter/material.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_service.dart';
import 'package:suara/services/library_service.dart';
import 'package:suara/widgets/album_art.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  @override
  void initState() {
    super.initState();
    LibraryService().syncLibrary();
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
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: songs.length,
          // Force every item to be exactly 72 pixels high (Standard ListTile height)
          // This allows Flutter to "jump" calculation during fast scrolls.
          itemExtent: 72.0,
          itemBuilder: (context, index) {
            return ListTile(
              leading: AlbumArt(artPath: songs[index].artPath),
              title: Text(songs[index].title, maxLines: 1, overflow: .ellipsis),
              subtitle: Text(
                songs[index].artist,
                maxLines: 1,
                overflow: .ellipsis,
              ),
              onTap: () {
                final audioService = AudioService();
                audioService.setQueueAndPlay(songs, songs[index].id);
              },
            );
          },
        );
      },
    );
  }
}
