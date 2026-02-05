import 'package:flutter/material.dart';
import 'package:suara/models/artist.dart';

class ArtistDetailsPage extends StatelessWidget {
  final Artist artist;

  const ArtistDetailsPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(artist.name)]);
  }
}
