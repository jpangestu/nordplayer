import 'package:drift/drift.dart';
import 'package:nordplayer/data/database/app_database.dart' as db;
import 'package:nordplayer/domain/models/album.dart' as domain;
import 'package:nordplayer/domain/models/artist.dart' as domain;
import 'package:nordplayer/domain/models/playlist.dart' as domain;
import 'package:nordplayer/domain/models/track.dart' as domain;

/// Extension mappers converting raw Drift SQLite database records to pure domain models.
extension DbTrackMapper on db.Track {
  domain.Track toDomain() => domain.Track(
    id: id,
    title: title,
    trackNumber: trackNumber,
    trackTotal: trackTotal,
    discNumber: discNumber,
    discTotal: discTotal,
    durationMs: durationMs,
    genre: genre,
    fileHash: fileHash,
    audioFingerprint: audioFingerprint,
    isMissing: isMissing,
    filePath: filePath,
    fileSize: fileSize,
    artistId: artistId,
    albumId: albumId,
    dateAdded: dateAdded,
  );
}

extension DbAlbumMapper on db.Album {
  domain.Album toDomain() => domain.Album(
    id: id,
    title: title,
    year: year,
    albumArtist: albumArtist,
    albumArtPath: albumArtPath,
    albumArtistId: albumArtistId,
  );
}

extension DbArtistMapper on db.Artist {
  domain.Artist toDomain() => domain.Artist(id: id, name: name, artistImgPath: artistImgPath);
}

extension DbPlaylistMapper on db.PlaylistData {
  domain.Playlist toDomain() => domain.Playlist(id: id, name: name, coverPath: coverPath);
}

/// Extension mappers converting pure domain models back to Drift companions for database persistence.
extension DomainTrackMapper on domain.Track {
  db.TracksCompanion toCompanion({bool includeId = true}) => db.TracksCompanion(
    id: includeId ? Value(id) : const Value.absent(),
    title: Value(title),
    trackNumber: Value(trackNumber),
    trackTotal: Value(trackTotal),
    discNumber: Value(discNumber),
    discTotal: Value(discTotal),
    durationMs: Value(durationMs),
    genre: Value(genre),
    fileHash: Value(fileHash),
    audioFingerprint: Value(audioFingerprint),
    isMissing: Value(isMissing),
    filePath: Value(filePath),
    fileSize: Value(fileSize),
    artistId: Value(artistId),
    albumId: Value(albumId),
    dateAdded: Value(dateAdded),
  );
}

extension DomainPlaylistMapper on domain.Playlist {
  db.PlaylistsCompanion toCompanion({bool includeId = true}) => db.PlaylistsCompanion(
    id: includeId ? Value(id) : const Value.absent(),
    name: Value(name),
    coverPath: Value(coverPath),
  );
}

extension DomainAlbumMapper on domain.Album {
  db.AlbumsCompanion toCompanion({bool includeId = true}) => db.AlbumsCompanion(
    id: includeId ? Value(id) : const Value.absent(),
    title: Value(title),
    year: Value(year),
    albumArtist: Value(albumArtist),
    albumArtPath: Value(albumArtPath),
    albumArtistId: Value(albumArtistId),
  );
}

extension DomainArtistMapper on domain.Artist {
  db.ArtistsCompanion toCompanion({bool includeId = true}) => db.ArtistsCompanion(
    id: includeId ? Value(id) : const Value.absent(),
    name: Value(name),
    artistImgPath: Value(artistImgPath),
  );
}
