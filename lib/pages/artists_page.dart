import 'package:flutter/material.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/models/artist.dart';
import 'package:suara/pages/artist_details_page.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Artist>>(
      stream: Database().watchAllArtists(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists = snapshot.data!;

        if (artists.isEmpty) {
          return const Center(child: Text("No songs found in Library."));
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: artists.length,
          itemExtent: 72,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.person_outlined),
              title: Text(
                artists[index].name,
                maxLines: 1,
                overflow: .ellipsis,
              ),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ArtistDetailsPage(artist: artists[index]),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
