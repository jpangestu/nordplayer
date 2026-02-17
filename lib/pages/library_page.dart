import 'package:flutter/material.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Library'), centerTitle: true),
      body: StreamBuilder<List<SongWithArtists>>(
        stream: AppDatabase().watchLibrary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return const Center(child: Text("No songs found. Try scanning!"));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final item = songs[index];
              final track = item.track;
              final album = item.album;
              List<String> artists = item.artists.map((a) => a.name).toList();

              return MusicTile(
                albumArtPath: album.albumArtPath,
                title: track.title,
                artists: artists,
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
