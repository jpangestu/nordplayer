import 'package:flutter/material.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/widgets/album_art.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Database().watchAllAlbums(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final albums = snapshot.data!;

        if (albums.isEmpty) {
          return const Center(child: Text("No songs found in Library."));
        }

        return GridView.builder(
          gridDelegate:
          // SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 10),
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // Number of columns
            crossAxisSpacing: 4.0, // Spacing between items horizontally
            mainAxisSpacing: 4.0, // Spacing between items vertically
          ),
          itemBuilder: (context, index) {
            return GridTile(
              footer: Text(albums[index].title),
              child: AlbumArt(artPath: albums[index].artPath, size: 600,),
            );
          },
        );
      },
    );
  }
}
