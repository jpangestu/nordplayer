import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/album_stack.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/nordplayer_app_bar.dart';
import 'package:nordplayer/widgets/sliver_resizable_table_layout.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final libraryAsync = ref.watch(libraryStreamProvider);

    final songs = libraryAsync.value ?? [];
    final songsRandom = [...songs]..shuffle();

    final int totalMs = songs.fold(
      0,
      (sum, song) => sum + song.track.durationMs,
    );

    final Duration totalDuration = Duration(milliseconds: totalMs);

    String formatTotalDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes % 60;

      if (hours > 0) {
        return '$hours hr $minutes min';
      } else {
        return '$minutes min';
      }
    }

    final List<String> sampleCovers = [];
    final Set<String> seenCovers = {};

    for (final song in songsRandom) {
      final artPath = song.album.albumArtPath;

      if (artPath != null &&
          artPath.isNotEmpty &&
          !seenCovers.contains(artPath)) {
        seenCovers.add(artPath);
        sampleCovers.add(artPath);
      }

      if (sampleCovers.length >= 6) break;
    }

    return Scaffold(
      appBar: NordplayerAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            expandedHeight: 220,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final settings = context
                      .dependOnInheritedWidgetOfExactType<
                        FlexibleSpaceBarSettings
                      >();
                  if (settings == null) return const SizedBox.shrink();
                  final deltaExtent = settings.maxExtent - settings.minExtent;
                  final t =
                      (settings.currentExtent - settings.minExtent) /
                      deltaExtent;
                  final clampT = t.clamp(0.0, 1.0);
                  final double horizontalOffset = 135 * clampT;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: horizontalOffset,
                      bottom: 60 * clampT,
                    ),
                    child: Text(
                      'Library',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              background: Container(
                padding: .symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.10),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: .center,
                  children: [
                    AlbumStack(
                      imageUrls: sampleCovers,
                      size: 180,
                      maxLayers: 5,
                      sliceWidth: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 40,
                        right: 16,
                      ),
                      child: Text(
                        '${songs.length} Songs - ${formatTotalDuration(totalDuration)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          libraryAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $error')),
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                          "Scan your local folders to set up your music library.",
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
                            context.go('/settings/library-management');
                          },
                          icon: const Icon(Icons.create_new_folder),
                          label: const Text("Add Music Folders"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverResizableTableLayout(
                columns: const [
                  TableColumn(
                    label: "#",
                    width: 50,
                    minWidth: 50,
                    alignment: Alignment.centerRight,
                  ),
                  TableColumn(label: "Title", flex: 5, minWidth: 200),
                  TableColumn(label: "Album", flex: 3, minWidth: 120),
                  TableColumn(
                    label: 'Duration',
                    width: 100,
                    minWidth: 90,
                    alignment: Alignment.centerRight,
                  ),
                ],
                itemCount: songs.length,
                rowBuilder: (context, index, widths, cellPadding) {
                  return _LibrarySongRow(
                    songs: songs,
                    index: index,
                    widths: widths,
                    cellPadding: cellPadding,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LibrarySongRow extends ConsumerStatefulWidget {
  final List<SongWithArtists> songs;
  final int index;
  final List<double> widths;
  final EdgeInsets cellPadding;

  const _LibrarySongRow({
    required this.songs,
    required this.index,
    required this.widths,
    required this.cellPadding,
  });

  @override
  ConsumerState<_LibrarySongRow> createState() => _LibrarySongRowState();
}

class _LibrarySongRowState extends ConsumerState<_LibrarySongRow>
    with LoggerMixin {
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

    final currentSong = ref.watch(currentSongProvider).value;

    final thisSong = widget.songs[widget.index];
    final thisSongArtists = thisSong.artists.map((a) => a.name).toList();
    final bool thisSongPlayed =
        currentSong?.track.filePath == thisSong.track.filePath;

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
        onDoubleTap: () => ref
            .read(playerServiceProvider)
            .setPlaylist(widget.songs, widget.index),
        child: Container(
          height: tileHeight,
          decoration: BoxDecoration(
            borderRadius: .circular(6),
            color: _rowHovered
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: .circular(6),
              color: thisSongPlayed
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
                      onTap: () => ref
                          .read(playerServiceProvider)
                          .setPlaylist(widget.songs, widget.index),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: widget.cellPadding,
                          child: _rowHovered
                              ? const Icon(Icons.play_arrow, size: 20)
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
                    selected: thisSongPlayed,
                    albumArtPath: thisSong.album.albumArtPath,
                    title: thisSong.track.title,
                    artists: thisSongArtists,
                    padding: widget.cellPadding,
                  ),
                ),

                // COLUMN 3: Album
                SizedBox(
                  width: widget.widths[2],
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
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
                ),

                // COLUMN 4: Duration
                SizedBox(
                  width: widget.widths[3],
                  child: Padding(
                    padding: widget.cellPadding,
                    child: Align(
                      alignment: Alignment.centerRight,
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
      ),
    );
  }
}
