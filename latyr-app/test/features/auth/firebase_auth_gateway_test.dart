import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latyr_app/features/auth/data/firebase_auth_gateway.dart';
import 'package:latyr_app/features/auth/domain/auth_gateway.dart';

class _Token extends Fake implements IdTokenResult {
  @override
  final String? signInProvider;
  _Token(this.signInProvider);
}

class _User extends Fake implements User {
  final String identity;
  final Completer<IdTokenResult>? pendingToken;
  final String provider;
  _User({
    this.identity = 'firebase-owner',
    this.pendingToken,
    this.provider = 'apple.com',
  });
  @override
  String get uid => identity;
  @override
  bool get isAnonymous => false;
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      pendingToken == null ? _Token(provider) : await pendingToken!.future;
}

class _Credential extends Fake implements UserCredential {
  @override
  final User user;
  _Credential(this.user);
}

class _Auth extends Fake implements FirebaseAuth {
  Object? error;
  String? requestedProvider;
  AuthCredential? credential;
  User credentialUser = _User();
  final events = StreamController<User?>.broadcast(sync: true);
  User? current;
  @override
  User? get currentUser => current;
  @override
  Stream<User?> idTokenChanges() => events.stream;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    requestedProvider = provider.providerId;
    if (error != null) throw error!;
    current = credentialUser;
    return _Credential(credentialUser);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    this.credential = credential;
    current = credentialUser;
    return _Credential(credentialUser);
  }
}

class _GoogleAccount extends Fake implements GoogleSignInAccount {
  @override
  GoogleSignInAuthentication get authentication =>
      const GoogleSignInAuthentication(idToken: 'google-id-token');
}

class _Google extends Fake implements GoogleSignIn {
  int initializationCalls = 0;
  Object? initializationError;
  Object? authenticationError;
  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializationCalls++;
    if (initializationError != null) throw initializationError!;
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    if (authenticationError != null) throw authenticationError!;
    return _GoogleAccount();
  }
}

void main() {
  test(
    'Google initializes once, exchanges ID token, and can retry failed initialization',
    () async {
      final auth = _Auth()..credentialUser = _User(provider: 'google.com');
      final google = _Google()
        ..initializationError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
      final gateway = FirebaseAuthGateway(getAuth: () => auth, google: google);
      await expectLater(
        gateway.signInWithGoogle(),
        throwsA(isA<AuthFailure>()),
      );
      google.initializationError = null;
      expect((await gateway.signInWithGoogle()).provider, 'google.com');
      expect((auth.credential as OAuthCredential).idToken, 'google-id-token');
      expect(auth.credential?.providerId, 'google.com');
      await gateway.signInWithGoogle();
      expect(google.initializationCalls, 2);
    },
  );

  test('Google cancellation does not exchange credentials', () async {
    final auth = _Auth();
    final google = _Google()
      ..authenticationError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    final gateway = FirebaseAuthGateway(getAuth: () => auth, google: google);
    await expectLater(
      gateway.signInWithGoogle(),
      throwsA(
        isA<AuthFailure>().having(
          (error) => error.kind,
          'kind',
          AuthFailureKind.cancelled,
        ),
      ),
    );
    expect(auth.credential, isNull);
  });
  test(
    'raw logout closes session immediately and late claims never restore it',
    () async {
      final auth = _Auth();
      final gateway = FirebaseAuthGateway(getAuth: () => auth);
      final received = <AuthSession?>[];
      final subscription = gateway.sessions.listen(received.add);
      await Future<void>.delayed(Duration.zero);
      final pending = Completer<IdTokenResult>();
      auth.current = _User(pendingToken: pending);
      auth.events.add(auth.current);
      await Future<void>.delayed(Duration.zero);
      auth.current = null;
      auth.events.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(received, isNotEmpty);
      expect(received.last, isNull);
      pending.complete(_Token('apple.com'));
      await Future<void>.delayed(Duration.zero);
      expect(received.whereType<AuthSession>(), isEmpty);
      await subscription.cancel();
      await auth.events.close();
    },
  );

  test(
    'raw account change clears old session before slow new claims',
    () async {
      final auth = _Auth();
      final gateway = FirebaseAuthGateway(getAuth: () => auth);
      final received = <AuthSession?>[];
      final subscription = gateway.sessions.listen(received.add);
      await Future<void>.delayed(Duration.zero);
      auth.current = _User();
      auth.events.add(auth.current);
      await Future<void>.delayed(Duration.zero);
      expect(received.last?.uid, 'firebase-owner');
      final pending = Completer<IdTokenResult>();
      auth.current = _User(identity: 'second-owner', pendingToken: pending);
      auth.events.add(auth.current);
      await Future<void>.delayed(Duration.zero);
      expect(received.last, isNull);
      pending.complete(_Token('apple.com'));
      await Future<void>.delayed(Duration.zero);
      expect(received.last?.uid, 'second-owner');
      await subscription.cancel();
      await auth.events.close();
    },
  );
  test('Apple uses SDK provider flow and actual token provider', () async {
    final auth = _Auth();
    final gateway = FirebaseAuthGateway(getAuth: () => auth);
    final session = await gateway.signInWithApple();
    expect(auth.requestedProvider, 'apple.com');
    expect(session.uid, 'firebase-owner');
    expect(session.provider, 'apple.com');
    expect(session.isSupported, isTrue);
  });

  for (final entry in {
    'web-context-cancelled': AuthFailureKind.cancelled,
    'account-exists-with-different-credential': AuthFailureKind.collision,
    'credential-already-in-use': AuthFailureKind.collision,
    'network-request-failed': AuthFailureKind.network,
    'operation-not-allowed': AuthFailureKind.configuration,
    'unknown-private-sdk-error': AuthFailureKind.unknown,
  }.entries) {
    test('SDK ${entry.key} is mapped without exposing raw errors', () async {
      final auth = _Auth()
        ..error = FirebaseAuthException(
          code: entry.key,
          message: 'private detail',
        );
      final gateway = FirebaseAuthGateway(getAuth: () => auth);
      await expectLater(
        gateway.signInWithApple(),
        throwsA(
          isA<AuthFailure>()
              .having((error) => error.kind, 'kind', entry.value)
              .having(
                (error) => error.message,
                'sanitized message',
                isNot(contains('private detail')),
              ),
        ),
      );
    });
  }
}
