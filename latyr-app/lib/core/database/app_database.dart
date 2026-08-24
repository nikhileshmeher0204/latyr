import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LocalCaptures extends Table {
  TextColumn get id => text()();
  TextColumn get serverCaptureId => text().nullable()();
  TextColumn get originalUrl => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('URL'))();
  TextColumn get status => text().withDefault(const Constant('PENDING_SYNC'))();
  TextColumn get intent => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get originalCaption => text().nullable()();
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

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

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

  Future<int> insertCapture(LocalCapturesCompanion entry) {
    return into(localCaptures).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<bool> updateCapture(LocalCapturesCompanion entry) {
    return update(localCaptures).replace(entry);
  }

  Future<int> deleteCapture(String id) {
    return (delete(localCaptures)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'latyr_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
