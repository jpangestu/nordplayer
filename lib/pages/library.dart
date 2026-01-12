import 'package:flutter/material.dart';

import 'package:suara/models/song.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<Song> songs = [
    Song(
      title: 'Afterlife',
      artist: 'Avenged Sevenfold',
      filePath: '/home/est/Music/Avenged Sevenfold - Afterlife.mp3',
    ),
    Song(
      title: 'Waiting For Love',
      artist: 'Avicii',
      filePath: '/home/est/Music/Avicii - Waiting For Love.mp3',
    ),
    Song(
      title: 'Warbringer',
      artist: 'TheFatRat',
      filePath: '/home/est/Music/TheFatRat - Warbringer.mp3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
            return ListTile(
              title: Text(songs[index].title),
            );
          },
      ),
    );
  }
}
