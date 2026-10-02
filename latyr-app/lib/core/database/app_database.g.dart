// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalCapturesTable extends LocalCaptures
    with TableInfo<$LocalCapturesTable, LocalCapture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCapturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverCaptureIdMeta = const VerificationMeta(
    'serverCaptureId',
  );
  @override
  late final GeneratedColumn<String> serverCaptureId = GeneratedColumn<String>(
    'server_capture_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalUrlMeta = const VerificationMeta(
    'originalUrl',
  );
  @override
  late final GeneratedColumn<String> originalUrl = GeneratedColumn<String>(
    'original_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('URL'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING_SYNC'),
  );
  static const VerificationMeta _intentMeta = const VerificationMeta('intent');
  @override
  late final GeneratedColumn<String> intent = GeneratedColumn<String>(
    'intent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalCaptionMeta = const VerificationMeta(
    'originalCaption',
  );
  @override
  late final GeneratedColumn<String> originalCaption = GeneratedColumn<String>(
    'original_caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioTranscriptMeta = const VerificationMeta(
    'audioTranscript',
  );
  @override
  late final GeneratedColumn<String> audioTranscript = GeneratedColumn<String>(
    'audio_transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationCopiesJsonMeta =
      const VerificationMeta('notificationCopiesJson');
  @override
  late final GeneratedColumn<String> notificationCopiesJson =
      GeneratedColumn<String>(
        'notification_copies_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _entitiesJsonMeta = const VerificationMeta(
    'entitiesJson',
  );
  @override
  late final GeneratedColumn<String> entitiesJson = GeneratedColumn<String>(
    'entities_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverCaptureId,
    originalUrl,
    contentType,
    status,
    intent,
    category,
    title,
    originalCaption,
    thumbnailUrl,
    audioTranscript,
    notificationCopiesJson,
    entitiesJson,
    createdAt,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCapture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_capture_id')) {
      context.handle(
        _serverCaptureIdMeta,
        serverCaptureId.isAcceptableOrUnknown(
          data['server_capture_id']!,
          _serverCaptureIdMeta,
        ),
      );
    }
    if (data.containsKey('original_url')) {
      context.handle(
        _originalUrlMeta,
        originalUrl.isAcceptableOrUnknown(
          data['original_url']!,
          _originalUrlMeta,
        ),
      );
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('intent')) {
      context.handle(
        _intentMeta,
        intent.isAcceptableOrUnknown(data['intent']!, _intentMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('original_caption')) {
      context.handle(
        _originalCaptionMeta,
        originalCaption.isAcceptableOrUnknown(
          data['original_caption']!,
          _originalCaptionMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('audio_transcript')) {
      context.handle(
        _audioTranscriptMeta,
        audioTranscript.isAcceptableOrUnknown(
          data['audio_transcript']!,
          _audioTranscriptMeta,
        ),
      );
    }
    if (data.containsKey('notification_copies_json')) {
      context.handle(
        _notificationCopiesJsonMeta,
        notificationCopiesJson.isAcceptableOrUnknown(
          data['notification_copies_json']!,
          _notificationCopiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('entities_json')) {
      context.handle(
        _entitiesJsonMeta,
        entitiesJson.isAcceptableOrUnknown(
          data['entities_json']!,
          _entitiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCapture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCapture(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverCaptureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_capture_id'],
      ),
      originalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_url'],
      ),
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      intent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intent'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      originalCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_caption'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      audioTranscript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_transcript'],
      ),
      notificationCopiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_copies_json'],
      ),
      entitiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entities_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $LocalCapturesTable createAlias(String alias) {
    return $LocalCapturesTable(attachedDatabase, alias);
  }
}

class LocalCapture extends DataClass implements Insertable<LocalCapture> {
  final String id;
  final String? serverCaptureId;
  final String? originalUrl;
  final String contentType;
  final String status;
  final String? intent;
  final String? category;
  final String? title;
  final String? originalCaption;
  final String? thumbnailUrl;
  final String? audioTranscript;
  final String? notificationCopiesJson;
  final String? entitiesJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  const LocalCapture({
    required this.id,
    this.serverCaptureId,
    this.originalUrl,
    required this.contentType,
    required this.status,
    this.intent,
    this.category,
    this.title,
    this.originalCaption,
    this.thumbnailUrl,
    this.audioTranscript,
    this.notificationCopiesJson,
    this.entitiesJson,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverCaptureId != null) {
      map['server_capture_id'] = Variable<String>(serverCaptureId);
    }
    if (!nullToAbsent || originalUrl != null) {
      map['original_url'] = Variable<String>(originalUrl);
    }
    map['content_type'] = Variable<String>(contentType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || intent != null) {
      map['intent'] = Variable<String>(intent);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || originalCaption != null) {
      map['original_caption'] = Variable<String>(originalCaption);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || audioTranscript != null) {
      map['audio_transcript'] = Variable<String>(audioTranscript);
    }
    if (!nullToAbsent || notificationCopiesJson != null) {
      map['notification_copies_json'] = Variable<String>(
        notificationCopiesJson,
      );
    }
    if (!nullToAbsent || entitiesJson != null) {
      map['entities_json'] = Variable<String>(entitiesJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocalCapturesCompanion toCompanion(bool nullToAbsent) {
    return LocalCapturesCompanion(
      id: Value(id),
      serverCaptureId: serverCaptureId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverCaptureId),
      originalUrl: originalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(originalUrl),
      contentType: Value(contentType),
      status: Value(status),
      intent: intent == null && nullToAbsent
          ? const Value.absent()
          : Value(intent),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      originalCaption: originalCaption == null && nullToAbsent
          ? const Value.absent()
          : Value(originalCaption),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      audioTranscript: audioTranscript == null && nullToAbsent
          ? const Value.absent()
          : Value(audioTranscript),
      notificationCopiesJson: notificationCopiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationCopiesJson),
      entitiesJson: entitiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(entitiesJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocalCapture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCapture(
      id: serializer.fromJson<String>(json['id']),
      serverCaptureId: serializer.fromJson<String?>(json['serverCaptureId']),
      originalUrl: serializer.fromJson<String?>(json['originalUrl']),
      contentType: serializer.fromJson<String>(json['contentType']),
      status: serializer.fromJson<String>(json['status']),
      intent: serializer.fromJson<String?>(json['intent']),
      category: serializer.fromJson<String?>(json['category']),
      title: serializer.fromJson<String?>(json['title']),
      originalCaption: serializer.fromJson<String?>(json['originalCaption']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      audioTranscript: serializer.fromJson<String?>(json['audioTranscript']),
      notificationCopiesJson: serializer.fromJson<String?>(
        json['notificationCopiesJson'],
      ),
      entitiesJson: serializer.fromJson<String?>(json['entitiesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverCaptureId': serializer.toJson<String?>(serverCaptureId),
      'originalUrl': serializer.toJson<String?>(originalUrl),
      'contentType': serializer.toJson<String>(contentType),
      'status': serializer.toJson<String>(status),
      'intent': serializer.toJson<String?>(intent),
      'category': serializer.toJson<String?>(category),
      'title': serializer.toJson<String?>(title),
      'originalCaption': serializer.toJson<String?>(originalCaption),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'audioTranscript': serializer.toJson<String?>(audioTranscript),
      'notificationCopiesJson': serializer.toJson<String?>(
        notificationCopiesJson,
      ),
      'entitiesJson': serializer.toJson<String?>(entitiesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocalCapture copyWith({
    String? id,
    Value<String?> serverCaptureId = const Value.absent(),
    Value<String?> originalUrl = const Value.absent(),
    String? contentType,
    String? status,
    Value<String?> intent = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> originalCaption = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> audioTranscript = const Value.absent(),
    Value<String?> notificationCopiesJson = const Value.absent(),
    Value<String?> entitiesJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => LocalCapture(
    id: id ?? this.id,
    serverCaptureId: serverCaptureId.present
        ? serverCaptureId.value
        : this.serverCaptureId,
    originalUrl: originalUrl.present ? originalUrl.value : this.originalUrl,
    contentType: contentType ?? this.contentType,
    status: status ?? this.status,
    intent: intent.present ? intent.value : this.intent,
    category: category.present ? category.value : this.category,
    title: title.present ? title.value : this.title,
    originalCaption: originalCaption.present
        ? originalCaption.value
        : this.originalCaption,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    audioTranscript: audioTranscript.present
        ? audioTranscript.value
        : this.audioTranscript,
    notificationCopiesJson: notificationCopiesJson.present
        ? notificationCopiesJson.value
        : this.notificationCopiesJson,
    entitiesJson: entitiesJson.present ? entitiesJson.value : this.entitiesJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LocalCapture copyWithCompanion(LocalCapturesCompanion data) {
    return LocalCapture(
      id: data.id.present ? data.id.value : this.id,
      serverCaptureId: data.serverCaptureId.present
          ? data.serverCaptureId.value
          : this.serverCaptureId,
      originalUrl: data.originalUrl.present
          ? data.originalUrl.value
          : this.originalUrl,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      status: data.status.present ? data.status.value : this.status,
      intent: data.intent.present ? data.intent.value : this.intent,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      originalCaption: data.originalCaption.present
          ? data.originalCaption.value
          : this.originalCaption,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      audioTranscript: data.audioTranscript.present
          ? data.audioTranscript.value
          : this.audioTranscript,
      notificationCopiesJson: data.notificationCopiesJson.present
          ? data.notificationCopiesJson.value
          : this.notificationCopiesJson,
      entitiesJson: data.entitiesJson.present
          ? data.entitiesJson.value
          : this.entitiesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCapture(')
          ..write('id: $id, ')
          ..write('serverCaptureId: $serverCaptureId, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('contentType: $contentType, ')
          ..write('status: $status, ')
          ..write('intent: $intent, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('originalCaption: $originalCaption, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('audioTranscript: $audioTranscript, ')
          ..write('notificationCopiesJson: $notificationCopiesJson, ')
          ..write('entitiesJson: $entitiesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverCaptureId,
    originalUrl,
    contentType,
    status,
    intent,
    category,
    title,
    originalCaption,
    thumbnailUrl,
    audioTranscript,
    notificationCopiesJson,
    entitiesJson,
    createdAt,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCapture &&
          other.id == this.id &&
          other.serverCaptureId == this.serverCaptureId &&
          other.originalUrl == this.originalUrl &&
          other.contentType == this.contentType &&
          other.status == this.status &&
          other.intent == this.intent &&
          other.category == this.category &&
          other.title == this.title &&
          other.originalCaption == this.originalCaption &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.audioTranscript == this.audioTranscript &&
          other.notificationCopiesJson == this.notificationCopiesJson &&
          other.entitiesJson == this.entitiesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class LocalCapturesCompanion extends UpdateCompanion<LocalCapture> {
  final Value<String> id;
  final Value<String?> serverCaptureId;
  final Value<String?> originalUrl;
  final Value<String> contentType;
  final Value<String> status;
  final Value<String?> intent;
  final Value<String?> category;
  final Value<String?> title;
  final Value<String?> originalCaption;
  final Value<String?> thumbnailUrl;
  final Value<String?> audioTranscript;
  final Value<String?> notificationCopiesJson;
  final Value<String?> entitiesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocalCapturesCompanion({
    this.id = const Value.absent(),
    this.serverCaptureId = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.contentType = const Value.absent(),
    this.status = const Value.absent(),
    this.intent = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.originalCaption = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.audioTranscript = const Value.absent(),
    this.notificationCopiesJson = const Value.absent(),
    this.entitiesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCapturesCompanion.insert({
    required String id,
    this.serverCaptureId = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.contentType = const Value.absent(),
    this.status = const Value.absent(),
    this.intent = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.originalCaption = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.audioTranscript = const Value.absent(),
    this.notificationCopiesJson = const Value.absent(),
    this.entitiesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LocalCapture> custom({
    Expression<String>? id,
    Expression<String>? serverCaptureId,
    Expression<String>? originalUrl,
    Expression<String>? contentType,
    Expression<String>? status,
    Expression<String>? intent,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? originalCaption,
    Expression<String>? thumbnailUrl,
    Expression<String>? audioTranscript,
    Expression<String>? notificationCopiesJson,
    Expression<String>? entitiesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverCaptureId != null) 'server_capture_id': serverCaptureId,
      if (originalUrl != null) 'original_url': originalUrl,
      if (contentType != null) 'content_type': contentType,
      if (status != null) 'status': status,
      if (intent != null) 'intent': intent,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (originalCaption != null) 'original_caption': originalCaption,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (audioTranscript != null) 'audio_transcript': audioTranscript,
      if (notificationCopiesJson != null)
        'notification_copies_json': notificationCopiesJson,
      if (entitiesJson != null) 'entities_json': entitiesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCapturesCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverCaptureId,
    Value<String?>? originalUrl,
    Value<String>? contentType,
    Value<String>? status,
    Value<String?>? intent,
    Value<String?>? category,
    Value<String?>? title,
    Value<String?>? originalCaption,
    Value<String?>? thumbnailUrl,
    Value<String?>? audioTranscript,
    Value<String?>? notificationCopiesJson,
    Value<String?>? entitiesJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalCapturesCompanion(
      id: id ?? this.id,
      serverCaptureId: serverCaptureId ?? this.serverCaptureId,
      originalUrl: originalUrl ?? this.originalUrl,
      contentType: contentType ?? this.contentType,
      status: status ?? this.status,
      intent: intent ?? this.intent,
      category: category ?? this.category,
      title: title ?? this.title,
      originalCaption: originalCaption ?? this.originalCaption,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioTranscript: audioTranscript ?? this.audioTranscript,
      notificationCopiesJson:
          notificationCopiesJson ?? this.notificationCopiesJson,
      entitiesJson: entitiesJson ?? this.entitiesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverCaptureId.present) {
      map['server_capture_id'] = Variable<String>(serverCaptureId.value);
    }
    if (originalUrl.present) {
      map['original_url'] = Variable<String>(originalUrl.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (intent.present) {
      map['intent'] = Variable<String>(intent.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalCaption.present) {
      map['original_caption'] = Variable<String>(originalCaption.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (audioTranscript.present) {
      map['audio_transcript'] = Variable<String>(audioTranscript.value);
    }
    if (notificationCopiesJson.present) {
      map['notification_copies_json'] = Variable<String>(
        notificationCopiesJson.value,
      );
    }
    if (entitiesJson.present) {
      map['entities_json'] = Variable<String>(entitiesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCapturesCompanion(')
          ..write('id: $id, ')
          ..write('serverCaptureId: $serverCaptureId, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('contentType: $contentType, ')
          ..write('status: $status, ')
          ..write('intent: $intent, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('originalCaption: $originalCaption, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('audioTranscript: $audioTranscript, ')
          ..write('notificationCopiesJson: $notificationCopiesJson, ')
          ..write('entitiesJson: $entitiesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCapturesTable localCaptures = $LocalCapturesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localCaptures];
}

typedef $$LocalCapturesTableCreateCompanionBuilder =
    LocalCapturesCompanion Function({
      required String id,
      Value<String?> serverCaptureId,
      Value<String?> originalUrl,
      Value<String> contentType,
      Value<String> status,
      Value<String?> intent,
      Value<String?> category,
      Value<String?> title,
      Value<String?> originalCaption,
      Value<String?> thumbnailUrl,
      Value<String?> audioTranscript,
      Value<String?> notificationCopiesJson,
      Value<String?> entitiesJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$LocalCapturesTableUpdateCompanionBuilder =
    LocalCapturesCompanion Function({
      Value<String> id,
      Value<String?> serverCaptureId,
      Value<String?> originalUrl,
      Value<String> contentType,
      Value<String> status,
      Value<String?> intent,
      Value<String?> category,
      Value<String?> title,
      Value<String?> originalCaption,
      Value<String?> thumbnailUrl,
      Value<String?> audioTranscript,
      Value<String?> notificationCopiesJson,
      Value<String?> entitiesJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$LocalCapturesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCapturesTable> {
  $$LocalCapturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverCaptureId => $composableBuilder(
    column: $table.serverCaptureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intent => $composableBuilder(
    column: $table.intent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalCaption => $composableBuilder(
    column: $table.originalCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioTranscript => $composableBuilder(
    column: $table.audioTranscript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationCopiesJson => $composableBuilder(
    column: $table.notificationCopiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entitiesJson => $composableBuilder(
    column: $table.entitiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCapturesTable> {
  $$LocalCapturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverCaptureId => $composableBuilder(
    column: $table.serverCaptureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intent => $composableBuilder(
    column: $table.intent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalCaption => $composableBuilder(
    column: $table.originalCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioTranscript => $composableBuilder(
    column: $table.audioTranscript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationCopiesJson => $composableBuilder(
    column: $table.notificationCopiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entitiesJson => $composableBuilder(
    column: $table.entitiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCapturesTable> {
  $$LocalCapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverCaptureId => $composableBuilder(
    column: $table.serverCaptureId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get intent =>
      $composableBuilder(column: $table.intent, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalCaption => $composableBuilder(
    column: $table.originalCaption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioTranscript => $composableBuilder(
    column: $table.audioTranscript,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notificationCopiesJson => $composableBuilder(
    column: $table.notificationCopiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entitiesJson => $composableBuilder(
    column: $table.entitiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalCapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCapturesTable,
          LocalCapture,
          $$LocalCapturesTableFilterComposer,
          $$LocalCapturesTableOrderingComposer,
          $$LocalCapturesTableAnnotationComposer,
          $$LocalCapturesTableCreateCompanionBuilder,
          $$LocalCapturesTableUpdateCompanionBuilder,
          (
            LocalCapture,
            BaseReferences<_$AppDatabase, $LocalCapturesTable, LocalCapture>,
          ),
          LocalCapture,
          PrefetchHooks Function()
        > {
  $$LocalCapturesTableTableManager(_$AppDatabase db, $LocalCapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverCaptureId = const Value.absent(),
                Value<String?> originalUrl = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> intent = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> originalCaption = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> audioTranscript = const Value.absent(),
                Value<String?> notificationCopiesJson = const Value.absent(),
                Value<String?> entitiesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCapturesCompanion(
                id: id,
                serverCaptureId: serverCaptureId,
                originalUrl: originalUrl,
                contentType: contentType,
                status: status,
                intent: intent,
                category: category,
                title: title,
                originalCaption: originalCaption,
                thumbnailUrl: thumbnailUrl,
                audioTranscript: audioTranscript,
                notificationCopiesJson: notificationCopiesJson,
                entitiesJson: entitiesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverCaptureId = const Value.absent(),
                Value<String?> originalUrl = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> intent = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> originalCaption = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> audioTranscript = const Value.absent(),
                Value<String?> notificationCopiesJson = const Value.absent(),
                Value<String?> entitiesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCapturesCompanion.insert(
                id: id,
                serverCaptureId: serverCaptureId,
                originalUrl: originalUrl,
                contentType: contentType,
                status: status,
                intent: intent,
                category: category,
                title: title,
                originalCaption: originalCaption,
                thumbnailUrl: thumbnailUrl,
                audioTranscript: audioTranscript,
                notificationCopiesJson: notificationCopiesJson,
                entitiesJson: entitiesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCapturesTable,
      LocalCapture,
      $$LocalCapturesTableFilterComposer,
      $$LocalCapturesTableOrderingComposer,
      $$LocalCapturesTableAnnotationComposer,
      $$LocalCapturesTableCreateCompanionBuilder,
      $$LocalCapturesTableUpdateCompanionBuilder,
      (
        LocalCapture,
        BaseReferences<_$AppDatabase, $LocalCapturesTable, LocalCapture>,
      ),
      LocalCapture,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCapturesTableTableManager get localCaptures =>
      $$LocalCapturesTableTableManager(_db, _db.localCaptures);
}
