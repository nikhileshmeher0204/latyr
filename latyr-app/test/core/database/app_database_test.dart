import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() => db.close());

  Future<void> expectLifecyclePreserves(
    List<LocalCapturesCompanion> entries,
  ) async {
    for (final entry in entries) {
      await db.insertCapture(entry);
    }
    final before = await (db.select(
      db.localCaptures,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    final transport = _FeedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = transport;
    for (var iteration = 0; iteration < 3; iteration++) {
      final repository = CaptureRepository(
        db: db,
        apiClient: ApiClient(customDio: dio),
        canCapture: () => true,
      );
      try {
        await repository.fetchRemoteFeed();
      } finally {
        repository.dispose();
      }
      final after =
          await (db.select(db.localCaptures)
                ..where((table) => table.id.isIn(before.map((row) => row.id)))
                ..orderBy([(table) => OrderingTerm.asc(table.id)]))
              .get();
      expect(after, before);
      expect(await db.getCaptureByServerId('unrelated-feed-item'), isNotNull);
    }
    expect(transport.feedRequests, 3);
    dio.close();
  }

  test('preserves distinct resources and versions in URL queries', () async {
    await expectLifecyclePreserves([
      for (final suffix in ['first', 'second'])
        LocalCapturesCompanion(
          id: Value(suffix),
          originalUrl: Value('https://example.org/article?id=$suffix'),
          status: const Value('COMPLETED'),
          summary: Value('Summary for $suffix'),
        ),
      const LocalCapturesCompanion(
        id: Value('new-version'),
        originalUrl: Value('https://example.org/article?id=first&version=2'),
      ),
    ]);
  });

  test(
    'equal URLs do not authorize deleting distinct server captures',
    () async {
      await expectLifecyclePreserves([
        for (final suffix in ['first', 'second'])
          LocalCapturesCompanion(
            id: Value(suffix),
            serverCaptureId: Value('server-$suffix'),
            originalUrl: const Value('https://example.org/article'),
            entitiesJson: Value('[{"name":"$suffix"}]'),
          ),
      ]);
    },
  );

  test(
    'preserves private image payloads with equal local source URLs',
    () async {
      await expectLifecyclePreserves([
        for (final suffix in ['first', 'second'])
          LocalCapturesCompanion(
            id: Value(suffix),
            originalUrl: const Value('file:///shared/image.png'),
            contentType: const Value('IMAGE'),
            originalCaption: Value('Private caption $suffix'),
            summary: Value('Private summary $suffix'),
          ),
      ]);
    },
  );

  test(
    'shared server identity does not authorize dropping local records',
    () async {
      await expectLifecyclePreserves([
        for (final suffix in ['first', 'second'])
          LocalCapturesCompanion(
            id: Value(suffix),
            serverCaptureId: const Value('same-server-id'),
            originalUrl: const Value('https://example.org/article'),
            summary: const Value('Same analysis'),
          ),
      ]);
    },
  );

  test(
    'preserves conflicting local changes for the same server identity',
    () async {
      await expectLifecyclePreserves([
        const LocalCapturesCompanion(
          id: Value('synced'),
          serverCaptureId: Value('same-server-id'),
          status: Value('COMPLETED'),
          summary: Value('Previously synced analysis'),
        ),
        const LocalCapturesCompanion(
          id: Value('pending'),
          serverCaptureId: Value('same-server-id'),
          status: Value('PENDING_SYNC'),
          summary: Value('Local unsynced payload'),
        ),
      ]);
      expect((await db.getPendingSyncCaptures()).single.id, 'pending');
    },
  );

  test(
    'account filenames are stable, isolated and do not select legacy data',
    () {
      final first = AppDatabase.accountDatabaseFileName('user-one');
      expect(AppDatabase.accountDatabaseFileName('user-one'), first);
      expect(AppDatabase.accountDatabaseFileName('user-two'), isNot(first));
      expect(first, isNot('latyr_local.sqlite'));
      expect(first, isNot(contains('user-one')));
      expect(first, matches(RegExp(r'^latyr_account_[a-f0-9-]+\.sqlite$')));
    },
  );

  test('untrusted UID cannot introduce path separators or legacy filename', () {
    final name = AppDatabase.accountDatabaseFileName('../\\latyr_local.sqlite');
    expect(name, matches(RegExp(r'^latyr_account_[a-f0-9-]+\.sqlite$')));
    expect(name, isNot(contains('latyr_local.sqlite')));
    expect(
      () => AppDatabase.accountDatabaseFileName('  '),
      throwsArgumentError,
    );
  });
}

class _FeedAdapter implements HttpClientAdapter {
  int feedRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isFeed = options.path == '/captures';
    if (isFeed) feedRequests++;
    return ResponseBody.fromString(
      jsonEncode(
        isFeed
            ? {
                'items': [
                  {
                    'id': 'unrelated-feed-item',
                    'title': 'Feed revision $feedRequests',
                    'original_caption': 'https://example.org/unrelated',
                  },
                ],
              }
            : {'entities': []},
      ),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
