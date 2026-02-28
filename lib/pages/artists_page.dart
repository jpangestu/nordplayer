import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/nordplayer_app_bar.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NordplayerAppBar(),
      body: Center(child: Text('Artists')),
    );
  }
}
