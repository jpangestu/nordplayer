import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Library'), centerTitle: true),
      body: ListView(
        padding: .all(16),
        children: [
          MusicTile(
            artPath: 'assets/calm_down.jpg',
            title: 'Calm Down',
            artists: ['Rema', 'Selena Gomez'],
            onTap: () {},
          ),
          MusicTile(
            artPath: 'assets/enemy.jpg',
            title: 'Enemy',
            artists: ['Imagine Dragon', 'Kendrick Lamar'],
            selected: true,
            onTap: () {},
          ),
          MusicTile(
            artPath: 'assets/let_love_win.jpg',
            title: 'Let Love Win',
            artists: ['TheFatRat'],
            onTap: () {},
          ),
          MusicTile(
            title: 'Let Love Win',
            artists: ['TheFatRat'],
            onTap: () {},
          ),
          ListTile(),
        ],
      ),
    );
  }
}
