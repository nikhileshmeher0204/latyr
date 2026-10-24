import 'dart:async';
import 'package:latyr_app/features/auth/domain/auth_gateway.dart';

class FakeAuthGateway implements AuthGateway {
  final events = StreamController<AuthSession?>.broadcast(sync: true);
  AuthSession? current;
  Object? initializationError;
  Object? signInError;
  Object? signOutError;
  Completer<AuthSession>? pendingSignIn;
  int googleCalls = 0;
  int appleCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> initialize() async {
    if (initializationError != null) throw initializationError!;
  }

  @override
  Stream<AuthSession?> get sessions async* {
    yield current;
    yield* events.stream;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    googleCalls++;
    return _signIn('google.com');
  }

  @override
  Future<AuthSession> signInWithApple() async {
    appleCalls++;
    return _signIn('apple.com');
  }

  Future<AuthSession> _signIn(String provider) async {
    if (signInError != null) throw signInError!;
    return pendingSignIn?.future ??
        AuthSession(uid: 'owner', provider: provider);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
    current = null;
  }
}
