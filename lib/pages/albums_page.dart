import 'package:flutter/material.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Albums'),
        centerTitle: true,
      ),
      body: Center(child: Text('Albums')),
    );
  }
}
