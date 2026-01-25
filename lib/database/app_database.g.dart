// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, SongEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<int> songId = GeneratedColumn<int>(
    'song_id',
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
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [songId, title, artist, path, duration];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SongEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  SongEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SongEntity(
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }
}

class SongEntity extends DataClass implements Insertable<SongEntity> {
  final int songId;
  final String title;
  final String artist;
  final String path;
  final int duration;
  const SongEntity({
    required this.songId,
    required this.title,
    required this.artist,
    required this.path,
    required this.duration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<int>(songId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['path'] = Variable<String>(path);
    map['duration'] = Variable<int>(duration);
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      songId: Value(songId),
      title: Value(title),
      artist: Value(artist),
      path: Value(path),
      duration: Value(duration),
    );
  }

  factory SongEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SongEntity(
      songId: serializer.fromJson<int>(json['songId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      path: serializer.fromJson<String>(json['path']),
      duration: serializer.fromJson<int>(json['duration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<int>(songId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'path': serializer.toJson<String>(path),
      'duration': serializer.toJson<int>(duration),
    };
  }

  SongEntity copyWith({
    int? songId,
    String? title,
    String? artist,
    String? path,
    int? duration,
  }) => SongEntity(
    songId: songId ?? this.songId,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    path: path ?? this.path,
    duration: duration ?? this.duration,
  );
  SongEntity copyWithCompanion(SongsCompanion data) {
    return SongEntity(
      songId: data.songId.present ? data.songId.value : this.songId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      path: data.path.present ? data.path.value : this.path,
      duration: data.duration.present ? data.duration.value : this.duration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SongEntity(')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('path: $path, ')
          ..write('duration: $duration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(songId, title, artist, path, duration);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SongEntity &&
          other.songId == this.songId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.path == this.path &&
          other.duration == this.duration);
}

class SongsCompanion extends UpdateCompanion<SongEntity> {
  final Value<int> songId;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> path;
  final Value<int> duration;
  const SongsCompanion({
    this.songId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.path = const Value.absent(),
    this.duration = const Value.absent(),
  });
  SongsCompanion.insert({
    this.songId = const Value.absent(),
    required String title,
    required String artist,
    required String path,
    this.duration = const Value.absent(),
  }) : title = Value(title),
       artist = Value(artist),
       path = Value(path);
  static Insertable<SongEntity> custom({
    Expression<int>? songId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? path,
    Expression<int>? duration,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (path != null) 'path': path,
      if (duration != null) 'duration': duration,
    });
  }

  SongsCompanion copyWith({
    Value<int>? songId,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? path,
    Value<int>? duration,
  }) {
    return SongsCompanion(
      songId: songId ?? this.songId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      path: path ?? this.path,
      duration: duration ?? this.duration,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<int>(songId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('path: $path, ')
          ..write('duration: $duration')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [songs];
}

typedef $$SongsTableCreateCompanionBuilder =
    SongsCompanion Function({
      Value<int> songId,
      required String title,
      required String artist,
      required String path,
      Value<int> duration,
    });
typedef $$SongsTableUpdateCompanionBuilder =
    SongsCompanion Function({
      Value<int> songId,
      Value<String> title,
      Value<String> artist,
      Value<String> path,
      Value<int> duration,
    });

class $$SongsTableFilterComposer extends Composer<_$Database, $SongsTable> {
  $$SongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SongsTableOrderingComposer extends Composer<_$Database, $SongsTable> {
  $$SongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SongsTableAnnotationComposer extends Composer<_$Database, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);
}

class $$SongsTableTableManager
    extends
        RootTableManager<
          _$Database,
          $SongsTable,
          SongEntity,
          $$SongsTableFilterComposer,
          $$SongsTableOrderingComposer,
          $$SongsTableAnnotationComposer,
          $$SongsTableCreateCompanionBuilder,
          $$SongsTableUpdateCompanionBuilder,
          (SongEntity, BaseReferences<_$Database, $SongsTable, SongEntity>),
          SongEntity,
          PrefetchHooks Function()
        > {
  $$SongsTableTableManager(_$Database db, $SongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> duration = const Value.absent(),
              }) => SongsCompanion(
                songId: songId,
                title: title,
                artist: artist,
                path: path,
                duration: duration,
              ),
          createCompanionCallback:
              ({
                Value<int> songId = const Value.absent(),
                required String title,
                required String artist,
                required String path,
                Value<int> duration = const Value.absent(),
              }) => SongsCompanion.insert(
                songId: songId,
                title: title,
                artist: artist,
                path: path,
                duration: duration,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SongsTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $SongsTable,
      SongEntity,
      $$SongsTableFilterComposer,
      $$SongsTableOrderingComposer,
      $$SongsTableAnnotationComposer,
      $$SongsTableCreateCompanionBuilder,
      $$SongsTableUpdateCompanionBuilder,
      (SongEntity, BaseReferences<_$Database, $SongsTable, SongEntity>),
      SongEntity,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
}
