import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/services/sync_service.dart';
import 'package:latyr_app/features/auth/presentation/auth_providers.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/home/presentation/home_providers.dart';
import 'package:latyr_app/main.dart';

import '../../core/network/recording_http_adapter.dart';

class _Gateway implements AuthGateway {
  AuthSession? current;
  final changes = StreamController<AuthSession?>.broadcast(sync: true);

  @override
  Future<void> initialize() async {}
  @override
  Stream<AuthSession?> get sessions async* {
    yield current;
    yield* changes.stream;
  }
  void setSession(AuthSession? session) {
    current = session;
    changes.add(session);
  }
  @override
  Future<AuthSession> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<AuthSession> signInWithApple() async => throw UnimplementedError();
  @override
  Future<void> signOut() async => setSession(null);
}

class _NoSync extends Fake implements SyncService {}

void main() {
  testWidgets('signed-out cold share shows notice without opening data or home', (tester) async {
    final gateway = _Gateway();
    const channel = MethodChannel('com.latyr.latyr_app/share');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => 'https://example.test/shared');
    var dataReads = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      authGatewayProvider.overrideWithValue(gateway),
      appDatabaseProvider.overrideWith((ref) {
        dataReads++;
        throw StateError('Signed-out library must not open');
      }),
    ], child: const LatyrAppInitializer()));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Captures Today'), findsNothing);
    expect(find.text('Sign in to use Latyr, then share again. Nothing was queued.'), findsOneWidget);
    expect(dataReads, 0);
    await tester.tap(find.byIcon(CupertinoIcons.clear));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to use Latyr, then share again. Nothing was queued.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await gateway.changes.close();
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('logout removes pushed private routes and another account gets a fresh navigator', (tester) async {
    final gateway = _Gateway()..current = const AuthSession(uid: 'first', provider: 'google.com');
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    final dio = Dio()..httpClientAdapter = RecordingHttpAdapter();
    final api = ApiClient(customDio: dio);
    final repo = CaptureRepository(db: db, apiClient: api, canCapture: () => true);
    const channel = MethodChannel('com.latyr.latyr_app/share');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await tester.pumpWidget(ProviderScope(overrides: [
      authGatewayProvider.overrideWithValue(gateway),
      appDatabaseProvider.overrideWithValue(db),
      apiClientProvider.overrideWithValue(api),
      captureRepositoryProvider.overrideWithValue(repo),
      syncServiceProvider.overrideWithValue(_NoSync()),
      weatherProvider.overrideWith((ref) async => WeatherContext(city: 'Test', temperature: 25, condition: 'Clear')),
    ], child: const LatyrAppInitializer()));
    await tester.pumpAndSettle();
    expect(find.text('Captures Today'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(navigator.push(CupertinoPageRoute<void>(builder: (_) => const CupertinoPageScaffold(
      child: Center(child: Text('Private detail')),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Private detail'), findsOneWidget);
    gateway.setSession(null);
    await tester.pumpAndSettle();
    expect(find.text('Private detail'), findsNothing);
    expect(find.text('Captures Today'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    gateway.setSession(const AuthSession(uid: 'second', provider: 'apple.com'));
    await tester.pumpAndSettle();
    expect(find.text('Captures Today'), findsOneWidget);
    expect(find.text('Private detail'), findsNothing);
    expect(identical(tester.state<NavigatorState>(find.byType(Navigator).first), navigator), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    repo.dispose();
    await db.close();
    dio.close();
    await gateway.changes.close();
    messenger.setMockMethodCallHandler(channel, null);
  });
}
