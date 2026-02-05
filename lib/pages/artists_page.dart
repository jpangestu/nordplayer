import 'package:flutter/material.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Artists'),
        centerTitle: true,
      ),
      body: Center(child: Text('Artists')),
    );
  }
}
