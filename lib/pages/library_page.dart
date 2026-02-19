import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/flexible_table_layout.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Your library is empty",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Songs you add from your local folders will appear here.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to Settings
                      },
                      icon: const Icon(Icons.create_new_folder),
                      label: const Text("Add Music Folders"),
                    ),
                  ],
                ),
              ),
            );
          }

          return ResizableTableLayout(
            columns: const [
              TableColumn(
                label: "#",
                width: 50,
                minWidth: 50,
                alignment: .centerRight,
              ),
              TableColumn(label: "Title", flex: 5, minWidth: 300),
              TableColumn(label: "Album", flex: 3, minWidth: 150),
              TableColumn(
                label: 'Duration',
                width: 100,
                minWidth: 90,
                alignment: .centerRight,
              ),
            ],
            itemCount: songs.length,
            rowBuilder: (context, index, widths) {
              return _LibrarySongRow(
                songs: songs,
                index: index,
                widths: widths,
              );
            },
          );
        },
      ),
    );
  }
}

class _LibrarySongRow extends StatefulWidget {
  final List<SongWithArtists> songs;
  final int index;
  final List<double> widths;

  const _LibrarySongRow({
    required this.songs,
    required this.index,
    required this.widths,
  });

  @override
  State<_LibrarySongRow> createState() => _LibrarySongRowState();
}

class _LibrarySongRowState extends State<_LibrarySongRow> with LoggerMixin {
  late final TapGestureRecognizer _albumTapRecognizer;
  bool _rowHovered = false;
  bool _albumHovered = false;

  @override
  void initState() {
    super.initState();
    _albumTapRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _albumTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final double tileHeight = MusicTile.tileHeight(textScaler);

    final thisSong = widget.songs[widget.index];
    final thisSongArtists = thisSong.artists.map((a) => a.name).toList();

    final duration = Duration(milliseconds: thisSong.track.durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    final theme = Theme.of(context);
    final subtitleStyle =
        theme.listTileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium!;

    return MouseRegion(
      onEnter: (_) => setState(() => _rowHovered = true),
      onExit: (_) => setState(() => _rowHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () =>
            PlayerService().setPlaylist(widget.songs, widget.index),
        child: Container(
          height: tileHeight,
          decoration: BoxDecoration(
            color: _rowHovered
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // COLUMN 1: Index OR Play Button
              SizedBox(
                width: widget.widths[0],
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        PlayerService().setPlaylist(widget.songs, widget.index),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _rowHovered
                            ? const Icon(
                                Icons.play_arrow,
                                size: 20,
                              )
                            : Text(
                                "${widget.index + 1}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // COLUMN 2: Title & Artist
              SizedBox(
                width: widget.widths[1],
                child: MusicTile(
                  albumArtPath: thisSong.album.albumArtPath,
                  title: thisSong.track.title,
                  artists: thisSongArtists,
                ),
              ),

              // COLUMN 3: Album
              SizedBox(
                width: widget.widths[2],
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: thisSong.album.title,
                    recognizer: _albumTapRecognizer
                      ..onTap = () {
                        log.d(
                          'Navigate to album: ${thisSong.album.title} (from "${thisSong.track.title}")',
                        );
                      },
                    onEnter: (_) => setState(() => _albumHovered = true),
                    onExit: (_) => setState(() => _albumHovered = false),
                    style: subtitleStyle.copyWith(
                      decoration: _albumHovered
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ),

              // COLUMN 4: Duration
              SizedBox(
                width: widget.widths[3],
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      '$minutes:${seconds.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
