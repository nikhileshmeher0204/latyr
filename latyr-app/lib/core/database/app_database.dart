import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class LocalCaptures extends Table {
  TextColumn get id => text()();
  TextColumn get serverCaptureId => text().nullable()();
  TextColumn get originalUrl => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('URL'))();
  TextColumn get status => text().withDefault(const Constant('PENDING_SYNC'))();
  TextColumn get sourceType => text().nullable()();
  TextColumn get intent => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get subCategory => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get originalCaption => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get audioTranscript => text().nullable()();
  TextColumn get notificationCopiesJson => text().nullable()();
  TextColumn get entitiesJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalCaptures])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forAccount(String firebaseUid)
    : super(_openConnection(fileName: accountDatabaseFileName(firebaseUid)));

  static String accountDatabaseFileName(String firebaseUid) {
    if (firebaseUid.trim().isEmpty) {
      throw ArgumentError.value(
        firebaseUid,
        'firebaseUid',
        'Must not be empty',
      );
    }
    final accountId = const Uuid().v5(
      Namespace.url.value,
      'latyr-account:$firebaseUid',
    );
    return 'latyr_account_$accountId.sqlite';
  }

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            try {
              await m.addColumn(localCaptures, localCaptures.thumbnailUrl);
            } catch (_) {}
          }
          if (from < 3) {
            try {
              await m.addColumn(localCaptures, localCaptures.title);
            } catch (_) {}
          }
          if (from < 4) {
            try {
              await m.addColumn(localCaptures, localCaptures.subCategory);
            } catch (_) {}
            try {
              await m.addColumn(localCaptures, localCaptures.summary);
            } catch (_) {}
          }
          if (from < 5) {
            try {
              await m.addColumn(localCaptures, localCaptures.sourceType);
            } catch (_) {}
          }
        },
      );

  Stream<List<LocalCapture>> watchAllCaptures() {
    return (select(localCaptures)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<LocalCapture>> getAllCaptures() {
    return (select(localCaptures)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<List<LocalCapture>> getPendingSyncCaptures() {
    return (select(localCaptures)
          ..where((t) => t.status.equals('PENDING_SYNC'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  Future<LocalCapture?> getCaptureById(String id) {
    return (select(localCaptures)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<LocalCapture?> getCaptureByServerId(String serverCaptureId) {
    return (select(localCaptures)..where((t) => t.serverCaptureId.equals(serverCaptureId))).getSingleOrNull();
  }

  Future<LocalCapture?> getCaptureByUrl(String url) {
    return (select(localCaptures)
          ..where((t) => t.originalUrl.equals(url))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertCapture(LocalCapturesCompanion entry) {
    return into(localCaptures).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateCapture(LocalCapturesCompanion entry) {
    return (update(localCaptures)..where((t) => t.id.equals(entry.id.value))).write(entry);
  }

  Future<int> deleteCapture(String id) {
    return (delete(localCaptures)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection({String fileName = 'latyr_local.sqlite'}) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, fileName));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA journal_mode = WAL;');
        rawDb.execute('PRAGMA busy_timeout = 10000;');
      },
    );
  });
}
