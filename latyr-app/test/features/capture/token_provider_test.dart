import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/auth/presentation/auth_providers.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import '../auth/fake_auth_gateway.dart';

class _Controller extends AuthController {
  _Controller() : super(FakeAuthGateway());
  void setSession(String? uid, {String provider = 'google.com', int revision = 1}) {
    state = AuthState(
      phase: uid == null ? AuthPhase.signedOut : AuthPhase.signedIn,
      session: uid == null ? null : AuthSession(uid: uid, provider: provider),
      revision: revision,
    );
  }
}

class _Auth extends Fake implements FirebaseAuth {
  User? user;
  @override
  User? get currentUser => user;
}

class _Adapter extends Fake implements HttpClientAdapter {
  bool closed = false;
  @override
  void close({bool force = false}) => closed = force;
}

class _NoSse extends SseClient {
  @override
  Future<void> connect() async {}
}

class _User extends Fake implements User {
  @override
  final String uid;
  @override
  final bool isAnonymous;
  String? token;
  Object? error;
  int tokenRequests = 0;
  Future<String?>? pending;
  _User({this.uid = 'owner', this.isAnonymous = false, this.token});
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    tokenRequests++;
    if (error != null) throw error!;
    if (pending != null) return pending;
    return token;
  }
}

void main() {
  late _Auth auth;
  late ProviderContainer container;
  late _Controller controller;
  setUp(() {
    auth = _Auth();
    controller = _Controller()..setSession(null);
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        authControllerProvider.overrideWith((ref) => controller),
      ],
    );
  });
  tearDown(() => container.dispose());
  test(
    'signed-out and anonymous users never receive a fallback token',
    () async {
      final provider = container.read(tokenProviderProvider);
      expect(await provider(), isNull);
      final anonymous = _User(isAnonymous: true, token: 'anonymous-token');
      auth.user = anonymous;
      controller.setSession('owner');
      expect(await container.read(tokenProviderProvider)(), isNull);
      expect(anonymous.tokenRequests, 0);
    },
  );
  test(
    'signed-in user delegates fresh token retrieval on every call',
    () async {
      final user = _User(token: 'initial-token');
      auth.user = user;
      controller.setSession(user.uid);
      final provider = container.read(tokenProviderProvider);
      expect(await provider(), 'initial-token');
      user.token = 'refreshed-token';
      controller.setSession(user.uid, revision: 2);
      expect(container.read(tokenProviderProvider), same(provider));
      expect(await provider(), 'refreshed-token');
      expect(user.tokenRequests, 2);
      auth.user = null;
      expect(await provider(), isNull);
    },
  );
  test(
    'token refresh failures propagate without fabricated credentials',
    () async {
      auth.user = _User()..error = StateError('Firebase refresh failed');
      controller.setSession(auth.user!.uid);
      await expectLater(
        container.read(tokenProviderProvider)(),
        throwsStateError,
      );
    },
  );

  test('unsupported auth session cannot expose SDK credentials', () async {
    auth.user = _User(token: 'sdk-token');
    controller.setSession('owner', provider: 'password');
    expect(container.read(authenticatedUserIdProvider), isNull);
    expect(await container.read(tokenProviderProvider)(), isNull);
  });

  test('token result is discarded if identity changes during await', () async {
    final completion = Completer<String?>();
    auth.user = _User()..pending = completion.future;
    controller.setSession('owner');
    final oldProvider = container.read(tokenProviderProvider);
    final pendingToken = oldProvider();
    auth.user = _User(uid: 'other', token: 'other-token');
    controller.setSession('other', revision: 2);
    completion.complete('old-token');
    expect(await pendingToken, isNull);
    expect(await oldProvider(), isNull);
    expect(await container.read(tokenProviderProvider)(), 'other-token');
    auth.user = _User(token: 'new-owner-token');
    controller.setSession('owner', revision: 3);
    expect(await oldProvider(), isNull);
    expect(await container.read(tokenProviderProvider)(), 'new-owner-token');
  });

  test('SDK account mismatch blocks token before SDK request', () async {
    final user = _User(uid: 'other', token: 'other-token');
    auth.user = user;
    controller.setSession('owner');
    expect(await container.read(tokenProviderProvider)(), isNull);
    expect(user.tokenRequests, 0);
  });

  test('rapid account round trip creates a fresh token generation', () async {
    auth.user = _User(token: 'old-token');
    controller.setSession('owner');
    final oldProvider = container.read(tokenProviderProvider);
    controller.setSession('other', revision: 2);
    controller.setSession('owner', revision: 3);
    auth.user = _User(token: 'new-token');
    expect(await oldProvider(), isNull);
    expect(await container.read(tokenProviderProvider)(), 'new-token');
  });

  test('disposed token closure cannot access a later account', () async {
    auth.user = _User(token: 'old-token');
    controller.setSession('owner');
    final oldProvider = container.read(tokenProviderProvider);
    container.dispose();
    auth.user = _User(uid: 'other', token: 'other-token');
    expect(await oldProvider(), isNull);
    container = ProviderContainer();
  });

  test('database provider rejects signed-out and unsupported sessions', () {
    expect(() => container.read(appDatabaseProvider),
        throwsA(isA<AuthenticationRequiredException>()));
    controller.setSession('owner', provider: 'password');
    expect(() => container.read(appDatabaseProvider),
        throwsA(isA<AuthenticationRequiredException>()));
  });

  test('same-account refresh keeps database; account switch replaces it', () {
    controller.setSession('owner');
    final first = container.read(appDatabaseProvider);
    controller.setSession('owner', revision: 2);
    expect(container.read(appDatabaseProvider), same(first));
    controller.setSession('other', revision: 3);
    expect(container.read(appDatabaseProvider), isNot(same(first)));
  });

  test('account switch closes previous API client transport', () {
    controller.setSession('owner');
    final first = container.read(apiClientProvider);
    final adapter = _Adapter();
    first.dio.httpClientAdapter = adapter;
    controller.setSession('other', revision: 2);
    expect(container.read(apiClientProvider), isNot(same(first)));
    expect(adapter.closed, isTrue);
  });

  test('repository cannot authorize a new account with an old database', () {
    container.dispose();
    controller = _Controller()..setSession('owner');
    final sse = _NoSse();
    container = ProviderContainer(overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      authControllerProvider.overrideWith((ref) => controller),
      sseClientProvider.overrideWithValue(sse),
    ]);
    addTearDown(sse.dispose);
    auth.user = _User(token: 'owner-token');
    final first = container.read(captureRepositoryProvider);
    expect(first.canCapture(), isTrue);
    auth.user = _User(uid: 'other');
    controller.setSession('other', revision: 2);
    expect(first.canCapture(), isFalse);
    auth.user = _User();
    controller.setSession('owner', revision: 3);
    expect(first.canCapture(), isFalse);
    expect(container.read(captureRepositoryProvider).canCapture(), isTrue);
  });
}
