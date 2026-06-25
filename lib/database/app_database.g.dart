// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ArtistsTable extends Artists with TableInfo<$ArtistsTable, Artist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _artistImgPathMeta = const VerificationMeta(
    'artistImgPath',
  );
  @override
  late final GeneratedColumn<String> artistImgPath = GeneratedColumn<String>(
    'artist_img_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, artistImgPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Artist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist_img_path')) {
      context.handle(
        _artistImgPathMeta,
        artistImgPath.isAcceptableOrUnknown(
          data['artist_img_path']!,
          _artistImgPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Artist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artistImgPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_img_path'],
      ),
    );
  }

  @override
  $ArtistsTable createAlias(String alias) {
    return $ArtistsTable(attachedDatabase, alias);
  }
}

class Artist extends DataClass implements Insertable<Artist> {
  final int id;
  final String name;
  final String? artistImgPath;
  const Artist({required this.id, required this.name, this.artistImgPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || artistImgPath != null) {
      map['artist_img_path'] = Variable<String>(artistImgPath);
    }
    return map;
  }

  ArtistsCompanion toCompanion(bool nullToAbsent) {
    return ArtistsCompanion(
      id: Value(id),
      name: Value(name),
      artistImgPath: artistImgPath == null && nullToAbsent
          ? const Value.absent()
          : Value(artistImgPath),
    );
  }

  factory Artist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      artistImgPath: serializer.fromJson<String?>(json['artistImgPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'artistImgPath': serializer.toJson<String?>(artistImgPath),
    };
  }

