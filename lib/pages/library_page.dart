import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final sixTracks = ref.watch(random6TracksProvider);

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const .all(24.0),
        children: [
          const CollapsibleSection(label: 'Pinned', content: Placeholder()),

          const SizedBox(height: 16),

          CollapsibleSection(
            label: 'Playlists',
            onLabelClick: () {
              context.go(Routes.playlistsPage);
            },
            content: const Placeholder(),
          ),

          const SizedBox(height: 16),

          CollapsibleSection(
            label: 'All Tracks',
            onLabelClick: () {
              context.go(Routes.allTracksPage);
            },
            content: sixTracks.length < 6
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text("Not enough tracks yet. Loading or empty library!")),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TrackTile(track: sixTracks[0]),
                            TrackTile(track: sixTracks[1]),
                            TrackTile(track: sixTracks[2]),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      Expanded(
                        child: Column(
                          children: [
                            TrackTile(track: sixTracks[3]),
                            TrackTile(track: sixTracks[4]),
                            TrackTile(track: sixTracks[5]),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          const CollapsibleSection(label: 'Recently Added', content: Placeholder()),
        ],
      ),
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({super.key, required this.label, this.onLabelClick, required this.content});

  final String label;
  final void Function()? onLabelClick;
  final Widget content;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            MouseRegion(
              cursor: widget.onLabelClick != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: widget.onLabelClick,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label, style: theme.textTheme.titleLarge),
                    if (widget.onLabelClick != null)
                      Icon(Icons.chevron_right, color: theme.textTheme.titleLarge!.color, size: 28),
                  ],
                ),
              ),
            ),

            const Spacer(),

            IconButton(
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 28,
                // color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        if (isExpanded) SizedBox(height: 180, width: double.infinity, child: widget.content),
      ],
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track});

  final TrackWithArtists track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: MusicTile(
              padding: const .all(0),
              title: track.track.title,
              // title: 'Lover',
              artists: track.artists.map((artist) => artist.name).toList(),
              // artists: ['Taylor Swift'],
              albumArtPath: track.album.albumArtPath,
              // albumArtPath: "/home/est/.cache/com.nordplayer.nordplayer/album_art/album_43.jpg",
            ),
          ),
          const Icon(Icons.menu),
        ],
      ),
    );
  }
}

// final dummyTrack = TrackWithArtists(
//   track: Track(
//     id: 1,
//     title: "Lover",
//     trackNumber: 9,
//     trackTotal: 14,
//     discNumber: 1,
//     discTotal: 1,
//     durationMs: 200000,
//     genre: "Synthwave",
//     filePath:
//         "/mnt/shared/Music/The Complete Collection (320kbps) - 371 song/Taylor Swift/Lover/Taylor Swift - Lover.mp3",
//     fileSize: 8000000,
//     artistId: 1,
//     albumId: 1,
//     dateAdded: DateTime.now(),
//   ),
//   album: const Album(
//     id: 1,
//     title: "Lover",
//     year: 2020,
//     albumArtist: "Taylor Swift",
//     albumArtPath: "/home/est/.cache/com.nordplayer.nordplayer/album_art/album_43.jpg",
//     artistId: 1,
//   ),
//   artists: [const Artist(id: 1, name: "Taylor Swift")],
// );
