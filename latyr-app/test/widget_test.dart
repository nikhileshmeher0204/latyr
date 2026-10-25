import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';
import 'package:latyr_app/app.dart';

import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/home/presentation/home_providers.dart';
import 'core/network/recording_http_adapter.dart';

class _NoOpSseClient extends SseClient {
  _NoOpSseClient() : super();
  @override
  Future<void> connect() async {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('LatyrApp smoke test: renders navigation and Home screen', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    final dio = Dio()..httpClientAdapter = RecordingHttpAdapter();
    final sse = _NoOpSseClient();
    final repo = CaptureRepository(
      db: db,
      apiClient: ApiClient(customDio: dio),
      canCapture: () => true,
      sseClient: sse,
    );
    addTearDown(() async {
      repo.dispose();
      dio.close(force: true);
      await db.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          captureRepositoryProvider.overrideWithValue(repo),
          sseClientProvider.overrideWithValue(sse),
          weatherProvider.overrideWith((ref) async => WeatherContext(
            city: 'Lakeland',
            temperature: 29.0,
            condition: 'Partly Cloudy',
          )),
        ],
        child: const CupertinoApp(
          localizationsDelegates: [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          home: LatyrTabNavigationScreen(),
        ),
      ),
    );

    // Verify Home top bar
    expect(find.text('Latyr'), findsOneWidget);

    // Verify Floating Navigation Bar tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