  Artist copyWith({
    int? id,
    String? name,
    Value<String?> artistImgPath = const Value.absent(),
  }) => Artist(
    id: id ?? this.id,
    name: name ?? this.name,
    artistImgPath: artistImgPath.present
        ? artistImgPath.value
        : this.artistImgPath,
  );
  Artist copyWithCompanion(ArtistsCompanion data) {
    return Artist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      artistImgPath: data.artistImgPath.present
          ? data.artistImgPath.value
          : this.artistImgPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('artistImgPath: $artistImgPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, artistImgPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artist &&
          other.id == this.id &&
          other.name == this.name &&
          other.artistImgPath == this.artistImgPath);
}

class ArtistsCompanion extends UpdateCompanion<Artist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> artistImgPath;
  const ArtistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.artistImgPath = const Value.absent(),
  });
  ArtistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.artistImgPath = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Artist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? artistImgPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (artistImgPath != null) 'artist_img_path': artistImgPath,
    });
  }

  ArtistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? artistImgPath,
  }) {
    return ArtistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      artistImgPath: artistImgPath ?? this.artistImgPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artistImgPath.present) {
      map['artist_img_path'] = Variable<String>(artistImgPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('artistImgPath: $artistImgPath')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtPathMeta = const VerificationMeta(
    'albumArtPath',
  );
  @override
  late final GeneratedColumn<String> albumArtPath = GeneratedColumn<String>(
    'album_art_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistIdMeta = const VerificationMeta(
    'albumArtistId',
  );
  @override
  late final GeneratedColumn<int> albumArtistId = GeneratedColumn<int>(
    'album_artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    year,
    albumArtist,
    albumArtPath,
    albumArtistId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<Album> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('album_art_path')) {
      context.handle(
        _albumArtPathMeta,
        albumArtPath.isAcceptableOrUnknown(
          data['album_art_path']!,
          _albumArtPathMeta,
        ),
      );
    }
    if (data.containsKey('album_artist_id')) {
      context.handle(
        _albumArtistIdMeta,
        albumArtistId.isAcceptableOrUnknown(
          data['album_artist_id']!,
          _albumArtistIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      albumArtPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_art_path'],
      ),
      albumArtistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_artist_id'],
      ),
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final int id;
  final String title;
  final int year;
  final String? albumArtist;
  final String? albumArtPath;

  /// The database ID of the solo album artist (fallback to the track's primary artist if the albumArtist is empty).
  /// Set to null for compilation albums or multi-artist releases to avoid database clutter in the artists table.
  final int? albumArtistId;
  const Album({
    required this.id,
    required this.title,
    required this.year,
    this.albumArtist,
    this.albumArtPath,
    this.albumArtistId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['year'] = Variable<int>(year);
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || albumArtPath != null) {
      map['album_art_path'] = Variable<String>(albumArtPath);
    }
    if (!nullToAbsent || albumArtistId != null) {
      map['album_artist_id'] = Variable<int>(albumArtistId);
    }
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      title: Value(title),
      year: Value(year),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      albumArtPath: albumArtPath == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtPath),
      albumArtistId: albumArtistId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtistId),
    );
  }

  factory Album.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int>(json['year']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      albumArtPath: serializer.fromJson<String?>(json['albumArtPath']),
      albumArtistId: serializer.fromJson<int?>(json['albumArtistId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int>(year),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'albumArtPath': serializer.toJson<String?>(albumArtPath),
      'albumArtistId': serializer.toJson<int?>(albumArtistId),
    };
  }

  Album copyWith({
    int? id,
    String? title,
    int? year,
    Value<String?> albumArtist = const Value.absent(),
    Value<String?> albumArtPath = const Value.absent(),
    Value<int?> albumArtistId = const Value.absent(),
  }) => Album(
    id: id ?? this.id,
    title: title ?? this.title,
    year: year ?? this.year,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    albumArtPath: albumArtPath.present ? albumArtPath.value : this.albumArtPath,
    albumArtistId: albumArtistId.present
        ? albumArtistId.value
        : this.albumArtistId,
  );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      albumArtPath: data.albumArtPath.present
          ? data.albumArtPath.value
          : this.albumArtPath,
      albumArtistId: data.albumArtistId.present
          ? data.albumArtistId.value
          : this.albumArtistId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('albumArtPath: $albumArtPath, ')
          ..write('albumArtistId: $albumArtistId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, year, albumArtist, albumArtPath, albumArtistId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.title == this.title &&
          other.year == this.year &&
          other.albumArtist == this.albumArtist &&
          other.albumArtPath == this.albumArtPath &&
          other.albumArtistId == this.albumArtistId);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> year;
  final Value<String?> albumArtist;
  final Value<String?> albumArtPath;
  final Value<int?> albumArtistId;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.albumArtPath = const Value.absent(),
    this.albumArtistId = const Value.absent(),
  });
  AlbumsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.year = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.albumArtPath = const Value.absent(),
    this.albumArtistId = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Album> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? year,
    Expression<String>? albumArtist,
    Expression<String>? albumArtPath,
    Expression<int>? albumArtistId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (albumArtPath != null) 'album_art_path': albumArtPath,
      if (albumArtistId != null) 'album_artist_id': albumArtistId,
    });
  }

  AlbumsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? year,
    Value<String?>? albumArtist,
    Value<String?>? albumArtPath,
    Value<int?>? albumArtistId,
  }) {
    return AlbumsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      albumArtist: albumArtist ?? this.albumArtist,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      albumArtistId: albumArtistId ?? this.albumArtistId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (albumArtPath.present) {
      map['album_art_path'] = Variable<String>(albumArtPath.value);
    }
    if (albumArtistId.present) {
      map['album_artist_id'] = Variable<int>(albumArtistId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('albumArtPath: $albumArtPath, ')
          ..write('albumArtistId: $albumArtistId')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _trackTotalMeta = const VerificationMeta(
    'trackTotal',
  );
  @override
  late final GeneratedColumn<int> trackTotal = GeneratedColumn<int>(
    'track_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discTotalMeta = const VerificationMeta(
    'discTotal',
  );
  @override
  late final GeneratedColumn<int> discTotal = GeneratedColumn<int>(
    'disc_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioFingerprintMeta = const VerificationMeta(
    'audioFingerprint',
  );
  @override
  late final GeneratedColumn<Uint8List> audioFingerprint =
      GeneratedColumn<Uint8List>(
        'audio_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isMissingMeta = const VerificationMeta(
    'isMissing',
  );
  @override
  late final GeneratedColumn<bool> isMissing = GeneratedColumn<bool>(
    'is_missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id)',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id)',
    ),
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    trackNumber,
    trackTotal,
    discNumber,
    discTotal,
    durationMs,
    genre,
    fileHash,
    audioFingerprint,
    isMissing,
    filePath,
    fileSize,
    artistId,
    albumId,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('track_total')) {
      context.handle(
        _trackTotalMeta,
        trackTotal.isAcceptableOrUnknown(data['track_total']!, _trackTotalMeta),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('disc_total')) {
      context.handle(
        _discTotalMeta,
        discTotal.isAcceptableOrUnknown(data['disc_total']!, _discTotalMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('audio_fingerprint')) {
      context.handle(
        _audioFingerprintMeta,
        audioFingerprint.isAcceptableOrUnknown(
          data['audio_fingerprint']!,
          _audioFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('is_missing')) {
      context.handle(
        _isMissingMeta,
        isMissing.isAcceptableOrUnknown(data['is_missing']!, _isMissingMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      )!,
      trackTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_total'],
      )!,
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      )!,
      discTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_total'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      audioFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}audio_fingerprint'],
      ),
      isMissing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_missing'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final int id;
  final String title;
  final int trackNumber;
  final int trackTotal;
  final int discNumber;
  final int discTotal;
  final int durationMs;
  final String? genre;

  /// FNV-1a hash.
  final String fileHash;

  /// Chromaprint raw fingerprint stored as binary blob (Uint32List bytes).
  final Uint8List? audioFingerprint;

  /// Soft-delete flag. Flips to true if file vanishes, false if rediscovered.
  final bool isMissing;
  final String filePath;
  final int fileSize;
  final int artistId;
  final int albumId;
  final DateTime dateAdded;
  const Track({
    required this.id,
    required this.title,
    required this.trackNumber,
    required this.trackTotal,
    required this.discNumber,
    required this.discTotal,
    required this.durationMs,
    this.genre,
    required this.fileHash,
    this.audioFingerprint,
    required this.isMissing,
    required this.filePath,
    required this.fileSize,
    required this.artistId,
    required this.albumId,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['track_number'] = Variable<int>(trackNumber);
    map['track_total'] = Variable<int>(trackTotal);
    map['disc_number'] = Variable<int>(discNumber);
    map['disc_total'] = Variable<int>(discTotal);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['file_hash'] = Variable<String>(fileHash);
    if (!nullToAbsent || audioFingerprint != null) {
      map['audio_fingerprint'] = Variable<Uint8List>(audioFingerprint);
    }
    map['is_missing'] = Variable<bool>(isMissing);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['artist_id'] = Variable<int>(artistId);
    map['album_id'] = Variable<int>(albumId);
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      title: Value(title),
      trackNumber: Value(trackNumber),
      trackTotal: Value(trackTotal),
      discNumber: Value(discNumber),
      discTotal: Value(discTotal),
      durationMs: Value(durationMs),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      fileHash: Value(fileHash),
      audioFingerprint: audioFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(audioFingerprint),
      isMissing: Value(isMissing),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      artistId: Value(artistId),
      albumId: Value(albumId),
      dateAdded: Value(dateAdded),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      trackNumber: serializer.fromJson<int>(json['trackNumber']),
      trackTotal: serializer.fromJson<int>(json['trackTotal']),
      discNumber: serializer.fromJson<int>(json['discNumber']),
      discTotal: serializer.fromJson<int>(json['discTotal']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      genre: serializer.fromJson<String?>(json['genre']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      audioFingerprint: serializer.fromJson<Uint8List?>(
        json['audioFingerprint'],
      ),
      isMissing: serializer.fromJson<bool>(json['isMissing']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      artistId: serializer.fromJson<int>(json['artistId']),
      albumId: serializer.fromJson<int>(json['albumId']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'trackNumber': serializer.toJson<int>(trackNumber),
      'trackTotal': serializer.toJson<int>(trackTotal),
      'discNumber': serializer.toJson<int>(discNumber),
      'discTotal': serializer.toJson<int>(discTotal),
      'durationMs': serializer.toJson<int>(durationMs),
      'genre': serializer.toJson<String?>(genre),
      'fileHash': serializer.toJson<String>(fileHash),
      'audioFingerprint': serializer.toJson<Uint8List?>(audioFingerprint),
      'isMissing': serializer.toJson<bool>(isMissing),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'artistId': serializer.toJson<int>(artistId),
      'albumId': serializer.toJson<int>(albumId),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  Track copyWith({
    int? id,
    String? title,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    int? durationMs,
    Value<String?> genre = const Value.absent(),
    String? fileHash,
    Value<Uint8List?> audioFingerprint = const Value.absent(),
    bool? isMissing,
    String? filePath,
    int? fileSize,
    int? artistId,
    int? albumId,
    DateTime? dateAdded,
  }) => Track(
    id: id ?? this.id,
    title: title ?? this.title,
    trackNumber: trackNumber ?? this.trackNumber,
    trackTotal: trackTotal ?? this.trackTotal,
    discNumber: discNumber ?? this.discNumber,
    discTotal: discTotal ?? this.discTotal,
    durationMs: durationMs ?? this.durationMs,
    genre: genre.present ? genre.value : this.genre,
    fileHash: fileHash ?? this.fileHash,
    audioFingerprint: audioFingerprint.present
        ? audioFingerprint.value
        : this.audioFingerprint,
    isMissing: isMissing ?? this.isMissing,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    artistId: artistId ?? this.artistId,
    albumId: albumId ?? this.albumId,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      trackTotal: data.trackTotal.present
          ? data.trackTotal.value
          : this.trackTotal,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      discTotal: data.discTotal.present ? data.discTotal.value : this.discTotal,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      genre: data.genre.present ? data.genre.value : this.genre,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      audioFingerprint: data.audioFingerprint.present
          ? data.audioFingerprint.value
          : this.audioFingerprint,
      isMissing: data.isMissing.present ? data.isMissing.value : this.isMissing,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('trackTotal: $trackTotal, ')
          ..write('discNumber: $discNumber, ')
          ..write('discTotal: $discTotal, ')
          ..write('durationMs: $durationMs, ')
          ..write('genre: $genre, ')
          ..write('fileHash: $fileHash, ')
          ..write('audioFingerprint: $audioFingerprint, ')
          ..write('isMissing: $isMissing, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('artistId: $artistId, ')
          ..write('albumId: $albumId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    trackNumber,
    trackTotal,
    discNumber,
    discTotal,
    durationMs,
    genre,
    fileHash,
    $driftBlobEquality.hash(audioFingerprint),
    isMissing,
    filePath,
    fileSize,
    artistId,
    albumId,
    dateAdded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.title == this.title &&
          other.trackNumber == this.trackNumber &&
          other.trackTotal == this.trackTotal &&
          other.discNumber == this.discNumber &&
          other.discTotal == this.discTotal &&
          other.durationMs == this.durationMs &&
          other.genre == this.genre &&
          other.fileHash == this.fileHash &&
          $driftBlobEquality.equals(
            other.audioFingerprint,
            this.audioFingerprint,
          ) &&
          other.isMissing == this.isMissing &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.artistId == this.artistId &&
          other.albumId == this.albumId &&
          other.dateAdded == this.dateAdded);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> trackNumber;
  final Value<int> trackTotal;
  final Value<int> discNumber;
  final Value<int> discTotal;
  final Value<int> durationMs;
  final Value<String?> genre;
  final Value<String> fileHash;
  final Value<Uint8List?> audioFingerprint;
  final Value<bool> isMissing;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<int> artistId;
  final Value<int> albumId;
  final Value<DateTime> dateAdded;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.trackTotal = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.discTotal = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.genre = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.audioFingerprint = const Value.absent(),
    this.isMissing = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.artistId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.trackNumber = const Value.absent(),
    this.trackTotal = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.discTotal = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.genre = const Value.absent(),
    required String fileHash,
    this.audioFingerprint = const Value.absent(),
    this.isMissing = const Value.absent(),
    required String filePath,
    this.fileSize = const Value.absent(),
    required int artistId,
    required int albumId,
    this.dateAdded = const Value.absent(),
  }) : title = Value(title),
       fileHash = Value(fileHash),
       filePath = Value(filePath),
       artistId = Value(artistId),
       albumId = Value(albumId);
  static Insertable<Track> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? trackNumber,
    Expression<int>? trackTotal,
    Expression<int>? discNumber,
    Expression<int>? discTotal,
    Expression<int>? durationMs,
    Expression<String>? genre,
    Expression<String>? fileHash,
    Expression<Uint8List>? audioFingerprint,
    Expression<bool>? isMissing,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<int>? artistId,
    Expression<int>? albumId,
    Expression<DateTime>? dateAdded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (trackNumber != null) 'track_number': trackNumber,
      if (trackTotal != null) 'track_total': trackTotal,
      if (discNumber != null) 'disc_number': discNumber,
      if (discTotal != null) 'disc_total': discTotal,
      if (durationMs != null) 'duration_ms': durationMs,
      if (genre != null) 'genre': genre,
      if (fileHash != null) 'file_hash': fileHash,
      if (audioFingerprint != null) 'audio_fingerprint': audioFingerprint,
      if (isMissing != null) 'is_missing': isMissing,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (artistId != null) 'artist_id': artistId,
      if (albumId != null) 'album_id': albumId,
      if (dateAdded != null) 'date_added': dateAdded,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? trackNumber,
    Value<int>? trackTotal,
    Value<int>? discNumber,
    Value<int>? discTotal,
    Value<int>? durationMs,
    Value<String?>? genre,
    Value<String>? fileHash,
    Value<Uint8List?>? audioFingerprint,
    Value<bool>? isMissing,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<int>? artistId,
    Value<int>? albumId,
    Value<DateTime>? dateAdded,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      trackNumber: trackNumber ?? this.trackNumber,
      trackTotal: trackTotal ?? this.trackTotal,
      discNumber: discNumber ?? this.discNumber,
      discTotal: discTotal ?? this.discTotal,
      durationMs: durationMs ?? this.durationMs,
      genre: genre ?? this.genre,
      fileHash: fileHash ?? this.fileHash,
      audioFingerprint: audioFingerprint ?? this.audioFingerprint,
      isMissing: isMissing ?? this.isMissing,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (trackTotal.present) {
      map['track_total'] = Variable<int>(trackTotal.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (discTotal.present) {
      map['disc_total'] = Variable<int>(discTotal.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (audioFingerprint.present) {
      map['audio_fingerprint'] = Variable<Uint8List>(audioFingerprint.value);
    }
    if (isMissing.present) {
      map['is_missing'] = Variable<bool>(isMissing.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('trackTotal: $trackTotal, ')
          ..write('discNumber: $discNumber, ')
          ..write('discTotal: $discTotal, ')
          ..write('durationMs: $durationMs, ')
          ..write('genre: $genre, ')
          ..write('fileHash: $fileHash, ')
          ..write('audioFingerprint: $audioFingerprint, ')
          ..write('isMissing: $isMissing, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('artistId: $artistId, ')
          ..write('albumId: $albumId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, coverPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistData extends DataClass implements Insertable<PlaylistData> {
  final int id;
  final String name;
  final String? coverPath;
  const PlaylistData({required this.id, required this.name, this.coverPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
    );
  }

  factory PlaylistData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'coverPath': serializer.toJson<String?>(coverPath),
    };
  }

  PlaylistData copyWith({
    int? id,
    String? name,
    Value<String?> coverPath = const Value.absent(),
  }) => PlaylistData(
    id: id ?? this.id,
    name: name ?? this.name,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
  );
  PlaylistData copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPath: $coverPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, coverPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistData &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverPath == this.coverPath);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> coverPath;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverPath = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.coverPath = const Value.absent(),
  }) : name = Value(name);
  static Insertable<PlaylistData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? coverPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverPath != null) 'cover_path': coverPath,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? coverPath,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPath: $coverPath')
          ..write(')'))
        .toString();
  }
}

class $TrackArtistTable extends TrackArtist
    with TableInfo<$TrackArtistTable, TrackArtistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackArtistTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, artistId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_artist';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackArtistData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, artistId};
  @override
  TrackArtistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackArtistData(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      )!,
    );
  }

  @override
  $TrackArtistTable createAlias(String alias) {
    return $TrackArtistTable(attachedDatabase, alias);
  }
}

class TrackArtistData extends DataClass implements Insertable<TrackArtistData> {
  final int trackId;
  final int artistId;
  const TrackArtistData({required this.trackId, required this.artistId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['artist_id'] = Variable<int>(artistId);
    return map;
  }

  TrackArtistCompanion toCompanion(bool nullToAbsent) {
    return TrackArtistCompanion(
      trackId: Value(trackId),
      artistId: Value(artistId),
    );
  }

  factory TrackArtistData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackArtistData(
      trackId: serializer.fromJson<int>(json['trackId']),
      artistId: serializer.fromJson<int>(json['artistId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'artistId': serializer.toJson<int>(artistId),
    };
  }

  TrackArtistData copyWith({int? trackId, int? artistId}) => TrackArtistData(
    trackId: trackId ?? this.trackId,
    artistId: artistId ?? this.artistId,
  );
  TrackArtistData copyWithCompanion(TrackArtistCompanion data) {
    return TrackArtistData(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackArtistData(')
          ..write('trackId: $trackId, ')
          ..write('artistId: $artistId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, artistId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackArtistData &&
          other.trackId == this.trackId &&
          other.artistId == this.artistId);
}

class TrackArtistCompanion extends UpdateCompanion<TrackArtistData> {
  final Value<int> trackId;
  final Value<int> artistId;
  final Value<int> rowid;
  const TrackArtistCompanion({
    this.trackId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackArtistCompanion.insert({
    required int trackId,
    required int artistId,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       artistId = Value(artistId);
  static Insertable<TrackArtistData> custom({
    Expression<int>? trackId,
    Expression<int>? artistId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (artistId != null) 'artist_id': artistId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackArtistCompanion copyWith({
    Value<int>? trackId,
    Value<int>? artistId,
    Value<int>? rowid,
  }) {
    return TrackArtistCompanion(
      trackId: trackId ?? this.trackId,
      artistId: artistId ?? this.artistId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackArtistCompanion(')
          ..write('trackId: $trackId, ')
          ..write('artistId: $artistId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTrackTable extends PlaylistTrack
    with TableInfo<$PlaylistTrackTable, PlaylistTrackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTrackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, trackId, dateAdded];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_track';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrackData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  PlaylistTrackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrackData(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $PlaylistTrackTable createAlias(String alias) {
    return $PlaylistTrackTable(attachedDatabase, alias);
  }
}

class PlaylistTrackData extends DataClass
    implements Insertable<PlaylistTrackData> {
  final int playlistId;
  final int trackId;
  final DateTime dateAdded;
  const PlaylistTrackData({
    required this.playlistId,
    required this.trackId,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['track_id'] = Variable<int>(trackId);
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  PlaylistTrackCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTrackCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      dateAdded: Value(dateAdded),
    );
  }

  factory PlaylistTrackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrackData(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      trackId: serializer.fromJson<int>(json['trackId']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'trackId': serializer.toJson<int>(trackId),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  PlaylistTrackData copyWith({
    int? playlistId,
    int? trackId,
    DateTime? dateAdded,
  }) => PlaylistTrackData(
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  PlaylistTrackData copyWithCompanion(PlaylistTrackCompanion data) {
    return PlaylistTrackData(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrackData(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackId, dateAdded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrackData &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.dateAdded == this.dateAdded);
}

class PlaylistTrackCompanion extends UpdateCompanion<PlaylistTrackData> {
  final Value<int> playlistId;
  final Value<int> trackId;
  final Value<DateTime> dateAdded;
  final Value<int> rowid;
  const PlaylistTrackCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTrackCompanion.insert({
    required int playlistId,
    required int trackId,
    this.dateAdded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId);
  static Insertable<PlaylistTrackData> custom({
    Expression<int>? playlistId,
    Expression<int>? trackId,
    Expression<DateTime>? dateAdded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (dateAdded != null) 'date_added': dateAdded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTrackCompanion copyWith({
    Value<int>? playlistId,
    Value<int>? trackId,
    Value<DateTime>? dateAdded,
    Value<int>? rowid,
  }) {
    return PlaylistTrackCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      dateAdded: dateAdded ?? this.dateAdded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrackCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueEntriesTable extends QueueEntries
    with TableInfo<$QueueEntriesTable, QueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _originalQueueIndexMeta =
      const VerificationMeta('originalQueueIndex');
  @override
  late final GeneratedColumn<int> originalQueueIndex = GeneratedColumn<int>(
    'original_queue_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id)',
    ),
  );
  static const VerificationMeta _isCurrentlyPlayingMeta =
      const VerificationMeta('isCurrentlyPlaying');
  @override
  late final GeneratedColumn<bool> isCurrentlyPlaying = GeneratedColumn<bool>(
    'is_currently_playing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_currently_playing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _resumePositionMsMeta = const VerificationMeta(
    'resumePositionMs',
  );
  @override
  late final GeneratedColumn<int> resumePositionMs = GeneratedColumn<int>(
    'resume_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playbackContextTypeMeta =
      const VerificationMeta('playbackContextType');
  @override
  late final GeneratedColumn<String> playbackContextType =
      GeneratedColumn<String>(
        'playback_context_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _playbackContextIdMeta = const VerificationMeta(
    'playbackContextId',
  );
  @override
  late final GeneratedColumn<int> playbackContextId = GeneratedColumn<int>(
    'playback_context_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    originalQueueIndex,
    trackId,
    isCurrentlyPlaying,
    resumePositionMs,
    playbackContextType,
    playbackContextId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('original_queue_index')) {
      context.handle(
        _originalQueueIndexMeta,
        originalQueueIndex.isAcceptableOrUnknown(
          data['original_queue_index']!,
          _originalQueueIndexMeta,
        ),
      );
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('is_currently_playing')) {
      context.handle(
        _isCurrentlyPlayingMeta,
        isCurrentlyPlaying.isAcceptableOrUnknown(
          data['is_currently_playing']!,
          _isCurrentlyPlayingMeta,
        ),
      );
    }
    if (data.containsKey('resume_position_ms')) {
      context.handle(
        _resumePositionMsMeta,
        resumePositionMs.isAcceptableOrUnknown(
          data['resume_position_ms']!,
          _resumePositionMsMeta,
        ),
      );
    }
    if (data.containsKey('playback_context_type')) {
      context.handle(
        _playbackContextTypeMeta,
        playbackContextType.isAcceptableOrUnknown(
          data['playback_context_type']!,
          _playbackContextTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playbackContextTypeMeta);
    }
    if (data.containsKey('playback_context_id')) {
      context.handle(
        _playbackContextIdMeta,
        playbackContextId.isAcceptableOrUnknown(
          data['playback_context_id']!,
          _playbackContextIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {originalQueueIndex};
  @override
  QueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueEntry(
      originalQueueIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_queue_index'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      isCurrentlyPlaying: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_currently_playing'],
      )!,
      resumePositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resume_position_ms'],
      )!,
      playbackContextType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playback_context_type'],
      )!,
      playbackContextId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_context_id'],
      ),
    );
  }

  @override
  $QueueEntriesTable createAlias(String alias) {
    return $QueueEntriesTable(attachedDatabase, alias);
  }
}

class QueueEntry extends DataClass implements Insertable<QueueEntry> {
  /// The pure, unshuffled position of the track in the original list.
  /// Fall back to this when the user clicks "Unshuffle".
  final int originalQueueIndex;

  /// Foreign key linking to the `Tracks` metadata table.
  final int trackId;

  /// Flags the single track that was actively playing when the app was last closed.
  final bool isCurrentlyPlaying;

  /// The exact timestamp (in milliseconds) to resume playback from on the active track.
  final int resumePositionMs;

  /// The origin of the queue (i.e. 'album', 'playlist', 'all_tracks').
  final String playbackContextType;

  /// The specific database ID of the origin (i.e. Playlist ID 5, Album ID 77).
  /// Nullable because all_tracks don't have id
  final int? playbackContextId;
  const QueueEntry({
    required this.originalQueueIndex,
    required this.trackId,
    required this.isCurrentlyPlaying,
    required this.resumePositionMs,
    required this.playbackContextType,
    this.playbackContextId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['original_queue_index'] = Variable<int>(originalQueueIndex);
    map['track_id'] = Variable<int>(trackId);
    map['is_currently_playing'] = Variable<bool>(isCurrentlyPlaying);
    map['resume_position_ms'] = Variable<int>(resumePositionMs);
    map['playback_context_type'] = Variable<String>(playbackContextType);
    if (!nullToAbsent || playbackContextId != null) {
      map['playback_context_id'] = Variable<int>(playbackContextId);
    }
    return map;
  }

  QueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return QueueEntriesCompanion(
      originalQueueIndex: Value(originalQueueIndex),
      trackId: Value(trackId),
      isCurrentlyPlaying: Value(isCurrentlyPlaying),
      resumePositionMs: Value(resumePositionMs),
      playbackContextType: Value(playbackContextType),
      playbackContextId: playbackContextId == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackContextId),
    );
  }

  factory QueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueEntry(
      originalQueueIndex: serializer.fromJson<int>(json['originalQueueIndex']),
      trackId: serializer.fromJson<int>(json['trackId']),
      isCurrentlyPlaying: serializer.fromJson<bool>(json['isCurrentlyPlaying']),
      resumePositionMs: serializer.fromJson<int>(json['resumePositionMs']),
      playbackContextType: serializer.fromJson<String>(
        json['playbackContextType'],
      ),
      playbackContextId: serializer.fromJson<int?>(json['playbackContextId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'originalQueueIndex': serializer.toJson<int>(originalQueueIndex),
      'trackId': serializer.toJson<int>(trackId),
      'isCurrentlyPlaying': serializer.toJson<bool>(isCurrentlyPlaying),
      'resumePositionMs': serializer.toJson<int>(resumePositionMs),
      'playbackContextType': serializer.toJson<String>(playbackContextType),
      'playbackContextId': serializer.toJson<int?>(playbackContextId),
    };
  }

  QueueEntry copyWith({
    int? originalQueueIndex,
    int? trackId,
    bool? isCurrentlyPlaying,
    int? resumePositionMs,
    String? playbackContextType,
    Value<int?> playbackContextId = const Value.absent(),
  }) => QueueEntry(
    originalQueueIndex: originalQueueIndex ?? this.originalQueueIndex,
    trackId: trackId ?? this.trackId,
    isCurrentlyPlaying: isCurrentlyPlaying ?? this.isCurrentlyPlaying,
    resumePositionMs: resumePositionMs ?? this.resumePositionMs,
    playbackContextType: playbackContextType ?? this.playbackContextType,
    playbackContextId: playbackContextId.present
        ? playbackContextId.value
        : this.playbackContextId,
  );
  QueueEntry copyWithCompanion(QueueEntriesCompanion data) {
    return QueueEntry(
      originalQueueIndex: data.originalQueueIndex.present
          ? data.originalQueueIndex.value
          : this.originalQueueIndex,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      isCurrentlyPlaying: data.isCurrentlyPlaying.present
          ? data.isCurrentlyPlaying.value
          : this.isCurrentlyPlaying,
      resumePositionMs: data.resumePositionMs.present
          ? data.resumePositionMs.value
          : this.resumePositionMs,
      playbackContextType: data.playbackContextType.present
          ? data.playbackContextType.value
          : this.playbackContextType,
      playbackContextId: data.playbackContextId.present
          ? data.playbackContextId.value
          : this.playbackContextId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntry(')
          ..write('originalQueueIndex: $originalQueueIndex, ')
          ..write('trackId: $trackId, ')
          ..write('isCurrentlyPlaying: $isCurrentlyPlaying, ')
          ..write('resumePositionMs: $resumePositionMs, ')
          ..write('playbackContextType: $playbackContextType, ')
          ..write('playbackContextId: $playbackContextId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    originalQueueIndex,
    trackId,
    isCurrentlyPlaying,
    resumePositionMs,
    playbackContextType,
    playbackContextId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueEntry &&
          other.originalQueueIndex == this.originalQueueIndex &&
          other.trackId == this.trackId &&
          other.isCurrentlyPlaying == this.isCurrentlyPlaying &&
          other.resumePositionMs == this.resumePositionMs &&
          other.playbackContextType == this.playbackContextType &&
          other.playbackContextId == this.playbackContextId);
}

class QueueEntriesCompanion extends UpdateCompanion<QueueEntry> {
  final Value<int> originalQueueIndex;
  final Value<int> trackId;
  final Value<bool> isCurrentlyPlaying;
  final Value<int> resumePositionMs;
  final Value<String> playbackContextType;
  final Value<int?> playbackContextId;
  const QueueEntriesCompanion({
    this.originalQueueIndex = const Value.absent(),
    this.trackId = const Value.absent(),
    this.isCurrentlyPlaying = const Value.absent(),
    this.resumePositionMs = const Value.absent(),
    this.playbackContextType = const Value.absent(),
    this.playbackContextId = const Value.absent(),
  });
  QueueEntriesCompanion.insert({
    this.originalQueueIndex = const Value.absent(),
    required int trackId,
    this.isCurrentlyPlaying = const Value.absent(),
    this.resumePositionMs = const Value.absent(),
    required String playbackContextType,
    this.playbackContextId = const Value.absent(),
  }) : trackId = Value(trackId),
       playbackContextType = Value(playbackContextType);
  static Insertable<QueueEntry> custom({
    Expression<int>? originalQueueIndex,
    Expression<int>? trackId,
    Expression<bool>? isCurrentlyPlaying,
    Expression<int>? resumePositionMs,
    Expression<String>? playbackContextType,
    Expression<int>? playbackContextId,
  }) {
    return RawValuesInsertable({
      if (originalQueueIndex != null)
        'original_queue_index': originalQueueIndex,
      if (trackId != null) 'track_id': trackId,
      if (isCurrentlyPlaying != null)
        'is_currently_playing': isCurrentlyPlaying,
      if (resumePositionMs != null) 'resume_position_ms': resumePositionMs,
      if (playbackContextType != null)
        'playback_context_type': playbackContextType,
      if (playbackContextId != null) 'playback_context_id': playbackContextId,
    });
  }

  QueueEntriesCompanion copyWith({
    Value<int>? originalQueueIndex,
    Value<int>? trackId,
    Value<bool>? isCurrentlyPlaying,
    Value<int>? resumePositionMs,
    Value<String>? playbackContextType,
    Value<int?>? playbackContextId,
  }) {
    return QueueEntriesCompanion(
      originalQueueIndex: originalQueueIndex ?? this.originalQueueIndex,
      trackId: trackId ?? this.trackId,
      isCurrentlyPlaying: isCurrentlyPlaying ?? this.isCurrentlyPlaying,
      resumePositionMs: resumePositionMs ?? this.resumePositionMs,
      playbackContextType: playbackContextType ?? this.playbackContextType,
      playbackContextId: playbackContextId ?? this.playbackContextId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (originalQueueIndex.present) {
      map['original_queue_index'] = Variable<int>(originalQueueIndex.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (isCurrentlyPlaying.present) {
      map['is_currently_playing'] = Variable<bool>(isCurrentlyPlaying.value);
    }
    if (resumePositionMs.present) {
      map['resume_position_ms'] = Variable<int>(resumePositionMs.value);
    }
    if (playbackContextType.present) {
      map['playback_context_type'] = Variable<String>(
        playbackContextType.value,
      );
    }
    if (playbackContextId.present) {
      map['playback_context_id'] = Variable<int>(playbackContextId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntriesCompanion(')
          ..write('originalQueueIndex: $originalQueueIndex, ')
          ..write('trackId: $trackId, ')
          ..write('isCurrentlyPlaying: $isCurrentlyPlaying, ')
          ..write('resumePositionMs: $resumePositionMs, ')
          ..write('playbackContextType: $playbackContextType, ')
          ..write('playbackContextId: $playbackContextId')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, PlayHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _durationListenedMsMeta =
      const VerificationMeta('durationListenedMs');
  @override
  late final GeneratedColumn<int> durationListenedMs = GeneratedColumn<int>(
    'duration_listened_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSkippedMeta = const VerificationMeta(
    'isSkipped',
  );
  @override
  late final GeneratedColumn<bool> isSkipped = GeneratedColumn<bool>(
    'is_skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _playbackContextTypeMeta =
      const VerificationMeta('playbackContextType');
  @override
  late final GeneratedColumn<String> playbackContextType =
      GeneratedColumn<String>(
        'playback_context_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _playbackContextIdMeta = const VerificationMeta(
    'playbackContextId',
  );
  @override
  late final GeneratedColumn<int> playbackContextId = GeneratedColumn<int>(
    'playback_context_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    startedAt,
    durationListenedMs,
    isSkipped,
    playbackContextType,
    playbackContextId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('duration_listened_ms')) {
      context.handle(
        _durationListenedMsMeta,
        durationListenedMs.isAcceptableOrUnknown(
          data['duration_listened_ms']!,
          _durationListenedMsMeta,
        ),
      );
    }
    if (data.containsKey('is_skipped')) {
      context.handle(
        _isSkippedMeta,
        isSkipped.isAcceptableOrUnknown(data['is_skipped']!, _isSkippedMeta),
      );
    }
    if (data.containsKey('playback_context_type')) {
      context.handle(
        _playbackContextTypeMeta,
        playbackContextType.isAcceptableOrUnknown(
          data['playback_context_type']!,
          _playbackContextTypeMeta,
        ),
      );
    }
    if (data.containsKey('playback_context_id')) {
      context.handle(
        _playbackContextIdMeta,
        playbackContextId.isAcceptableOrUnknown(
          data['playback_context_id']!,
          _playbackContextIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationListenedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_listened_ms'],
      )!,
      isSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_skipped'],
      )!,
      playbackContextType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playback_context_type'],
      ),
      playbackContextId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_context_id'],
      ),
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class PlayHistoryData extends DataClass implements Insertable<PlayHistoryData> {
  final int id;
  final int trackId;
  final DateTime startedAt;
  final int durationListenedMs;
  final bool isSkipped;

  /// The origin of the queue (i.e. 'album', 'playlist', 'all_tracks').
  final String? playbackContextType;

  /// The specific database ID of the origin (i.e. Playlist ID 5, Album ID 77).
  /// Nullable because all_tracks don't have id
  final int? playbackContextId;
  const PlayHistoryData({
    required this.id,
    required this.trackId,
    required this.startedAt,
    required this.durationListenedMs,
    required this.isSkipped,
    this.playbackContextType,
    this.playbackContextId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_listened_ms'] = Variable<int>(durationListenedMs);
    map['is_skipped'] = Variable<bool>(isSkipped);
    if (!nullToAbsent || playbackContextType != null) {
      map['playback_context_type'] = Variable<String>(playbackContextType);
    }
    if (!nullToAbsent || playbackContextId != null) {
      map['playback_context_id'] = Variable<int>(playbackContextId);
    }
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      trackId: Value(trackId),
      startedAt: Value(startedAt),
      durationListenedMs: Value(durationListenedMs),
      isSkipped: Value(isSkipped),
      playbackContextType: playbackContextType == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackContextType),
      playbackContextId: playbackContextId == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackContextId),
    );
  }

  factory PlayHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryData(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationListenedMs: serializer.fromJson<int>(json['durationListenedMs']),
      isSkipped: serializer.fromJson<bool>(json['isSkipped']),
      playbackContextType: serializer.fromJson<String?>(
        json['playbackContextType'],
      ),
      playbackContextId: serializer.fromJson<int?>(json['playbackContextId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationListenedMs': serializer.toJson<int>(durationListenedMs),
      'isSkipped': serializer.toJson<bool>(isSkipped),
      'playbackContextType': serializer.toJson<String?>(playbackContextType),
      'playbackContextId': serializer.toJson<int?>(playbackContextId),
    };
  }

  PlayHistoryData copyWith({
    int? id,
    int? trackId,
    DateTime? startedAt,
    int? durationListenedMs,
    bool? isSkipped,
    Value<String?> playbackContextType = const Value.absent(),
    Value<int?> playbackContextId = const Value.absent(),
  }) => PlayHistoryData(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    startedAt: startedAt ?? this.startedAt,
    durationListenedMs: durationListenedMs ?? this.durationListenedMs,
    isSkipped: isSkipped ?? this.isSkipped,
    playbackContextType: playbackContextType.present
        ? playbackContextType.value
        : this.playbackContextType,
    playbackContextId: playbackContextId.present
        ? playbackContextId.value
        : this.playbackContextId,
  );
  PlayHistoryData copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryData(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationListenedMs: data.durationListenedMs.present
          ? data.durationListenedMs.value
          : this.durationListenedMs,
      isSkipped: data.isSkipped.present ? data.isSkipped.value : this.isSkipped,
      playbackContextType: data.playbackContextType.present
          ? data.playbackContextType.value
          : this.playbackContextType,
      playbackContextId: data.playbackContextId.present
          ? data.playbackContextId.value
          : this.playbackContextId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryData(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationListenedMs: $durationListenedMs, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('playbackContextType: $playbackContextType, ')
          ..write('playbackContextId: $playbackContextId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackId,
    startedAt,
    durationListenedMs,
    isSkipped,
    playbackContextType,
    playbackContextId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryData &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.startedAt == this.startedAt &&
          other.durationListenedMs == this.durationListenedMs &&
          other.isSkipped == this.isSkipped &&
          other.playbackContextType == this.playbackContextType &&
          other.playbackContextId == this.playbackContextId);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryData> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<DateTime> startedAt;
  final Value<int> durationListenedMs;
  final Value<bool> isSkipped;
  final Value<String?> playbackContextType;
  final Value<int?> playbackContextId;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationListenedMs = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.playbackContextType = const Value.absent(),
    this.playbackContextId = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    this.startedAt = const Value.absent(),
    this.durationListenedMs = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.playbackContextType = const Value.absent(),
    this.playbackContextId = const Value.absent(),
  }) : trackId = Value(trackId);
  static Insertable<PlayHistoryData> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<DateTime>? startedAt,
    Expression<int>? durationListenedMs,
    Expression<bool>? isSkipped,
    Expression<String>? playbackContextType,
    Expression<int>? playbackContextId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (startedAt != null) 'started_at': startedAt,
      if (durationListenedMs != null)
        'duration_listened_ms': durationListenedMs,
      if (isSkipped != null) 'is_skipped': isSkipped,
      if (playbackContextType != null)
        'playback_context_type': playbackContextType,
      if (playbackContextId != null) 'playback_context_id': playbackContextId,
    });
  }

  PlayHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<DateTime>? startedAt,
    Value<int>? durationListenedMs,
    Value<bool>? isSkipped,
    Value<String?>? playbackContextType,
    Value<int?>? playbackContextId,
  }) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      startedAt: startedAt ?? this.startedAt,
      durationListenedMs: durationListenedMs ?? this.durationListenedMs,
      isSkipped: isSkipped ?? this.isSkipped,
      playbackContextType: playbackContextType ?? this.playbackContextType,
      playbackContextId: playbackContextId ?? this.playbackContextId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationListenedMs.present) {
      map['duration_listened_ms'] = Variable<int>(durationListenedMs.value);
    }
    if (isSkipped.present) {
      map['is_skipped'] = Variable<bool>(isSkipped.value);
    }
    if (playbackContextType.present) {
      map['playback_context_type'] = Variable<String>(
        playbackContextType.value,
      );
    }
    if (playbackContextId.present) {
      map['playback_context_id'] = Variable<int>(playbackContextId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationListenedMs: $durationListenedMs, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('playbackContextType: $playbackContextType, ')
          ..write('playbackContextId: $playbackContextId')
          ..write(')'))
        .toString();
  }
}

class $SourcePrioritiesTable extends SourcePriorities
    with TableInfo<$SourcePrioritiesTable, SourcePriority> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcePrioritiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityRankMeta = const VerificationMeta(
    'priorityRank',
  );
  @override
  late final GeneratedColumn<int> priorityRank = GeneratedColumn<int>(
    'priority_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [source, priorityRank];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_priorities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourcePriority> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('priority_rank')) {
      context.handle(
        _priorityRankMeta,
        priorityRank.isAcceptableOrUnknown(
          data['priority_rank']!,
          _priorityRankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priorityRankMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source};
  @override
  SourcePriority map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourcePriority(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      priorityRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority_rank'],
      )!,
    );
  }

  @override
  $SourcePrioritiesTable createAlias(String alias) {
    return $SourcePrioritiesTable(attachedDatabase, alias);
  }
}

class SourcePriority extends DataClass implements Insertable<SourcePriority> {
  final String source;
  final int priorityRank;
  const SourcePriority({required this.source, required this.priorityRank});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['priority_rank'] = Variable<int>(priorityRank);
    return map;
  }

  SourcePrioritiesCompanion toCompanion(bool nullToAbsent) {
    return SourcePrioritiesCompanion(
      source: Value(source),
      priorityRank: Value(priorityRank),
    );
  }

  factory SourcePriority.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourcePriority(
      source: serializer.fromJson<String>(json['source']),
      priorityRank: serializer.fromJson<int>(json['priorityRank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'priorityRank': serializer.toJson<int>(priorityRank),
    };
  }

  SourcePriority copyWith({String? source, int? priorityRank}) =>
      SourcePriority(
        source: source ?? this.source,
        priorityRank: priorityRank ?? this.priorityRank,
      );
  SourcePriority copyWithCompanion(SourcePrioritiesCompanion data) {
    return SourcePriority(
      source: data.source.present ? data.source.value : this.source,
      priorityRank: data.priorityRank.present
          ? data.priorityRank.value
          : this.priorityRank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourcePriority(')
          ..write('source: $source, ')
          ..write('priorityRank: $priorityRank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, priorityRank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourcePriority &&
          other.source == this.source &&
          other.priorityRank == this.priorityRank);
}

class SourcePrioritiesCompanion extends UpdateCompanion<SourcePriority> {
  final Value<String> source;
  final Value<int> priorityRank;
  final Value<int> rowid;
  const SourcePrioritiesCompanion({
    this.source = const Value.absent(),
    this.priorityRank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcePrioritiesCompanion.insert({
    required String source,
    required int priorityRank,
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       priorityRank = Value(priorityRank);
  static Insertable<SourcePriority> custom({
    Expression<String>? source,
    Expression<int>? priorityRank,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (priorityRank != null) 'priority_rank': priorityRank,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcePrioritiesCompanion copyWith({
    Value<String>? source,
    Value<int>? priorityRank,
    Value<int>? rowid,
  }) {
    return SourcePrioritiesCompanion(
      source: source ?? this.source,
      priorityRank: priorityRank ?? this.priorityRank,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (priorityRank.present) {
      map['priority_rank'] = Variable<int>(priorityRank.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcePrioritiesCompanion(')
          ..write('source: $source, ')
          ..write('priorityRank: $priorityRank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArtistMetadataTable extends ArtistMetadata
    with TableInfo<$ArtistMetadataTable, ArtistMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _biographyMeta = const VerificationMeta(
    'biography',
  );
  @override
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
    'biography',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalUrlMeta = const VerificationMeta(
    'externalUrl',
  );
  @override
  late final GeneratedColumn<String> externalUrl = GeneratedColumn<String>(
    'external_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFetchedMeta = const VerificationMeta(
    'lastFetched',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetched = GeneratedColumn<DateTime>(
    'last_fetched',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isUserSelectedMeta = const VerificationMeta(
    'isUserSelected',
  );
  @override
  late final GeneratedColumn<bool> isUserSelected = GeneratedColumn<bool>(
    'is_user_selected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_selected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    artistId,
    source,
    imageUrl,
    localPath,
    biography,
    externalUrl,
    lastFetched,
    isUserSelected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artist_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtistMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('biography')) {
      context.handle(
        _biographyMeta,
        biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta),
      );
    }
    if (data.containsKey('external_url')) {
      context.handle(
        _externalUrlMeta,
        externalUrl.isAcceptableOrUnknown(
          data['external_url']!,
          _externalUrlMeta,
        ),
      );
    }
    if (data.containsKey('last_fetched')) {
      context.handle(
        _lastFetchedMeta,
        lastFetched.isAcceptableOrUnknown(
          data['last_fetched']!,
          _lastFetchedMeta,
        ),
      );
    }
    if (data.containsKey('is_user_selected')) {
      context.handle(
        _isUserSelectedMeta,
        isUserSelected.isAcceptableOrUnknown(
          data['is_user_selected']!,
          _isUserSelectedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {artistId, source},
  ];
  @override
  ArtistMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      biography: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}biography'],
      ),
      externalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_url'],
      ),
      lastFetched: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched'],
      )!,
      isUserSelected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_selected'],
      )!,
    );
  }

  @override
  $ArtistMetadataTable createAlias(String alias) {
    return $ArtistMetadataTable(attachedDatabase, alias);
  }
}

class ArtistMetadataData extends DataClass
    implements Insertable<ArtistMetadataData> {
  final int id;
  final int artistId;

  /// The provider type: 'spotify', 'deezer', 'custom', etc.
  final String source;

  /// Remote image URL string
  final String? imageUrl;

  /// Relative local path for offline image caches
  final String? localPath;
  final String? biography;
  final String? externalUrl;
  final DateTime lastFetched;

  /// True if the user manually pinned this provider's image/bio as active
  final bool isUserSelected;
  const ArtistMetadataData({
    required this.id,
    required this.artistId,
    required this.source,
    this.imageUrl,
    this.localPath,
    this.biography,
    this.externalUrl,
    required this.lastFetched,
    required this.isUserSelected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['artist_id'] = Variable<int>(artistId);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String>(biography);
    }
    if (!nullToAbsent || externalUrl != null) {
      map['external_url'] = Variable<String>(externalUrl);
    }
    map['last_fetched'] = Variable<DateTime>(lastFetched);
    map['is_user_selected'] = Variable<bool>(isUserSelected);
    return map;
  }

  ArtistMetadataCompanion toCompanion(bool nullToAbsent) {
    return ArtistMetadataCompanion(
      id: Value(id),
      artistId: Value(artistId),
      source: Value(source),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      biography: biography == null && nullToAbsent
          ? const Value.absent()
          : Value(biography),
      externalUrl: externalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(externalUrl),
      lastFetched: Value(lastFetched),
      isUserSelected: Value(isUserSelected),
    );
  }

  factory ArtistMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistMetadataData(
      id: serializer.fromJson<int>(json['id']),
      artistId: serializer.fromJson<int>(json['artistId']),
      source: serializer.fromJson<String>(json['source']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      biography: serializer.fromJson<String?>(json['biography']),
      externalUrl: serializer.fromJson<String?>(json['externalUrl']),
      lastFetched: serializer.fromJson<DateTime>(json['lastFetched']),
      isUserSelected: serializer.fromJson<bool>(json['isUserSelected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'artistId': serializer.toJson<int>(artistId),
      'source': serializer.toJson<String>(source),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'localPath': serializer.toJson<String?>(localPath),
      'biography': serializer.toJson<String?>(biography),
      'externalUrl': serializer.toJson<String?>(externalUrl),
      'lastFetched': serializer.toJson<DateTime>(lastFetched),
      'isUserSelected': serializer.toJson<bool>(isUserSelected),
    };
  }

  ArtistMetadataData copyWith({
    int? id,
    int? artistId,
    String? source,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> biography = const Value.absent(),
    Value<String?> externalUrl = const Value.absent(),
    DateTime? lastFetched,
    bool? isUserSelected,
  }) => ArtistMetadataData(
    id: id ?? this.id,
    artistId: artistId ?? this.artistId,
    source: source ?? this.source,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    localPath: localPath.present ? localPath.value : this.localPath,
    biography: biography.present ? biography.value : this.biography,
    externalUrl: externalUrl.present ? externalUrl.value : this.externalUrl,
    lastFetched: lastFetched ?? this.lastFetched,
    isUserSelected: isUserSelected ?? this.isUserSelected,
  );
  ArtistMetadataData copyWithCompanion(ArtistMetadataCompanion data) {
    return ArtistMetadataData(
      id: data.id.present ? data.id.value : this.id,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      source: data.source.present ? data.source.value : this.source,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      biography: data.biography.present ? data.biography.value : this.biography,
      externalUrl: data.externalUrl.present
          ? data.externalUrl.value
          : this.externalUrl,
      lastFetched: data.lastFetched.present
          ? data.lastFetched.value
          : this.lastFetched,
      isUserSelected: data.isUserSelected.present
          ? data.isUserSelected.value
          : this.isUserSelected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistMetadataData(')
          ..write('id: $id, ')
          ..write('artistId: $artistId, ')
          ..write('source: $source, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localPath: $localPath, ')
          ..write('biography: $biography, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('isUserSelected: $isUserSelected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    artistId,
    source,
    imageUrl,
    localPath,
    biography,
    externalUrl,
    lastFetched,
    isUserSelected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistMetadataData &&
          other.id == this.id &&
          other.artistId == this.artistId &&
          other.source == this.source &&
          other.imageUrl == this.imageUrl &&
          other.localPath == this.localPath &&
          other.biography == this.biography &&
          other.externalUrl == this.externalUrl &&
          other.lastFetched == this.lastFetched &&
          other.isUserSelected == this.isUserSelected);
}

class ArtistMetadataCompanion extends UpdateCompanion<ArtistMetadataData> {
  final Value<int> id;
  final Value<int> artistId;
  final Value<String> source;
  final Value<String?> imageUrl;
  final Value<String?> localPath;
  final Value<String?> biography;
  final Value<String?> externalUrl;
  final Value<DateTime> lastFetched;
  final Value<bool> isUserSelected;
  const ArtistMetadataCompanion({
    this.id = const Value.absent(),
    this.artistId = const Value.absent(),
    this.source = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.biography = const Value.absent(),
    this.externalUrl = const Value.absent(),
    this.lastFetched = const Value.absent(),
    this.isUserSelected = const Value.absent(),
  });
  ArtistMetadataCompanion.insert({
    this.id = const Value.absent(),
    required int artistId,
    required String source,
    this.imageUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.biography = const Value.absent(),
    this.externalUrl = const Value.absent(),
    this.lastFetched = const Value.absent(),
    this.isUserSelected = const Value.absent(),
  }) : artistId = Value(artistId),
       source = Value(source);
  static Insertable<ArtistMetadataData> custom({
    Expression<int>? id,
    Expression<int>? artistId,
    Expression<String>? source,
    Expression<String>? imageUrl,
    Expression<String>? localPath,
    Expression<String>? biography,
    Expression<String>? externalUrl,
    Expression<DateTime>? lastFetched,
    Expression<bool>? isUserSelected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (artistId != null) 'artist_id': artistId,
      if (source != null) 'source': source,
      if (imageUrl != null) 'image_url': imageUrl,
      if (localPath != null) 'local_path': localPath,
      if (biography != null) 'biography': biography,
      if (externalUrl != null) 'external_url': externalUrl,
      if (lastFetched != null) 'last_fetched': lastFetched,
      if (isUserSelected != null) 'is_user_selected': isUserSelected,
    });
  }

  ArtistMetadataCompanion copyWith({
    Value<int>? id,
    Value<int>? artistId,
    Value<String>? source,
    Value<String?>? imageUrl,
    Value<String?>? localPath,
    Value<String?>? biography,
    Value<String?>? externalUrl,
    Value<DateTime>? lastFetched,
    Value<bool>? isUserSelected,
  }) {
    return ArtistMetadataCompanion(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      biography: biography ?? this.biography,
      externalUrl: externalUrl ?? this.externalUrl,
      lastFetched: lastFetched ?? this.lastFetched,
      isUserSelected: isUserSelected ?? this.isUserSelected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (externalUrl.present) {
      map['external_url'] = Variable<String>(externalUrl.value);
    }
    if (lastFetched.present) {
      map['last_fetched'] = Variable<DateTime>(lastFetched.value);
    }
    if (isUserSelected.present) {
      map['is_user_selected'] = Variable<bool>(isUserSelected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistMetadataCompanion(')
          ..write('id: $id, ')
          ..write('artistId: $artistId, ')
          ..write('source: $source, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localPath: $localPath, ')
          ..write('biography: $biography, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('isUserSelected: $isUserSelected')
          ..write(')'))
        .toString();
  }
}

class $AlbumMetadataTable extends AlbumMetadata
    with TableInfo<$AlbumMetadataTable, AlbumMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumArtUrlMeta = const VerificationMeta(
    'albumArtUrl',
  );
  @override
  late final GeneratedColumn<String> albumArtUrl = GeneratedColumn<String>(
    'album_art_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseTypeMeta = const VerificationMeta(
    'releaseType',
  );
  @override
  late final GeneratedColumn<String> releaseType = GeneratedColumn<String>(
    'release_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _popularityMeta = const VerificationMeta(
    'popularity',
  );
  @override
  late final GeneratedColumn<int> popularity = GeneratedColumn<int>(
    'popularity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUserSelectedMeta = const VerificationMeta(
    'isUserSelected',
  );
  @override
  late final GeneratedColumn<bool> isUserSelected = GeneratedColumn<bool>(
    'is_user_selected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_selected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    albumId,
    source,
    albumArtUrl,
    localPath,
    releaseType,
    popularity,
    isUserSelected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'album_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('album_art_url')) {
      context.handle(
        _albumArtUrlMeta,
        albumArtUrl.isAcceptableOrUnknown(
          data['album_art_url']!,
          _albumArtUrlMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('release_type')) {
      context.handle(
        _releaseTypeMeta,
        releaseType.isAcceptableOrUnknown(
          data['release_type']!,
          _releaseTypeMeta,
        ),
      );
    }
    if (data.containsKey('popularity')) {
      context.handle(
        _popularityMeta,
        popularity.isAcceptableOrUnknown(data['popularity']!, _popularityMeta),
      );
    }
    if (data.containsKey('is_user_selected')) {
      context.handle(
        _isUserSelectedMeta,
        isUserSelected.isAcceptableOrUnknown(
          data['is_user_selected']!,
          _isUserSelectedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {albumId, source},
  ];
  @override
  AlbumMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      albumArtUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_art_url'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      releaseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_type'],
      ),
      popularity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}popularity'],
      ),
      isUserSelected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_selected'],
      )!,
    );
  }

  @override
  $AlbumMetadataTable createAlias(String alias) {
    return $AlbumMetadataTable(attachedDatabase, alias);
  }
}

class AlbumMetadataData extends DataClass
    implements Insertable<AlbumMetadataData> {
  final int id;
  final int albumId;

  /// The source type: 'spotify', 'deezer', or 'custom'
  final String source;

  /// Web URL fallback. Null if source is 'custom'.
  final String? albumArtUrl;

  /// **Crucial:** Null if source is 'custom' because the art is embedded in the audio files.
  final String? localPath;
  final String? releaseType;
  final int? popularity;
  final bool isUserSelected;
  const AlbumMetadataData({
    required this.id,
    required this.albumId,
    required this.source,
    this.albumArtUrl,
    this.localPath,
    this.releaseType,
    this.popularity,
    required this.isUserSelected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['album_id'] = Variable<int>(albumId);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || albumArtUrl != null) {
      map['album_art_url'] = Variable<String>(albumArtUrl);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || releaseType != null) {
      map['release_type'] = Variable<String>(releaseType);
    }
    if (!nullToAbsent || popularity != null) {
      map['popularity'] = Variable<int>(popularity);
    }
    map['is_user_selected'] = Variable<bool>(isUserSelected);
    return map;
  }

  AlbumMetadataCompanion toCompanion(bool nullToAbsent) {
    return AlbumMetadataCompanion(
      id: Value(id),
      albumId: Value(albumId),
      source: Value(source),
      albumArtUrl: albumArtUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtUrl),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      releaseType: releaseType == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseType),
      popularity: popularity == null && nullToAbsent
          ? const Value.absent()
          : Value(popularity),
      isUserSelected: Value(isUserSelected),
    );
  }

  factory AlbumMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumMetadataData(
      id: serializer.fromJson<int>(json['id']),
      albumId: serializer.fromJson<int>(json['albumId']),
      source: serializer.fromJson<String>(json['source']),
      albumArtUrl: serializer.fromJson<String?>(json['albumArtUrl']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      releaseType: serializer.fromJson<String?>(json['releaseType']),
      popularity: serializer.fromJson<int?>(json['popularity']),
      isUserSelected: serializer.fromJson<bool>(json['isUserSelected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'albumId': serializer.toJson<int>(albumId),
      'source': serializer.toJson<String>(source),
      'albumArtUrl': serializer.toJson<String?>(albumArtUrl),
      'localPath': serializer.toJson<String?>(localPath),
      'releaseType': serializer.toJson<String?>(releaseType),
      'popularity': serializer.toJson<int?>(popularity),
      'isUserSelected': serializer.toJson<bool>(isUserSelected),
    };
  }

  AlbumMetadataData copyWith({
    int? id,
    int? albumId,
    String? source,
    Value<String?> albumArtUrl = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> releaseType = const Value.absent(),
    Value<int?> popularity = const Value.absent(),
    bool? isUserSelected,
  }) => AlbumMetadataData(
    id: id ?? this.id,
    albumId: albumId ?? this.albumId,
    source: source ?? this.source,
    albumArtUrl: albumArtUrl.present ? albumArtUrl.value : this.albumArtUrl,
    localPath: localPath.present ? localPath.value : this.localPath,
    releaseType: releaseType.present ? releaseType.value : this.releaseType,
    popularity: popularity.present ? popularity.value : this.popularity,
    isUserSelected: isUserSelected ?? this.isUserSelected,
  );
  AlbumMetadataData copyWithCompanion(AlbumMetadataCompanion data) {
    return AlbumMetadataData(
      id: data.id.present ? data.id.value : this.id,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      source: data.source.present ? data.source.value : this.source,
      albumArtUrl: data.albumArtUrl.present
          ? data.albumArtUrl.value
          : this.albumArtUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      releaseType: data.releaseType.present
          ? data.releaseType.value
          : this.releaseType,
      popularity: data.popularity.present
          ? data.popularity.value
          : this.popularity,
      isUserSelected: data.isUserSelected.present
          ? data.isUserSelected.value
          : this.isUserSelected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumMetadataData(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('source: $source, ')
          ..write('albumArtUrl: $albumArtUrl, ')
          ..write('localPath: $localPath, ')
          ..write('releaseType: $releaseType, ')
          ..write('popularity: $popularity, ')
          ..write('isUserSelected: $isUserSelected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    albumId,
    source,
    albumArtUrl,
    localPath,
    releaseType,
    popularity,
    isUserSelected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumMetadataData &&
          other.id == this.id &&
          other.albumId == this.albumId &&
          other.source == this.source &&
          other.albumArtUrl == this.albumArtUrl &&
          other.localPath == this.localPath &&
          other.releaseType == this.releaseType &&
          other.popularity == this.popularity &&
          other.isUserSelected == this.isUserSelected);
}

class AlbumMetadataCompanion extends UpdateCompanion<AlbumMetadataData> {
  final Value<int> id;
  final Value<int> albumId;
  final Value<String> source;
  final Value<String?> albumArtUrl;
  final Value<String?> localPath;
  final Value<String?> releaseType;
  final Value<int?> popularity;
  final Value<bool> isUserSelected;
  const AlbumMetadataCompanion({
    this.id = const Value.absent(),
    this.albumId = const Value.absent(),
    this.source = const Value.absent(),
    this.albumArtUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.releaseType = const Value.absent(),
    this.popularity = const Value.absent(),
    this.isUserSelected = const Value.absent(),
  });
  AlbumMetadataCompanion.insert({
    this.id = const Value.absent(),
    required int albumId,
    required String source,
    this.albumArtUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.releaseType = const Value.absent(),
    this.popularity = const Value.absent(),
    this.isUserSelected = const Value.absent(),
  }) : albumId = Value(albumId),
       source = Value(source);
  static Insertable<AlbumMetadataData> custom({
    Expression<int>? id,
    Expression<int>? albumId,
    Expression<String>? source,
    Expression<String>? albumArtUrl,
    Expression<String>? localPath,
    Expression<String>? releaseType,
    Expression<int>? popularity,
    Expression<bool>? isUserSelected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (albumId != null) 'album_id': albumId,
      if (source != null) 'source': source,
      if (albumArtUrl != null) 'album_art_url': albumArtUrl,
      if (localPath != null) 'local_path': localPath,
      if (releaseType != null) 'release_type': releaseType,
      if (popularity != null) 'popularity': popularity,
      if (isUserSelected != null) 'is_user_selected': isUserSelected,
    });
  }

  AlbumMetadataCompanion copyWith({
    Value<int>? id,
    Value<int>? albumId,
    Value<String>? source,
    Value<String?>? albumArtUrl,
    Value<String?>? localPath,
    Value<String?>? releaseType,
    Value<int?>? popularity,
    Value<bool>? isUserSelected,
  }) {
    return AlbumMetadataCompanion(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      source: source ?? this.source,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      localPath: localPath ?? this.localPath,
      releaseType: releaseType ?? this.releaseType,
      popularity: popularity ?? this.popularity,
      isUserSelected: isUserSelected ?? this.isUserSelected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (albumArtUrl.present) {
      map['album_art_url'] = Variable<String>(albumArtUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (releaseType.present) {
      map['release_type'] = Variable<String>(releaseType.value);
    }
    if (popularity.present) {
      map['popularity'] = Variable<int>(popularity.value);
    }
    if (isUserSelected.present) {
      map['is_user_selected'] = Variable<bool>(isUserSelected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumMetadataCompanion(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('source: $source, ')
          ..write('albumArtUrl: $albumArtUrl, ')
          ..write('localPath: $localPath, ')
          ..write('releaseType: $releaseType, ')
          ..write('popularity: $popularity, ')
          ..write('isUserSelected: $isUserSelected')
          ..write(')'))
        .toString();
  }
}

class $UserFavoritesTable extends UserFavorites
    with TableInfo<$UserFavoritesTable, UserFavorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    albumId,
    artistId,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserFavorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserFavorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFavorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $UserFavoritesTable createAlias(String alias) {
    return $UserFavoritesTable(attachedDatabase, alias);
  }
}

class UserFavorite extends DataClass implements Insertable<UserFavorite> {
  final int id;
  final int? trackId;
  final int? albumId;
  final int? artistId;
  final DateTime dateAdded;
  const UserFavorite({
    required this.id,
    this.trackId,
    this.albumId,
    this.artistId,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<int>(trackId);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<int>(artistId);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  UserFavoritesCompanion toCompanion(bool nullToAbsent) {
    return UserFavoritesCompanion(
      id: Value(id),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      dateAdded: Value(dateAdded),
    );
  }

  factory UserFavorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFavorite(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int?>(json['trackId']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      artistId: serializer.fromJson<int?>(json['artistId']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int?>(trackId),
      'albumId': serializer.toJson<int?>(albumId),
      'artistId': serializer.toJson<int?>(artistId),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  UserFavorite copyWith({
    int? id,
    Value<int?> trackId = const Value.absent(),
    Value<int?> albumId = const Value.absent(),
    Value<int?> artistId = const Value.absent(),
    DateTime? dateAdded,
  }) => UserFavorite(
    id: id ?? this.id,
    trackId: trackId.present ? trackId.value : this.trackId,
    albumId: albumId.present ? albumId.value : this.albumId,
    artistId: artistId.present ? artistId.value : this.artistId,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  UserFavorite copyWithCompanion(UserFavoritesCompanion data) {
    return UserFavorite(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFavorite(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, albumId, artistId, dateAdded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFavorite &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.albumId == this.albumId &&
          other.artistId == this.artistId &&
          other.dateAdded == this.dateAdded);
}

class UserFavoritesCompanion extends UpdateCompanion<UserFavorite> {
  final Value<int> id;
  final Value<int?> trackId;
  final Value<int?> albumId;
  final Value<int?> artistId;
  final Value<DateTime> dateAdded;
  const UserFavoritesCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  UserFavoritesCompanion.insert({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  static Insertable<UserFavorite> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? albumId,
    Expression<int>? artistId,
    Expression<DateTime>? dateAdded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
      if (dateAdded != null) 'date_added': dateAdded,
    });
  }

  UserFavoritesCompanion copyWith({
    Value<int>? id,
    Value<int?>? trackId,
    Value<int?>? albumId,
    Value<int?>? artistId,
    Value<DateTime>? dateAdded,
  }) {
    return UserFavoritesCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFavoritesCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }
}

class $UserBlacklistTable extends UserBlacklist
    with TableInfo<$UserBlacklistTable, UserBlacklistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserBlacklistTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    albumId,
    artistId,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_blacklist';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserBlacklistData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserBlacklistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserBlacklistData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $UserBlacklistTable createAlias(String alias) {
    return $UserBlacklistTable(attachedDatabase, alias);
  }
}

class UserBlacklistData extends DataClass
    implements Insertable<UserBlacklistData> {
  final int id;
  final int? trackId;
  final int? albumId;
  final int? artistId;
  final DateTime dateAdded;
  const UserBlacklistData({
    required this.id,
    this.trackId,
    this.albumId,
    this.artistId,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<int>(trackId);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<int>(artistId);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  UserBlacklistCompanion toCompanion(bool nullToAbsent) {
    return UserBlacklistCompanion(
      id: Value(id),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      dateAdded: Value(dateAdded),
    );
  }

  factory UserBlacklistData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserBlacklistData(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int?>(json['trackId']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      artistId: serializer.fromJson<int?>(json['artistId']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int?>(trackId),
      'albumId': serializer.toJson<int?>(albumId),
      'artistId': serializer.toJson<int?>(artistId),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  UserBlacklistData copyWith({
    int? id,
    Value<int?> trackId = const Value.absent(),
    Value<int?> albumId = const Value.absent(),
    Value<int?> artistId = const Value.absent(),
    DateTime? dateAdded,
  }) => UserBlacklistData(
    id: id ?? this.id,
    trackId: trackId.present ? trackId.value : this.trackId,
    albumId: albumId.present ? albumId.value : this.albumId,
    artistId: artistId.present ? artistId.value : this.artistId,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  UserBlacklistData copyWithCompanion(UserBlacklistCompanion data) {
    return UserBlacklistData(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserBlacklistData(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, albumId, artistId, dateAdded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserBlacklistData &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.albumId == this.albumId &&
          other.artistId == this.artistId &&
          other.dateAdded == this.dateAdded);
}

class UserBlacklistCompanion extends UpdateCompanion<UserBlacklistData> {
  final Value<int> id;
  final Value<int?> trackId;
  final Value<int?> albumId;
  final Value<int?> artistId;
  final Value<DateTime> dateAdded;
  const UserBlacklistCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  UserBlacklistCompanion.insert({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  static Insertable<UserBlacklistData> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? albumId,
    Expression<int>? artistId,
    Expression<DateTime>? dateAdded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
      if (dateAdded != null) 'date_added': dateAdded,
    });
  }

  UserBlacklistCompanion copyWith({
    Value<int>? id,
    Value<int?>? trackId,
    Value<int?>? albumId,
    Value<int?>? artistId,
    Value<DateTime>? dateAdded,
  }) {
    return UserBlacklistCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserBlacklistCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }
}

class $UserPinsTable extends UserPins with TableInfo<$UserPinsTable, UserPin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    albumId,
    artistId,
    playlistId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      ),
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $UserPinsTable createAlias(String alias) {
    return $UserPinsTable(attachedDatabase, alias);
  }
}

class UserPin extends DataClass implements Insertable<UserPin> {
  final int id;
  final int? trackId;
  final int? albumId;
  final int? artistId;
  final int? playlistId;
  final int sortOrder;
  const UserPin({
    required this.id,
    this.trackId,
    this.albumId,
    this.artistId,
    this.playlistId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<int>(trackId);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<int>(artistId);
    }
    if (!nullToAbsent || playlistId != null) {
      map['playlist_id'] = Variable<int>(playlistId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  UserPinsCompanion toCompanion(bool nullToAbsent) {
    return UserPinsCompanion(
      id: Value(id),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      playlistId: playlistId == null && nullToAbsent
          ? const Value.absent()
          : Value(playlistId),
      sortOrder: Value(sortOrder),
    );
  }

  factory UserPin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPin(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int?>(json['trackId']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      artistId: serializer.fromJson<int?>(json['artistId']),
      playlistId: serializer.fromJson<int?>(json['playlistId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int?>(trackId),
      'albumId': serializer.toJson<int?>(albumId),
      'artistId': serializer.toJson<int?>(artistId),
      'playlistId': serializer.toJson<int?>(playlistId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  UserPin copyWith({
    int? id,
    Value<int?> trackId = const Value.absent(),
    Value<int?> albumId = const Value.absent(),
    Value<int?> artistId = const Value.absent(),
    Value<int?> playlistId = const Value.absent(),
    int? sortOrder,
  }) => UserPin(
    id: id ?? this.id,
    trackId: trackId.present ? trackId.value : this.trackId,
    albumId: albumId.present ? albumId.value : this.albumId,
    artistId: artistId.present ? artistId.value : this.artistId,
    playlistId: playlistId.present ? playlistId.value : this.playlistId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  UserPin copyWithCompanion(UserPinsCompanion data) {
    return UserPin(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPin(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('playlistId: $playlistId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackId, albumId, artistId, playlistId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPin &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.albumId == this.albumId &&
          other.artistId == this.artistId &&
          other.playlistId == this.playlistId &&
          other.sortOrder == this.sortOrder);
}

class UserPinsCompanion extends UpdateCompanion<UserPin> {
  final Value<int> id;
  final Value<int?> trackId;
  final Value<int?> albumId;
  final Value<int?> artistId;
  final Value<int?> playlistId;
  final Value<int> sortOrder;
  const UserPinsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  UserPinsCompanion.insert({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  static Insertable<UserPin> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? albumId,
    Expression<int>? artistId,
    Expression<int>? playlistId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  UserPinsCompanion copyWith({
    Value<int>? id,
    Value<int?>? trackId,
    Value<int?>? albumId,
    Value<int?>? artistId,
    Value<int?>? playlistId,
    Value<int>? sortOrder,
  }) {
    return UserPinsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      playlistId: playlistId ?? this.playlistId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPinsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('playlistId: $playlistId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArtistsTable artists = $ArtistsTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $TrackArtistTable trackArtist = $TrackArtistTable(this);
  late final $PlaylistTrackTable playlistTrack = $PlaylistTrackTable(this);
  late final $QueueEntriesTable queueEntries = $QueueEntriesTable(this);
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final $SourcePrioritiesTable sourcePriorities = $SourcePrioritiesTable(
    this,
  );
  late final $ArtistMetadataTable artistMetadata = $ArtistMetadataTable(this);
  late final $AlbumMetadataTable albumMetadata = $AlbumMetadataTable(this);
  late final $UserFavoritesTable userFavorites = $UserFavoritesTable(this);
  late final $UserBlacklistTable userBlacklist = $UserBlacklistTable(this);
  late final $UserPinsTable userPins = $UserPinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    artists,
    albums,
    tracks,
    playlists,
    trackArtist,
    playlistTrack,
    queueEntries,
    playHistory,
    sourcePriorities,
    artistMetadata,
    albumMetadata,
    userFavorites,
    userBlacklist,
    userPins,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_artist', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_artist', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_track', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_track', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('artist_metadata', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'albums',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('album_metadata', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'albums',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_blacklist', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'albums',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_blacklist', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_blacklist', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_pins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'albums',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_pins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_pins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_pins', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ArtistsTableCreateCompanionBuilder =
    ArtistsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> artistImgPath,
    });
typedef $$ArtistsTableUpdateCompanionBuilder =
    ArtistsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> artistImgPath,
    });

final class $$ArtistsTableReferences
    extends BaseReferences<_$AppDatabase, $ArtistsTable, Artist> {
  $$ArtistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AlbumsTable, List<Album>> _albumsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.albums,
    aliasName: $_aliasNameGenerator(db.artists.id, db.albums.albumArtistId),
  );

  $$AlbumsTableProcessedTableManager get albumsRefs {
    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.albumArtistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_albumsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TracksTable, List<Track>> _tracksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: $_aliasNameGenerator(db.artists.id, db.tracks.artistId),
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrackArtistTable, List<TrackArtistData>>
  _trackArtistRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackArtist,
    aliasName: $_aliasNameGenerator(db.artists.id, db.trackArtist.artistId),
  );

  $$TrackArtistTableProcessedTableManager get trackArtistRefs {
    final manager = $$TrackArtistTableTableManager(
      $_db,
      $_db.trackArtist,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackArtistRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArtistMetadataTable, List<ArtistMetadataData>>
  _artistMetadataRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.artistMetadata,
    aliasName: $_aliasNameGenerator(db.artists.id, db.artistMetadata.artistId),
  );

  $$ArtistMetadataTableProcessedTableManager get artistMetadataRefs {
    final manager = $$ArtistMetadataTableTableManager(
      $_db,
      $_db.artistMetadata,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artistMetadataRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserFavoritesTable, List<UserFavorite>>
  _userFavoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userFavorites,
    aliasName: $_aliasNameGenerator(db.artists.id, db.userFavorites.artistId),
  );

  $$UserFavoritesTableProcessedTableManager get userFavoritesRefs {
    final manager = $$UserFavoritesTableTableManager(
      $_db,
      $_db.userFavorites,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userFavoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserBlacklistTable, List<UserBlacklistData>>
  _userBlacklistRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userBlacklist,
    aliasName: $_aliasNameGenerator(db.artists.id, db.userBlacklist.artistId),
  );

  $$UserBlacklistTableProcessedTableManager get userBlacklistRefs {
    final manager = $$UserBlacklistTableTableManager(
      $_db,
      $_db.userBlacklist,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userBlacklistRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserPinsTable, List<UserPin>> _userPinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.userPins,
    aliasName: $_aliasNameGenerator(db.artists.id, db.userPins.artistId),
  );

  $$UserPinsTableProcessedTableManager get userPinsRefs {
    final manager = $$UserPinsTableTableManager(
      $_db,
      $_db.userPins,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userPinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArtistsTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistImgPath => $composableBuilder(
    column: $table.artistImgPath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> albumsRefs(
    Expression<bool> Function($$AlbumsTableFilterComposer f) f,
  ) {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.albumArtistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trackArtistRefs(
    Expression<bool> Function($$TrackArtistTableFilterComposer f) f,
  ) {
    final $$TrackArtistTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtist,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistTableFilterComposer(
            $db: $db,
            $table: $db.trackArtist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> artistMetadataRefs(
    Expression<bool> Function($$ArtistMetadataTableFilterComposer f) f,
  ) {
    final $$ArtistMetadataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artistMetadata,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistMetadataTableFilterComposer(
            $db: $db,
            $table: $db.artistMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userFavoritesRefs(
    Expression<bool> Function($$UserFavoritesTableFilterComposer f) f,
  ) {
    final $$UserFavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFavorites,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFavoritesTableFilterComposer(
            $db: $db,
            $table: $db.userFavorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userBlacklistRefs(
    Expression<bool> Function($$UserBlacklistTableFilterComposer f) f,
  ) {
    final $$UserBlacklistTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userBlacklist,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserBlacklistTableFilterComposer(
            $db: $db,
            $table: $db.userBlacklist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userPinsRefs(
    Expression<bool> Function($$UserPinsTableFilterComposer f) f,
  ) {
    final $$UserPinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableFilterComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArtistsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistImgPath => $composableBuilder(
    column: $table.artistImgPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artistImgPath => $composableBuilder(
    column: $table.artistImgPath,
    builder: (column) => column,
  );

  Expression<T> albumsRefs<T extends Object>(
    Expression<T> Function($$AlbumsTableAnnotationComposer a) f,
  ) {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.albumArtistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trackArtistRefs<T extends Object>(
    Expression<T> Function($$TrackArtistTableAnnotationComposer a) f,
  ) {
    final $$TrackArtistTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtist,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistTableAnnotationComposer(
            $db: $db,
            $table: $db.trackArtist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> artistMetadataRefs<T extends Object>(
    Expression<T> Function($$ArtistMetadataTableAnnotationComposer a) f,
  ) {
    final $$ArtistMetadataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artistMetadata,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistMetadataTableAnnotationComposer(
            $db: $db,
            $table: $db.artistMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userFavoritesRefs<T extends Object>(
    Expression<T> Function($$UserFavoritesTableAnnotationComposer a) f,
  ) {
    final $$UserFavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFavorites,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.userFavorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userBlacklistRefs<T extends Object>(
    Expression<T> Function($$UserBlacklistTableAnnotationComposer a) f,
  ) {
    final $$UserBlacklistTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userBlacklist,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserBlacklistTableAnnotationComposer(
            $db: $db,
            $table: $db.userBlacklist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userPinsRefs<T extends Object>(
    Expression<T> Function($$UserPinsTableAnnotationComposer a) f,
  ) {
    final $$UserPinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableAnnotationComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArtistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistsTable,
          Artist,
          $$ArtistsTableFilterComposer,
          $$ArtistsTableOrderingComposer,
          $$ArtistsTableAnnotationComposer,
          $$ArtistsTableCreateCompanionBuilder,
          $$ArtistsTableUpdateCompanionBuilder,
          (Artist, $$ArtistsTableReferences),
          Artist,
          PrefetchHooks Function({
            bool albumsRefs,
            bool tracksRefs,
            bool trackArtistRefs,
            bool artistMetadataRefs,
            bool userFavoritesRefs,
            bool userBlacklistRefs,
            bool userPinsRefs,
          })
        > {
  $$ArtistsTableTableManager(_$AppDatabase db, $ArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> artistImgPath = const Value.absent(),
              }) => ArtistsCompanion(
                id: id,
                name: name,
                artistImgPath: artistImgPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> artistImgPath = const Value.absent(),
              }) => ArtistsCompanion.insert(
                id: id,
                name: name,
                artistImgPath: artistImgPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArtistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                albumsRefs = false,
                tracksRefs = false,
                trackArtistRefs = false,
                artistMetadataRefs = false,
                userFavoritesRefs = false,
                userBlacklistRefs = false,
                userPinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (albumsRefs) db.albums,
                    if (tracksRefs) db.tracks,
                    if (trackArtistRefs) db.trackArtist,
                    if (artistMetadataRefs) db.artistMetadata,
                    if (userFavoritesRefs) db.userFavorites,
                    if (userBlacklistRefs) db.userBlacklist,
                    if (userPinsRefs) db.userPins,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (albumsRefs)
                        await $_getPrefetchedData<Artist, $ArtistsTable, Album>(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._albumsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).albumsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumArtistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tracksRefs)
                        await $_getPrefetchedData<Artist, $ArtistsTable, Track>(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._tracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).tracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trackArtistRefs)
                        await $_getPrefetchedData<
                          Artist,
                          $ArtistsTable,
                          TrackArtistData
                        >(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._trackArtistRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).trackArtistRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (artistMetadataRefs)
                        await $_getPrefetchedData<
                          Artist,
                          $ArtistsTable,
                          ArtistMetadataData
                        >(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._artistMetadataRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).artistMetadataRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userFavoritesRefs)
                        await $_getPrefetchedData<
                          Artist,
                          $ArtistsTable,
                          UserFavorite
                        >(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._userFavoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).userFavoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userBlacklistRefs)
                        await $_getPrefetchedData<
                          Artist,
                          $ArtistsTable,
                          UserBlacklistData
                        >(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._userBlacklistRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).userBlacklistRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userPinsRefs)
                        await $_getPrefetchedData<
                          Artist,
                          $ArtistsTable,
                          UserPin
                        >(
                          currentTable: table,
                          referencedTable: $$ArtistsTableReferences
                              ._userPinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).userPinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistsTable,
      Artist,
      $$ArtistsTableFilterComposer,
      $$ArtistsTableOrderingComposer,
      $$ArtistsTableAnnotationComposer,
      $$ArtistsTableCreateCompanionBuilder,
      $$ArtistsTableUpdateCompanionBuilder,
      (Artist, $$ArtistsTableReferences),
      Artist,
      PrefetchHooks Function({
        bool albumsRefs,
        bool tracksRefs,
        bool trackArtistRefs,
        bool artistMetadataRefs,
        bool userFavoritesRefs,
        bool userBlacklistRefs,
        bool userPinsRefs,
      })
    >;
typedef $$AlbumsTableCreateCompanionBuilder =
    AlbumsCompanion Function({
      Value<int> id,
      required String title,
      Value<int> year,
      Value<String?> albumArtist,
      Value<String?> albumArtPath,
      Value<int?> albumArtistId,
    });
typedef $$AlbumsTableUpdateCompanionBuilder =
    AlbumsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> year,
      Value<String?> albumArtist,
      Value<String?> albumArtPath,
      Value<int?> albumArtistId,
    });

final class $$AlbumsTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumsTable, Album> {
  $$AlbumsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArtistsTable _albumArtistIdTable(_$AppDatabase db) =>
      db.artists.createAlias(
        $_aliasNameGenerator(db.albums.albumArtistId, db.artists.id),
      );

  $$ArtistsTableProcessedTableManager? get albumArtistId {
    final $_column = $_itemColumn<int>('album_artist_id');
    if ($_column == null) return null;
    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumArtistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TracksTable, List<Track>> _tracksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: $_aliasNameGenerator(db.albums.id, db.tracks.albumId),
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlbumMetadataTable, List<AlbumMetadataData>>
  _albumMetadataRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.albumMetadata,
    aliasName: $_aliasNameGenerator(db.albums.id, db.albumMetadata.albumId),
  );

  $$AlbumMetadataTableProcessedTableManager get albumMetadataRefs {
    final manager = $$AlbumMetadataTableTableManager(
      $_db,
      $_db.albumMetadata,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_albumMetadataRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserFavoritesTable, List<UserFavorite>>
  _userFavoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userFavorites,
    aliasName: $_aliasNameGenerator(db.albums.id, db.userFavorites.albumId),
  );

  $$UserFavoritesTableProcessedTableManager get userFavoritesRefs {
    final manager = $$UserFavoritesTableTableManager(
      $_db,
      $_db.userFavorites,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userFavoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserBlacklistTable, List<UserBlacklistData>>
  _userBlacklistRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userBlacklist,
    aliasName: $_aliasNameGenerator(db.albums.id, db.userBlacklist.albumId),
  );

  $$UserBlacklistTableProcessedTableManager get userBlacklistRefs {
    final manager = $$UserBlacklistTableTableManager(
      $_db,
      $_db.userBlacklist,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userBlacklistRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserPinsTable, List<UserPin>> _userPinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.userPins,
    aliasName: $_aliasNameGenerator(db.albums.id, db.userPins.albumId),
  );

  $$UserPinsTableProcessedTableManager get userPinsRefs {
    final manager = $$UserPinsTableTableManager(
      $_db,
      $_db.userPins,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userPinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtPath => $composableBuilder(
    column: $table.albumArtPath,
    builder: (column) => ColumnFilters(column),
  );

  $$ArtistsTableFilterComposer get albumArtistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumArtistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> albumMetadataRefs(
    Expression<bool> Function($$AlbumMetadataTableFilterComposer f) f,
  ) {
    final $$AlbumMetadataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumMetadata,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumMetadataTableFilterComposer(
            $db: $db,
            $table: $db.albumMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userFavoritesRefs(
    Expression<bool> Function($$UserFavoritesTableFilterComposer f) f,
  ) {
    final $$UserFavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFavorites,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFavoritesTableFilterComposer(
            $db: $db,
            $table: $db.userFavorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userBlacklistRefs(
    Expression<bool> Function($$UserBlacklistTableFilterComposer f) f,
  ) {
    final $$UserBlacklistTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userBlacklist,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserBlacklistTableFilterComposer(
            $db: $db,
            $table: $db.userBlacklist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userPinsRefs(
    Expression<bool> Function($$UserPinsTableFilterComposer f) f,
  ) {
    final $$UserPinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableFilterComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtPath => $composableBuilder(
    column: $table.albumArtPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArtistsTableOrderingComposer get albumArtistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumArtistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumArtPath => $composableBuilder(
    column: $table.albumArtPath,
    builder: (column) => column,
  );

  $$ArtistsTableAnnotationComposer get albumArtistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumArtistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> albumMetadataRefs<T extends Object>(
    Expression<T> Function($$AlbumMetadataTableAnnotationComposer a) f,
  ) {
    final $$AlbumMetadataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumMetadata,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumMetadataTableAnnotationComposer(
            $db: $db,
            $table: $db.albumMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userFavoritesRefs<T extends Object>(
    Expression<T> Function($$UserFavoritesTableAnnotationComposer a) f,
  ) {
    final $$UserFavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFavorites,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.userFavorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userBlacklistRefs<T extends Object>(
    Expression<T> Function($$UserBlacklistTableAnnotationComposer a) f,
  ) {
    final $$UserBlacklistTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userBlacklist,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserBlacklistTableAnnotationComposer(
            $db: $db,
            $table: $db.userBlacklist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userPinsRefs<T extends Object>(
    Expression<T> Function($$UserPinsTableAnnotationComposer a) f,
  ) {
    final $$UserPinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableAnnotationComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTable,
          Album,
          $$AlbumsTableFilterComposer,
          $$AlbumsTableOrderingComposer,
          $$AlbumsTableAnnotationComposer,
          $$AlbumsTableCreateCompanionBuilder,
          $$AlbumsTableUpdateCompanionBuilder,
          (Album, $$AlbumsTableReferences),
          Album,
          PrefetchHooks Function({
            bool albumArtistId,
            bool tracksRefs,
            bool albumMetadataRefs,
            bool userFavoritesRefs,
            bool userBlacklistRefs,
            bool userPinsRefs,
          })
        > {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> albumArtPath = const Value.absent(),
                Value<int?> albumArtistId = const Value.absent(),
              }) => AlbumsCompanion(
                id: id,
                title: title,
                year: year,
                albumArtist: albumArtist,
                albumArtPath: albumArtPath,
                albumArtistId: albumArtistId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int> year = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> albumArtPath = const Value.absent(),
                Value<int?> albumArtistId = const Value.absent(),
              }) => AlbumsCompanion.insert(
                id: id,
                title: title,
                year: year,
                albumArtist: albumArtist,
                albumArtPath: albumArtPath,
                albumArtistId: albumArtistId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AlbumsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                albumArtistId = false,
                tracksRefs = false,
                albumMetadataRefs = false,
                userFavoritesRefs = false,
                userBlacklistRefs = false,
                userPinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tracksRefs) db.tracks,
                    if (albumMetadataRefs) db.albumMetadata,
                    if (userFavoritesRefs) db.userFavorites,
                    if (userBlacklistRefs) db.userBlacklist,
                    if (userPinsRefs) db.userPins,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (albumArtistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.albumArtistId,
                                    referencedTable: $$AlbumsTableReferences
                                        ._albumArtistIdTable(db),
                                    referencedColumn: $$AlbumsTableReferences
                                        ._albumArtistIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tracksRefs)
                        await $_getPrefetchedData<Album, $AlbumsTable, Track>(
                          currentTable: table,
                          referencedTable: $$AlbumsTableReferences
                              ._tracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlbumsTableReferences(db, table, p0).tracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (albumMetadataRefs)
                        await $_getPrefetchedData<
                          Album,
                          $AlbumsTable,
                          AlbumMetadataData
                        >(
                          currentTable: table,
                          referencedTable: $$AlbumsTableReferences
                              ._albumMetadataRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).albumMetadataRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userFavoritesRefs)
                        await $_getPrefetchedData<
                          Album,
                          $AlbumsTable,
                          UserFavorite
                        >(
                          currentTable: table,
                          referencedTable: $$AlbumsTableReferences
                              ._userFavoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).userFavoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userBlacklistRefs)
                        await $_getPrefetchedData<
                          Album,
                          $AlbumsTable,
                          UserBlacklistData
                        >(
                          currentTable: table,
                          referencedTable: $$AlbumsTableReferences
                              ._userBlacklistRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).userBlacklistRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userPinsRefs)
                        await $_getPrefetchedData<Album, $AlbumsTable, UserPin>(
                          currentTable: table,
                          referencedTable: $$AlbumsTableReferences
                              ._userPinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).userPinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTable,
      Album,
      $$AlbumsTableFilterComposer,
      $$AlbumsTableOrderingComposer,
      $$AlbumsTableAnnotationComposer,
      $$AlbumsTableCreateCompanionBuilder,
      $$AlbumsTableUpdateCompanionBuilder,
      (Album, $$AlbumsTableReferences),
      Album,
      PrefetchHooks Function({
        bool albumArtistId,
        bool tracksRefs,
        bool albumMetadataRefs,
        bool userFavoritesRefs,
        bool userBlacklistRefs,
        bool userPinsRefs,
      })
    >;
typedef $$TracksTableCreateCompanionBuilder =
    TracksCompanion Function({
      Value<int> id,
      required String title,
      Value<int> trackNumber,
      Value<int> trackTotal,
      Value<int> discNumber,
      Value<int> discTotal,
      Value<int> durationMs,
      Value<String?> genre,
      required String fileHash,
      Value<Uint8List?> audioFingerprint,
      Value<bool> isMissing,
      required String filePath,
      Value<int> fileSize,
      required int artistId,
      required int albumId,
      Value<DateTime> dateAdded,
    });
typedef $$TracksTableUpdateCompanionBuilder =
    TracksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> trackNumber,
      Value<int> trackTotal,
      Value<int> discNumber,
      Value<int> discTotal,
      Value<int> durationMs,
      Value<String?> genre,
      Value<String> fileHash,
      Value<Uint8List?> audioFingerprint,
      Value<bool> isMissing,
      Value<String> filePath,
      Value<int> fileSize,
      Value<int> artistId,
      Value<int> albumId,
      Value<DateTime> dateAdded,
    });

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArtistsTable _artistIdTable(_$AppDatabase db) => db.artists
      .createAlias($_aliasNameGenerator(db.tracks.artistId, db.artists.id));

  $$ArtistsTableProcessedTableManager get artistId {
    final $_column = $_itemColumn<int>('artist_id')!;

    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlbumsTable _albumIdTable(_$AppDatabase db) => db.albums.createAlias(
    $_aliasNameGenerator(db.tracks.albumId, db.albums.id),
  );

  $$AlbumsTableProcessedTableManager get albumId {
    final $_column = $_itemColumn<int>('album_id')!;

    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TrackArtistTable, List<TrackArtistData>>
  _trackArtistRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackArtist,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.trackArtist.trackId),
  );

  $$TrackArtistTableProcessedTableManager get trackArtistRefs {
    final manager = $$TrackArtistTableTableManager(
      $_db,
      $_db.trackArtist,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackArtistRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaylistTrackTable, List<PlaylistTrackData>>
  _playlistTrackRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistTrack,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.playlistTrack.trackId),
  );

  $$PlaylistTrackTableProcessedTableManager get playlistTrackRefs {
    final manager = $$PlaylistTrackTableTableManager(
      $_db,
      $_db.playlistTrack,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistTrackRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QueueEntriesTable, List<QueueEntry>>
  _queueEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.queueEntries,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.queueEntries.trackId),
  );

  $$QueueEntriesTableProcessedTableManager get queueEntriesRefs {
    final manager = $$QueueEntriesTableTableManager(
      $_db,
      $_db.queueEntries,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_queueEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayHistoryTable, List<PlayHistoryData>>
  _playHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playHistory,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.playHistory.trackId),
  );

  $$PlayHistoryTableProcessedTableManager get playHistoryRefs {
    final manager = $$PlayHistoryTableTableManager(
      $_db,
      $_db.playHistory,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserFavoritesTable, List<UserFavorite>>
  _userFavoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userFavorites,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.userFavorites.trackId),
  );

  $$UserFavoritesTableProcessedTableManager get userFavoritesRefs {
    final manager = $$UserFavoritesTableTableManager(
      $_db,
      $_db.userFavorites,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userFavoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserBlacklistTable, List<UserBlacklistData>>
  _userBlacklistRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userBlacklist,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.userBlacklist.trackId),
  );

  $$UserBlacklistTableProcessedTableManager get userBlacklistRefs {
    final manager = $$UserBlacklistTableTableManager(
      $_db,
      $_db.userBlacklist,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userBlacklistRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserPinsTable, List<UserPin>> _userPinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.userPins,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.userPins.trackId),
  );

  $$UserPinsTableProcessedTableManager get userPinsRefs {
    final manager = $$UserPinsTableTableManager(
      $_db,
      $_db.userPins,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userPinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackTotal => $composableBuilder(
    column: $table.trackTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discTotal => $composableBuilder(
    column: $table.discTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get audioFingerprint => $composableBuilder(
    column: $table.audioFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMissing => $composableBuilder(
    column: $table.isMissing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> trackArtistRefs(
    Expression<bool> Function($$TrackArtistTableFilterComposer f) f,
  ) {
    final $$TrackArtistTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtist,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistTableFilterComposer(
            $db: $db,
            $table: $db.trackArtist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistTrackRefs(
    Expression<bool> Function($$PlaylistTrackTableFilterComposer f) f,
  ) {
    final $$PlaylistTrackTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTrack,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTrackTableFilterComposer(
            $db: $db,
            $table: $db.playlistTrack,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> queueEntriesRefs(
    Expression<bool> Function($$QueueEntriesTableFilterComposer f) f,
  ) {
    final $$QueueEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queueEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueEntriesTableFilterComposer(
            $db: $db,
            $table: $db.queueEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playHistoryRefs(
    Expression<bool> Function($$PlayHistoryTableFilterComposer f) f,
  ) {
    final $$PlayHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableFilterComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userFavoritesRefs(
    Expression<bool> Function($$UserFavoritesTableFilterComposer f) f,
  ) {
    final $$UserFavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFavorites,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFavoritesTableFilterComposer(
            $db: $db,
            $table: $db.userFavorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userBlacklistRefs(
    Expression<bool> Function($$UserBlacklistTableFilterComposer f) f,
  ) {
    final $$UserBlacklistTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userBlacklist,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserBlacklistTableFilterComposer(
            $db: $db,
            $table: $db.userBlacklist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userPinsRefs(
    Expression<bool> Function($$UserPinsTableFilterComposer f) f,
  ) {
    final $$UserPinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableFilterComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackTotal => $composableBuilder(
    column: $table.trackTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discTotal => $composableBuilder(
    column: $table.discTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get audioFingerprint => $composableBuilder(
    column: $table.audioFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMissing => $composableBuilder(
    column: $table.isMissing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackTotal => $composableBuilder(
    column: $table.trackTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discTotal =>
      $composableBuilder(column: $table.discTotal, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<Uint8List> get audioFingerprint => $composableBuilder(
    column: $table.audioFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMissing =>
      $composableBuilder(column: $table.isMissing, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> trackArtistRefs<T extends Object>(
    Expression<T> Function($$TrackArtistTableAnnotationComposer a) f,
  ) {
    final $$TrackArtistTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtist,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistTableAnnotationComposer(
            $db: $db,
            $table: $db.trackArtist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistTrackRefs<T extends Object>(
    Expression<T> Function($$PlaylistTrackTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTrackTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTrack,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTrackTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistTrack,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> queueEntriesRefs<T extends Object>(
    Expression<T> Function($$QueueEntriesTableAnnotationComposer a) f,
  ) {
    final $$QueueEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queueEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.queueEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playHistoryRefs<T extends Object>(
    Expression<T> Function($$PlayHistoryTableAnnotationComposer a) f,
  ) {
    final $$PlayHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userFavoritesRefs<T extends Object>(
    Expression<T> Function($$UserFavoritesTableAnnotationComposer a) f,
  ) {
    final $$UserFavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFavorites,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.userFavorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userBlacklistRefs<T extends Object>(
    Expression<T> Function($$UserBlacklistTableAnnotationComposer a) f,
  ) {
    final $$UserBlacklistTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userBlacklist,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserBlacklistTableAnnotationComposer(
            $db: $db,
            $table: $db.userBlacklist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userPinsRefs<T extends Object>(
    Expression<T> Function($$UserPinsTableAnnotationComposer a) f,
  ) {
    final $$UserPinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableAnnotationComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, $$TracksTableReferences),
          Track,
          PrefetchHooks Function({
            bool artistId,
            bool albumId,
            bool trackArtistRefs,
            bool playlistTrackRefs,
            bool queueEntriesRefs,
            bool playHistoryRefs,
            bool userFavoritesRefs,
            bool userBlacklistRefs,
            bool userPinsRefs,
          })
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> trackNumber = const Value.absent(),
                Value<int> trackTotal = const Value.absent(),
                Value<int> discNumber = const Value.absent(),
                Value<int> discTotal = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<Uint8List?> audioFingerprint = const Value.absent(),
                Value<bool> isMissing = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> artistId = const Value.absent(),
                Value<int> albumId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => TracksCompanion(
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
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int> trackNumber = const Value.absent(),
                Value<int> trackTotal = const Value.absent(),
                Value<int> discNumber = const Value.absent(),
                Value<int> discTotal = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                required String fileHash,
                Value<Uint8List?> audioFingerprint = const Value.absent(),
                Value<bool> isMissing = const Value.absent(),
                required String filePath,
                Value<int> fileSize = const Value.absent(),
                required int artistId,
                required int albumId,
                Value<DateTime> dateAdded = const Value.absent(),
              }) => TracksCompanion.insert(
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
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TracksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                artistId = false,
                albumId = false,
                trackArtistRefs = false,
                playlistTrackRefs = false,
                queueEntriesRefs = false,
                playHistoryRefs = false,
                userFavoritesRefs = false,
                userBlacklistRefs = false,
                userPinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackArtistRefs) db.trackArtist,
                    if (playlistTrackRefs) db.playlistTrack,
                    if (queueEntriesRefs) db.queueEntries,
                    if (playHistoryRefs) db.playHistory,
                    if (userFavoritesRefs) db.userFavorites,
                    if (userBlacklistRefs) db.userBlacklist,
                    if (userPinsRefs) db.userPins,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (artistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.artistId,
                                    referencedTable: $$TracksTableReferences
                                        ._artistIdTable(db),
                                    referencedColumn: $$TracksTableReferences
                                        ._artistIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (albumId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.albumId,
                                    referencedTable: $$TracksTableReferences
                                        ._albumIdTable(db),
                                    referencedColumn: $$TracksTableReferences
                                        ._albumIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackArtistRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          TrackArtistData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._trackArtistRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).trackArtistRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playlistTrackRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlaylistTrackData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playlistTrackRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistTrackRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (queueEntriesRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          QueueEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._queueEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).queueEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playHistoryRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlayHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userFavoritesRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          UserFavorite
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._userFavoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).userFavoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userBlacklistRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          UserBlacklistData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._userBlacklistRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).userBlacklistRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userPinsRefs)
                        await $_getPrefetchedData<Track, $TracksTable, UserPin>(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._userPinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).userPinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, $$TracksTableReferences),
      Track,
      PrefetchHooks Function({
        bool artistId,
        bool albumId,
        bool trackArtistRefs,
        bool playlistTrackRefs,
        bool queueEntriesRefs,
        bool playHistoryRefs,
        bool userFavoritesRefs,
        bool userBlacklistRefs,
        bool userPinsRefs,
      })
    >;
typedef $$PlaylistsTableCreateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> coverPath,
    });
typedef $$PlaylistsTableUpdateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> coverPath,
    });

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistData> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistTrackTable, List<PlaylistTrackData>>
  _playlistTrackRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistTrack,
    aliasName: $_aliasNameGenerator(
      db.playlists.id,
      db.playlistTrack.playlistId,
    ),
  );

  $$PlaylistTrackTableProcessedTableManager get playlistTrackRefs {
    final manager = $$PlaylistTrackTableTableManager(
      $_db,
      $_db.playlistTrack,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistTrackRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserPinsTable, List<UserPin>> _userPinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.userPins,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.userPins.playlistId),
  );

  $$UserPinsTableProcessedTableManager get userPinsRefs {
    final manager = $$UserPinsTableTableManager(
      $_db,
      $_db.userPins,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userPinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistTrackRefs(
    Expression<bool> Function($$PlaylistTrackTableFilterComposer f) f,
  ) {
    final $$PlaylistTrackTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTrack,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTrackTableFilterComposer(
            $db: $db,
            $table: $db.playlistTrack,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userPinsRefs(
    Expression<bool> Function($$UserPinsTableFilterComposer f) f,
  ) {
    final $$UserPinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableFilterComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  Expression<T> playlistTrackRefs<T extends Object>(
    Expression<T> Function($$PlaylistTrackTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTrackTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTrack,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTrackTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistTrack,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userPinsRefs<T extends Object>(
    Expression<T> Function($$UserPinsTableAnnotationComposer a) f,
  ) {
    final $$UserPinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPins,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPinsTableAnnotationComposer(
            $db: $db,
            $table: $db.userPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          PlaylistData,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (PlaylistData, $$PlaylistsTableReferences),
          PlaylistData,
          PrefetchHooks Function({bool playlistTrackRefs, bool userPinsRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
              }) =>
                  PlaylistsCompanion(id: id, name: name, coverPath: coverPath),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> coverPath = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                coverPath: coverPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistTrackRefs = false, userPinsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistTrackRefs) db.playlistTrack,
                    if (userPinsRefs) db.userPins,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistTrackRefs)
                        await $_getPrefetchedData<
                          PlaylistData,
                          $PlaylistsTable,
                          PlaylistTrackData
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._playlistTrackRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistTrackRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userPinsRefs)
                        await $_getPrefetchedData<
                          PlaylistData,
                          $PlaylistsTable,
                          UserPin
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._userPinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).userPinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      PlaylistData,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (PlaylistData, $$PlaylistsTableReferences),
      PlaylistData,
      PrefetchHooks Function({bool playlistTrackRefs, bool userPinsRefs})
    >;
typedef $$TrackArtistTableCreateCompanionBuilder =
    TrackArtistCompanion Function({
      required int trackId,
      required int artistId,
      Value<int> rowid,
    });
typedef $$TrackArtistTableUpdateCompanionBuilder =
    TrackArtistCompanion Function({
      Value<int> trackId,
      Value<int> artistId,
      Value<int> rowid,
    });

final class $$TrackArtistTableReferences
    extends BaseReferences<_$AppDatabase, $TrackArtistTable, TrackArtistData> {
  $$TrackArtistTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.trackArtist.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.artists.createAlias(
        $_aliasNameGenerator(db.trackArtist.artistId, db.artists.id),
      );

  $$ArtistsTableProcessedTableManager get artistId {
    final $_column = $_itemColumn<int>('artist_id')!;

    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackArtistTableFilterComposer
    extends Composer<_$AppDatabase, $TrackArtistTable> {
  $$TrackArtistTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackArtistTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackArtistTable> {
  $$TrackArtistTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackArtistTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackArtistTable> {
  $$TrackArtistTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackArtistTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackArtistTable,
          TrackArtistData,
          $$TrackArtistTableFilterComposer,
          $$TrackArtistTableOrderingComposer,
          $$TrackArtistTableAnnotationComposer,
          $$TrackArtistTableCreateCompanionBuilder,
          $$TrackArtistTableUpdateCompanionBuilder,
          (TrackArtistData, $$TrackArtistTableReferences),
          TrackArtistData,
          PrefetchHooks Function({bool trackId, bool artistId})
        > {
  $$TrackArtistTableTableManager(_$AppDatabase db, $TrackArtistTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackArtistTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackArtistTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackArtistTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<int> artistId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackArtistCompanion(
                trackId: trackId,
                artistId: artistId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int trackId,
                required int artistId,
                Value<int> rowid = const Value.absent(),
              }) => TrackArtistCompanion.insert(
                trackId: trackId,
                artistId: artistId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackArtistTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false, artistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable: $$TrackArtistTableReferences
                                    ._trackIdTable(db),
                                referencedColumn: $$TrackArtistTableReferences
                                    ._trackIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (artistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.artistId,
                                referencedTable: $$TrackArtistTableReferences
                                    ._artistIdTable(db),
                                referencedColumn: $$TrackArtistTableReferences
                                    ._artistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackArtistTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackArtistTable,
      TrackArtistData,
      $$TrackArtistTableFilterComposer,
      $$TrackArtistTableOrderingComposer,
      $$TrackArtistTableAnnotationComposer,
      $$TrackArtistTableCreateCompanionBuilder,
      $$TrackArtistTableUpdateCompanionBuilder,
      (TrackArtistData, $$TrackArtistTableReferences),
      TrackArtistData,
      PrefetchHooks Function({bool trackId, bool artistId})
    >;
typedef $$PlaylistTrackTableCreateCompanionBuilder =
    PlaylistTrackCompanion Function({
      required int playlistId,
      required int trackId,
      Value<DateTime> dateAdded,
      Value<int> rowid,
    });
typedef $$PlaylistTrackTableUpdateCompanionBuilder =
    PlaylistTrackCompanion Function({
      Value<int> playlistId,
      Value<int> trackId,
      Value<DateTime> dateAdded,
      Value<int> rowid,
    });

final class $$PlaylistTrackTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlaylistTrackTable, PlaylistTrackData> {
  $$PlaylistTrackTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.playlistTrack.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.playlistTrack.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistTrackTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTrackTable> {
  $$PlaylistTrackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTrackTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTrackTable> {
  $$PlaylistTrackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTrackTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTrackTable> {
  $$PlaylistTrackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTrackTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistTrackTable,
          PlaylistTrackData,
          $$PlaylistTrackTableFilterComposer,
          $$PlaylistTrackTableOrderingComposer,
          $$PlaylistTrackTableAnnotationComposer,
          $$PlaylistTrackTableCreateCompanionBuilder,
          $$PlaylistTrackTableUpdateCompanionBuilder,
          (PlaylistTrackData, $$PlaylistTrackTableReferences),
          PlaylistTrackData,
          PrefetchHooks Function({bool playlistId, bool trackId})
        > {
  $$PlaylistTrackTableTableManager(_$AppDatabase db, $PlaylistTrackTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTrackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTrackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTrackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTrackCompanion(
                playlistId: playlistId,
                trackId: trackId,
                dateAdded: dateAdded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required int trackId,
                Value<DateTime> dateAdded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTrackCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                dateAdded: dateAdded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistTrackTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$PlaylistTrackTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$PlaylistTrackTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable: $$PlaylistTrackTableReferences
                                    ._trackIdTable(db),
                                referencedColumn: $$PlaylistTrackTableReferences
                                    ._trackIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistTrackTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistTrackTable,
      PlaylistTrackData,
      $$PlaylistTrackTableFilterComposer,
      $$PlaylistTrackTableOrderingComposer,
      $$PlaylistTrackTableAnnotationComposer,
      $$PlaylistTrackTableCreateCompanionBuilder,
      $$PlaylistTrackTableUpdateCompanionBuilder,
      (PlaylistTrackData, $$PlaylistTrackTableReferences),
      PlaylistTrackData,
      PrefetchHooks Function({bool playlistId, bool trackId})
    >;
typedef $$QueueEntriesTableCreateCompanionBuilder =
    QueueEntriesCompanion Function({
      Value<int> originalQueueIndex,
      required int trackId,
      Value<bool> isCurrentlyPlaying,
      Value<int> resumePositionMs,
      required String playbackContextType,
      Value<int?> playbackContextId,
    });
typedef $$QueueEntriesTableUpdateCompanionBuilder =
    QueueEntriesCompanion Function({
      Value<int> originalQueueIndex,
      Value<int> trackId,
      Value<bool> isCurrentlyPlaying,
      Value<int> resumePositionMs,
      Value<String> playbackContextType,
      Value<int?> playbackContextId,
    });

final class $$QueueEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $QueueEntriesTable, QueueEntry> {
  $$QueueEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.queueEntries.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get originalQueueIndex => $composableBuilder(
    column: $table.originalQueueIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrentlyPlaying => $composableBuilder(
    column: $table.isCurrentlyPlaying,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resumePositionMs => $composableBuilder(
    column: $table.resumePositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playbackContextType => $composableBuilder(
    column: $table.playbackContextType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackContextId => $composableBuilder(
    column: $table.playbackContextId,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get originalQueueIndex => $composableBuilder(
    column: $table.originalQueueIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrentlyPlaying => $composableBuilder(
    column: $table.isCurrentlyPlaying,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resumePositionMs => $composableBuilder(
    column: $table.resumePositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playbackContextType => $composableBuilder(
    column: $table.playbackContextType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackContextId => $composableBuilder(
    column: $table.playbackContextId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get originalQueueIndex => $composableBuilder(
    column: $table.originalQueueIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrentlyPlaying => $composableBuilder(
    column: $table.isCurrentlyPlaying,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resumePositionMs => $composableBuilder(
    column: $table.resumePositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playbackContextType => $composableBuilder(
    column: $table.playbackContextType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackContextId => $composableBuilder(
    column: $table.playbackContextId,
    builder: (column) => column,
  );

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueEntriesTable,
          QueueEntry,
          $$QueueEntriesTableFilterComposer,
          $$QueueEntriesTableOrderingComposer,
          $$QueueEntriesTableAnnotationComposer,
          $$QueueEntriesTableCreateCompanionBuilder,
          $$QueueEntriesTableUpdateCompanionBuilder,
          (QueueEntry, $$QueueEntriesTableReferences),
          QueueEntry,
          PrefetchHooks Function({bool trackId})
        > {
  $$QueueEntriesTableTableManager(_$AppDatabase db, $QueueEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> originalQueueIndex = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<bool> isCurrentlyPlaying = const Value.absent(),
                Value<int> resumePositionMs = const Value.absent(),
                Value<String> playbackContextType = const Value.absent(),
                Value<int?> playbackContextId = const Value.absent(),
              }) => QueueEntriesCompanion(
                originalQueueIndex: originalQueueIndex,
                trackId: trackId,
                isCurrentlyPlaying: isCurrentlyPlaying,
                resumePositionMs: resumePositionMs,
                playbackContextType: playbackContextType,
                playbackContextId: playbackContextId,
              ),
          createCompanionCallback:
              ({
                Value<int> originalQueueIndex = const Value.absent(),
                required int trackId,
                Value<bool> isCurrentlyPlaying = const Value.absent(),
                Value<int> resumePositionMs = const Value.absent(),
                required String playbackContextType,
                Value<int?> playbackContextId = const Value.absent(),
              }) => QueueEntriesCompanion.insert(
                originalQueueIndex: originalQueueIndex,
                trackId: trackId,
                isCurrentlyPlaying: isCurrentlyPlaying,
                resumePositionMs: resumePositionMs,
                playbackContextType: playbackContextType,
                playbackContextId: playbackContextId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QueueEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable: $$QueueEntriesTableReferences
                                    ._trackIdTable(db),
                                referencedColumn: $$QueueEntriesTableReferences
                                    ._trackIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueEntriesTable,
      QueueEntry,
      $$QueueEntriesTableFilterComposer,
      $$QueueEntriesTableOrderingComposer,
      $$QueueEntriesTableAnnotationComposer,
      $$QueueEntriesTableCreateCompanionBuilder,
      $$QueueEntriesTableUpdateCompanionBuilder,
      (QueueEntry, $$QueueEntriesTableReferences),
      QueueEntry,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      required int trackId,
      Value<DateTime> startedAt,
      Value<int> durationListenedMs,
      Value<bool> isSkipped,
      Value<String?> playbackContextType,
      Value<int?> playbackContextId,
    });
typedef $$PlayHistoryTableUpdateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<int> trackId,
      Value<DateTime> startedAt,
      Value<int> durationListenedMs,
      Value<bool> isSkipped,
      Value<String?> playbackContextType,
      Value<int?> playbackContextId,
    });

final class $$PlayHistoryTableReferences
    extends BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData> {
  $$PlayHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.playHistory.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationListenedMs => $composableBuilder(
    column: $table.durationListenedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playbackContextType => $composableBuilder(
    column: $table.playbackContextType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackContextId => $composableBuilder(
    column: $table.playbackContextId,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationListenedMs => $composableBuilder(
    column: $table.durationListenedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playbackContextType => $composableBuilder(
    column: $table.playbackContextType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackContextId => $composableBuilder(
    column: $table.playbackContextId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationListenedMs => $composableBuilder(
    column: $table.durationListenedMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSkipped =>
      $composableBuilder(column: $table.isSkipped, builder: (column) => column);

  GeneratedColumn<String> get playbackContextType => $composableBuilder(
    column: $table.playbackContextType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackContextId => $composableBuilder(
    column: $table.playbackContextId,
    builder: (column) => column,
  );

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayHistoryTable,
          PlayHistoryData,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (PlayHistoryData, $$PlayHistoryTableReferences),
          PlayHistoryData,
          PrefetchHooks Function({bool trackId})
        > {
  $$PlayHistoryTableTableManager(_$AppDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> durationListenedMs = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<String?> playbackContextType = const Value.absent(),
                Value<int?> playbackContextId = const Value.absent(),
              }) => PlayHistoryCompanion(
                id: id,
                trackId: trackId,
                startedAt: startedAt,
                durationListenedMs: durationListenedMs,
                isSkipped: isSkipped,
                playbackContextType: playbackContextType,
                playbackContextId: playbackContextId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> durationListenedMs = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<String?> playbackContextType = const Value.absent(),
                Value<int?> playbackContextId = const Value.absent(),
              }) => PlayHistoryCompanion.insert(
                id: id,
                trackId: trackId,
                startedAt: startedAt,
                durationListenedMs: durationListenedMs,
                isSkipped: isSkipped,
                playbackContextType: playbackContextType,
                playbackContextId: playbackContextId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable: $$PlayHistoryTableReferences
                                    ._trackIdTable(db),
                                referencedColumn: $$PlayHistoryTableReferences
                                    ._trackIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayHistoryTable,
      PlayHistoryData,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (PlayHistoryData, $$PlayHistoryTableReferences),
      PlayHistoryData,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$SourcePrioritiesTableCreateCompanionBuilder =
    SourcePrioritiesCompanion Function({
      required String source,
      required int priorityRank,
      Value<int> rowid,
    });
typedef $$SourcePrioritiesTableUpdateCompanionBuilder =
    SourcePrioritiesCompanion Function({
      Value<String> source,
      Value<int> priorityRank,
      Value<int> rowid,
    });

class $$SourcePrioritiesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcePrioritiesTable> {
  $$SourcePrioritiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priorityRank => $composableBuilder(
    column: $table.priorityRank,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcePrioritiesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcePrioritiesTable> {
  $$SourcePrioritiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priorityRank => $composableBuilder(
    column: $table.priorityRank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcePrioritiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcePrioritiesTable> {
  $$SourcePrioritiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get priorityRank => $composableBuilder(
    column: $table.priorityRank,
    builder: (column) => column,
  );
}

class $$SourcePrioritiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcePrioritiesTable,
          SourcePriority,
          $$SourcePrioritiesTableFilterComposer,
          $$SourcePrioritiesTableOrderingComposer,
          $$SourcePrioritiesTableAnnotationComposer,
          $$SourcePrioritiesTableCreateCompanionBuilder,
          $$SourcePrioritiesTableUpdateCompanionBuilder,
          (
            SourcePriority,
            BaseReferences<
              _$AppDatabase,
              $SourcePrioritiesTable,
              SourcePriority
            >,
          ),
          SourcePriority,
          PrefetchHooks Function()
        > {
  $$SourcePrioritiesTableTableManager(
    _$AppDatabase db,
    $SourcePrioritiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcePrioritiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcePrioritiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcePrioritiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> source = const Value.absent(),
                Value<int> priorityRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcePrioritiesCompanion(
                source: source,
                priorityRank: priorityRank,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String source,
                required int priorityRank,
                Value<int> rowid = const Value.absent(),
              }) => SourcePrioritiesCompanion.insert(
                source: source,
                priorityRank: priorityRank,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourcePrioritiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcePrioritiesTable,
      SourcePriority,
      $$SourcePrioritiesTableFilterComposer,
      $$SourcePrioritiesTableOrderingComposer,
      $$SourcePrioritiesTableAnnotationComposer,
      $$SourcePrioritiesTableCreateCompanionBuilder,
      $$SourcePrioritiesTableUpdateCompanionBuilder,
      (
        SourcePriority,
        BaseReferences<_$AppDatabase, $SourcePrioritiesTable, SourcePriority>,
      ),
      SourcePriority,
      PrefetchHooks Function()
    >;
typedef $$ArtistMetadataTableCreateCompanionBuilder =
    ArtistMetadataCompanion Function({
      Value<int> id,
      required int artistId,
      required String source,
      Value<String?> imageUrl,
      Value<String?> localPath,
      Value<String?> biography,
      Value<String?> externalUrl,
      Value<DateTime> lastFetched,
      Value<bool> isUserSelected,
    });
typedef $$ArtistMetadataTableUpdateCompanionBuilder =
    ArtistMetadataCompanion Function({
      Value<int> id,
      Value<int> artistId,
      Value<String> source,
      Value<String?> imageUrl,
      Value<String?> localPath,
      Value<String?> biography,
      Value<String?> externalUrl,
      Value<DateTime> lastFetched,
      Value<bool> isUserSelected,
    });

final class $$ArtistMetadataTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ArtistMetadataTable,
          ArtistMetadataData
        > {
  $$ArtistMetadataTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.artists.createAlias(
        $_aliasNameGenerator(db.artistMetadata.artistId, db.artists.id),
      );

  $$ArtistsTableProcessedTableManager get artistId {
    final $_column = $_itemColumn<int>('artist_id')!;

    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArtistMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistMetadataTable> {
  $$ArtistMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalUrl => $composableBuilder(
    column: $table.externalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserSelected => $composableBuilder(
    column: $table.isUserSelected,
    builder: (column) => ColumnFilters(column),
  );

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistMetadataTable> {
  $$ArtistMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalUrl => $composableBuilder(
    column: $table.externalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserSelected => $composableBuilder(
    column: $table.isUserSelected,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistMetadataTable> {
  $$ArtistMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get biography =>
      $composableBuilder(column: $table.biography, builder: (column) => column);

  GeneratedColumn<String> get externalUrl => $composableBuilder(
    column: $table.externalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUserSelected => $composableBuilder(
    column: $table.isUserSelected,
    builder: (column) => column,
  );

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistMetadataTable,
          ArtistMetadataData,
          $$ArtistMetadataTableFilterComposer,
          $$ArtistMetadataTableOrderingComposer,
          $$ArtistMetadataTableAnnotationComposer,
          $$ArtistMetadataTableCreateCompanionBuilder,
          $$ArtistMetadataTableUpdateCompanionBuilder,
          (ArtistMetadataData, $$ArtistMetadataTableReferences),
          ArtistMetadataData,
          PrefetchHooks Function({bool artistId})
        > {
  $$ArtistMetadataTableTableManager(
    _$AppDatabase db,
    $ArtistMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> artistId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<String?> externalUrl = const Value.absent(),
                Value<DateTime> lastFetched = const Value.absent(),
                Value<bool> isUserSelected = const Value.absent(),
              }) => ArtistMetadataCompanion(
                id: id,
                artistId: artistId,
                source: source,
                imageUrl: imageUrl,
                localPath: localPath,
                biography: biography,
                externalUrl: externalUrl,
                lastFetched: lastFetched,
                isUserSelected: isUserSelected,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int artistId,
                required String source,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<String?> externalUrl = const Value.absent(),
                Value<DateTime> lastFetched = const Value.absent(),
                Value<bool> isUserSelected = const Value.absent(),
              }) => ArtistMetadataCompanion.insert(
                id: id,
                artistId: artistId,
                source: source,
                imageUrl: imageUrl,
                localPath: localPath,
                biography: biography,
                externalUrl: externalUrl,
                lastFetched: lastFetched,
                isUserSelected: isUserSelected,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArtistMetadataTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({artistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (artistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.artistId,
                                referencedTable: $$ArtistMetadataTableReferences
                                    ._artistIdTable(db),
                                referencedColumn:
                                    $$ArtistMetadataTableReferences
                                        ._artistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ArtistMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistMetadataTable,
      ArtistMetadataData,
      $$ArtistMetadataTableFilterComposer,
      $$ArtistMetadataTableOrderingComposer,
      $$ArtistMetadataTableAnnotationComposer,
      $$ArtistMetadataTableCreateCompanionBuilder,
      $$ArtistMetadataTableUpdateCompanionBuilder,
      (ArtistMetadataData, $$ArtistMetadataTableReferences),
      ArtistMetadataData,
      PrefetchHooks Function({bool artistId})
    >;
typedef $$AlbumMetadataTableCreateCompanionBuilder =
    AlbumMetadataCompanion Function({
      Value<int> id,
      required int albumId,
      required String source,
      Value<String?> albumArtUrl,
      Value<String?> localPath,
      Value<String?> releaseType,
      Value<int?> popularity,
      Value<bool> isUserSelected,
    });
typedef $$AlbumMetadataTableUpdateCompanionBuilder =
    AlbumMetadataCompanion Function({
      Value<int> id,
      Value<int> albumId,
      Value<String> source,
      Value<String?> albumArtUrl,
      Value<String?> localPath,
      Value<String?> releaseType,
      Value<int?> popularity,
      Value<bool> isUserSelected,
    });

final class $$AlbumMetadataTableReferences
    extends
        BaseReferences<_$AppDatabase, $AlbumMetadataTable, AlbumMetadataData> {
  $$AlbumMetadataTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AlbumsTable _albumIdTable(_$AppDatabase db) => db.albums.createAlias(
    $_aliasNameGenerator(db.albumMetadata.albumId, db.albums.id),
  );

  $$AlbumsTableProcessedTableManager get albumId {
    final $_column = $_itemColumn<int>('album_id')!;

    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlbumMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumMetadataTable> {
  $$AlbumMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtUrl => $composableBuilder(
    column: $table.albumArtUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseType => $composableBuilder(
    column: $table.releaseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserSelected => $composableBuilder(
    column: $table.isUserSelected,
    builder: (column) => ColumnFilters(column),
  );

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumMetadataTable> {
  $$AlbumMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtUrl => $composableBuilder(
    column: $table.albumArtUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseType => $composableBuilder(
    column: $table.releaseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserSelected => $composableBuilder(
    column: $table.isUserSelected,
    builder: (column) => ColumnOrderings(column),
  );

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumMetadataTable> {
  $$AlbumMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get albumArtUrl => $composableBuilder(
    column: $table.albumArtUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get releaseType => $composableBuilder(
    column: $table.releaseType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUserSelected => $composableBuilder(
    column: $table.isUserSelected,
    builder: (column) => column,
  );

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumMetadataTable,
          AlbumMetadataData,
          $$AlbumMetadataTableFilterComposer,
          $$AlbumMetadataTableOrderingComposer,
          $$AlbumMetadataTableAnnotationComposer,
          $$AlbumMetadataTableCreateCompanionBuilder,
          $$AlbumMetadataTableUpdateCompanionBuilder,
          (AlbumMetadataData, $$AlbumMetadataTableReferences),
          AlbumMetadataData,
          PrefetchHooks Function({bool albumId})
        > {
  $$AlbumMetadataTableTableManager(_$AppDatabase db, $AlbumMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> albumId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> albumArtUrl = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> releaseType = const Value.absent(),
                Value<int?> popularity = const Value.absent(),
                Value<bool> isUserSelected = const Value.absent(),
              }) => AlbumMetadataCompanion(
                id: id,
                albumId: albumId,
                source: source,
                albumArtUrl: albumArtUrl,
                localPath: localPath,
                releaseType: releaseType,
                popularity: popularity,
                isUserSelected: isUserSelected,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int albumId,
                required String source,
                Value<String?> albumArtUrl = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> releaseType = const Value.absent(),
                Value<int?> popularity = const Value.absent(),
                Value<bool> isUserSelected = const Value.absent(),
              }) => AlbumMetadataCompanion.insert(
                id: id,
                albumId: albumId,
                source: source,
                albumArtUrl: albumArtUrl,
                localPath: localPath,
                releaseType: releaseType,
                popularity: popularity,
                isUserSelected: isUserSelected,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AlbumMetadataTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({albumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (albumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.albumId,
                                referencedTable: $$AlbumMetadataTableReferences
                                    ._albumIdTable(db),
                                referencedColumn: $$AlbumMetadataTableReferences
                                    ._albumIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlbumMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumMetadataTable,
      AlbumMetadataData,
      $$AlbumMetadataTableFilterComposer,
      $$AlbumMetadataTableOrderingComposer,
      $$AlbumMetadataTableAnnotationComposer,
      $$AlbumMetadataTableCreateCompanionBuilder,
      $$AlbumMetadataTableUpdateCompanionBuilder,
      (AlbumMetadataData, $$AlbumMetadataTableReferences),
      AlbumMetadataData,
      PrefetchHooks Function({bool albumId})
    >;
typedef $$UserFavoritesTableCreateCompanionBuilder =
    UserFavoritesCompanion Function({
      Value<int> id,
      Value<int?> trackId,
      Value<int?> albumId,
      Value<int?> artistId,
      Value<DateTime> dateAdded,
    });
typedef $$UserFavoritesTableUpdateCompanionBuilder =
    UserFavoritesCompanion Function({
      Value<int> id,
      Value<int?> trackId,
      Value<int?> albumId,
      Value<int?> artistId,
      Value<DateTime> dateAdded,
    });

final class $$UserFavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $UserFavoritesTable, UserFavorite> {
  $$UserFavoritesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.userFavorites.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager? get trackId {
    final $_column = $_itemColumn<int>('track_id');
    if ($_column == null) return null;
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlbumsTable _albumIdTable(_$AppDatabase db) => db.albums.createAlias(
    $_aliasNameGenerator(db.userFavorites.albumId, db.albums.id),
  );

  $$AlbumsTableProcessedTableManager? get albumId {
    final $_column = $_itemColumn<int>('album_id');
    if ($_column == null) return null;
    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.artists.createAlias(
        $_aliasNameGenerator(db.userFavorites.artistId, db.artists.id),
      );

  $$ArtistsTableProcessedTableManager? get artistId {
    final $_column = $_itemColumn<int>('artist_id');
    if ($_column == null) return null;
    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $UserFavoritesTable> {
  $$UserFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserFavoritesTable> {
  $$UserFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserFavoritesTable> {
  $$UserFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserFavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserFavoritesTable,
          UserFavorite,
          $$UserFavoritesTableFilterComposer,
          $$UserFavoritesTableOrderingComposer,
          $$UserFavoritesTableAnnotationComposer,
          $$UserFavoritesTableCreateCompanionBuilder,
          $$UserFavoritesTableUpdateCompanionBuilder,
          (UserFavorite, $$UserFavoritesTableReferences),
          UserFavorite,
          PrefetchHooks Function({bool trackId, bool albumId, bool artistId})
        > {
  $$UserFavoritesTableTableManager(_$AppDatabase db, $UserFavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => UserFavoritesCompanion(
                id: id,
                trackId: trackId,
                albumId: albumId,
                artistId: artistId,
                dateAdded: dateAdded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => UserFavoritesCompanion.insert(
                id: id,
                trackId: trackId,
                albumId: albumId,
                artistId: artistId,
                dateAdded: dateAdded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserFavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({trackId = false, albumId = false, artistId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (trackId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.trackId,
                                    referencedTable:
                                        $$UserFavoritesTableReferences
                                            ._trackIdTable(db),
                                    referencedColumn:
                                        $$UserFavoritesTableReferences
                                            ._trackIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (albumId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.albumId,
                                    referencedTable:
                                        $$UserFavoritesTableReferences
                                            ._albumIdTable(db),
                                    referencedColumn:
                                        $$UserFavoritesTableReferences
                                            ._albumIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (artistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.artistId,
                                    referencedTable:
                                        $$UserFavoritesTableReferences
                                            ._artistIdTable(db),
                                    referencedColumn:
                                        $$UserFavoritesTableReferences
                                            ._artistIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$UserFavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserFavoritesTable,
      UserFavorite,
      $$UserFavoritesTableFilterComposer,
      $$UserFavoritesTableOrderingComposer,
      $$UserFavoritesTableAnnotationComposer,
      $$UserFavoritesTableCreateCompanionBuilder,
      $$UserFavoritesTableUpdateCompanionBuilder,
      (UserFavorite, $$UserFavoritesTableReferences),
      UserFavorite,
      PrefetchHooks Function({bool trackId, bool albumId, bool artistId})
    >;
typedef $$UserBlacklistTableCreateCompanionBuilder =
    UserBlacklistCompanion Function({
      Value<int> id,
      Value<int?> trackId,
      Value<int?> albumId,
      Value<int?> artistId,
      Value<DateTime> dateAdded,
    });
typedef $$UserBlacklistTableUpdateCompanionBuilder =
    UserBlacklistCompanion Function({
      Value<int> id,
      Value<int?> trackId,
      Value<int?> albumId,
      Value<int?> artistId,
      Value<DateTime> dateAdded,
    });

final class $$UserBlacklistTableReferences
    extends
        BaseReferences<_$AppDatabase, $UserBlacklistTable, UserBlacklistData> {
  $$UserBlacklistTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.userBlacklist.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager? get trackId {
    final $_column = $_itemColumn<int>('track_id');
    if ($_column == null) return null;
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlbumsTable _albumIdTable(_$AppDatabase db) => db.albums.createAlias(
    $_aliasNameGenerator(db.userBlacklist.albumId, db.albums.id),
  );

  $$AlbumsTableProcessedTableManager? get albumId {
    final $_column = $_itemColumn<int>('album_id');
    if ($_column == null) return null;
    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.artists.createAlias(
        $_aliasNameGenerator(db.userBlacklist.artistId, db.artists.id),
      );

  $$ArtistsTableProcessedTableManager? get artistId {
    final $_column = $_itemColumn<int>('artist_id');
    if ($_column == null) return null;
    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserBlacklistTableFilterComposer
    extends Composer<_$AppDatabase, $UserBlacklistTable> {
  $$UserBlacklistTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserBlacklistTableOrderingComposer
    extends Composer<_$AppDatabase, $UserBlacklistTable> {
  $$UserBlacklistTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserBlacklistTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserBlacklistTable> {
  $$UserBlacklistTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserBlacklistTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserBlacklistTable,
          UserBlacklistData,
          $$UserBlacklistTableFilterComposer,
          $$UserBlacklistTableOrderingComposer,
          $$UserBlacklistTableAnnotationComposer,
          $$UserBlacklistTableCreateCompanionBuilder,
          $$UserBlacklistTableUpdateCompanionBuilder,
          (UserBlacklistData, $$UserBlacklistTableReferences),
          UserBlacklistData,
          PrefetchHooks Function({bool trackId, bool albumId, bool artistId})
        > {
  $$UserBlacklistTableTableManager(_$AppDatabase db, $UserBlacklistTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserBlacklistTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserBlacklistTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserBlacklistTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => UserBlacklistCompanion(
                id: id,
                trackId: trackId,
                albumId: albumId,
                artistId: artistId,
                dateAdded: dateAdded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => UserBlacklistCompanion.insert(
                id: id,
                trackId: trackId,
                albumId: albumId,
                artistId: artistId,
                dateAdded: dateAdded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserBlacklistTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({trackId = false, albumId = false, artistId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (trackId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.trackId,
                                    referencedTable:
                                        $$UserBlacklistTableReferences
                                            ._trackIdTable(db),
                                    referencedColumn:
                                        $$UserBlacklistTableReferences
                                            ._trackIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (albumId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.albumId,
                                    referencedTable:
                                        $$UserBlacklistTableReferences
                                            ._albumIdTable(db),
                                    referencedColumn:
                                        $$UserBlacklistTableReferences
                                            ._albumIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (artistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.artistId,
                                    referencedTable:
                                        $$UserBlacklistTableReferences
                                            ._artistIdTable(db),
                                    referencedColumn:
                                        $$UserBlacklistTableReferences
                                            ._artistIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$UserBlacklistTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserBlacklistTable,
      UserBlacklistData,
      $$UserBlacklistTableFilterComposer,
      $$UserBlacklistTableOrderingComposer,
      $$UserBlacklistTableAnnotationComposer,
      $$UserBlacklistTableCreateCompanionBuilder,
      $$UserBlacklistTableUpdateCompanionBuilder,
      (UserBlacklistData, $$UserBlacklistTableReferences),
      UserBlacklistData,
      PrefetchHooks Function({bool trackId, bool albumId, bool artistId})
    >;
typedef $$UserPinsTableCreateCompanionBuilder =
    UserPinsCompanion Function({
      Value<int> id,
      Value<int?> trackId,
      Value<int?> albumId,
      Value<int?> artistId,
      Value<int?> playlistId,
      Value<int> sortOrder,
    });
typedef $$UserPinsTableUpdateCompanionBuilder =
    UserPinsCompanion Function({
      Value<int> id,
      Value<int?> trackId,
      Value<int?> albumId,
      Value<int?> artistId,
      Value<int?> playlistId,
      Value<int> sortOrder,
    });

final class $$UserPinsTableReferences
    extends BaseReferences<_$AppDatabase, $UserPinsTable, UserPin> {
  $$UserPinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.userPins.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager? get trackId {
    final $_column = $_itemColumn<int>('track_id');
    if ($_column == null) return null;
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlbumsTable _albumIdTable(_$AppDatabase db) => db.albums.createAlias(
    $_aliasNameGenerator(db.userPins.albumId, db.albums.id),
  );

  $$AlbumsTableProcessedTableManager? get albumId {
    final $_column = $_itemColumn<int>('album_id');
    if ($_column == null) return null;
    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArtistsTable _artistIdTable(_$AppDatabase db) => db.artists
      .createAlias($_aliasNameGenerator(db.userPins.artistId, db.artists.id));

  $$ArtistsTableProcessedTableManager? get artistId {
    final $_column = $_itemColumn<int>('artist_id');
    if ($_column == null) return null;
    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.userPins.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager? get playlistId {
    final $_column = $_itemColumn<int>('playlist_id');
    if ($_column == null) return null;
    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserPinsTableFilterComposer
    extends Composer<_$AppDatabase, $UserPinsTable> {
  $$UserPinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPinsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPinsTable> {
  $$UserPinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPinsTable> {
  $$UserPinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPinsTable,
          UserPin,
          $$UserPinsTableFilterComposer,
          $$UserPinsTableOrderingComposer,
          $$UserPinsTableAnnotationComposer,
          $$UserPinsTableCreateCompanionBuilder,
          $$UserPinsTableUpdateCompanionBuilder,
          (UserPin, $$UserPinsTableReferences),
          UserPin,
          PrefetchHooks Function({
            bool trackId,
            bool albumId,
            bool artistId,
            bool playlistId,
          })
        > {
  $$UserPinsTableTableManager(_$AppDatabase db, $UserPinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<int?> playlistId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => UserPinsCompanion(
                id: id,
                trackId: trackId,
                albumId: albumId,
                artistId: artistId,
                playlistId: playlistId,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<int?> playlistId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => UserPinsCompanion.insert(
                id: id,
                trackId: trackId,
                albumId: albumId,
                artistId: artistId,
                playlistId: playlistId,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserPinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                trackId = false,
                albumId = false,
                artistId = false,
                playlistId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (trackId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.trackId,
                                    referencedTable: $$UserPinsTableReferences
                                        ._trackIdTable(db),
                                    referencedColumn: $$UserPinsTableReferences
                                        ._trackIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (albumId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.albumId,
                                    referencedTable: $$UserPinsTableReferences
                                        ._albumIdTable(db),
                                    referencedColumn: $$UserPinsTableReferences
                                        ._albumIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (artistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.artistId,
                                    referencedTable: $$UserPinsTableReferences
                                        ._artistIdTable(db),
                                    referencedColumn: $$UserPinsTableReferences
                                        ._artistIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (playlistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.playlistId,
                                    referencedTable: $$UserPinsTableReferences
                                        ._playlistIdTable(db),
                                    referencedColumn: $$UserPinsTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$UserPinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPinsTable,
      UserPin,
      $$UserPinsTableFilterComposer,
      $$UserPinsTableOrderingComposer,
      $$UserPinsTableAnnotationComposer,
      $$UserPinsTableCreateCompanionBuilder,
      $$UserPinsTableUpdateCompanionBuilder,
      (UserPin, $$UserPinsTableReferences),
      UserPin,
      PrefetchHooks Function({
        bool trackId,
        bool albumId,
        bool artistId,
        bool playlistId,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArtistsTableTableManager get artists =>
      $$ArtistsTableTableManager(_db, _db.artists);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$TrackArtistTableTableManager get trackArtist =>
      $$TrackArtistTableTableManager(_db, _db.trackArtist);
  $$PlaylistTrackTableTableManager get playlistTrack =>
      $$PlaylistTrackTableTableManager(_db, _db.playlistTrack);
  $$QueueEntriesTableTableManager get queueEntries =>
      $$QueueEntriesTableTableManager(_db, _db.queueEntries);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
  $$SourcePrioritiesTableTableManager get sourcePriorities =>
      $$SourcePrioritiesTableTableManager(_db, _db.sourcePriorities);
  $$ArtistMetadataTableTableManager get artistMetadata =>
      $$ArtistMetadataTableTableManager(_db, _db.artistMetadata);
  $$AlbumMetadataTableTableManager get albumMetadata =>
      $$AlbumMetadataTableTableManager(_db, _db.albumMetadata);
  $$UserFavoritesTableTableManager get userFavorites =>
      $$UserFavoritesTableTableManager(_db, _db.userFavorites);
  $$UserBlacklistTableTableManager get userBlacklist =>
      $$UserBlacklistTableTableManager(_db, _db.userBlacklist);
  $$UserPinsTableTableManager get userPins =>
      $$UserPinsTableTableManager(_db, _db.userPins);
}
