class AuthSession {
  final String uid;
  final String provider;

  const AuthSession({required this.uid, required this.provider});

  bool get isSupported =>
      uid.isNotEmpty && (provider == 'google.com' || provider == 'apple.com');
}

enum AuthFailureKind { cancelled, collision, network, configuration, unknown }

class AuthFailure implements Exception {
  final AuthFailureKind kind;
  const AuthFailure(this.kind);

  String get message => switch (kind) {
    AuthFailureKind.cancelled => 'Sign-in was cancelled.',
    AuthFailureKind.collision =>
      'This account uses another sign-in method. Sign in with that method. Accounts have not been merged.',
    AuthFailureKind.network =>
      'Unable to connect. Check your connection and try again.',
    AuthFailureKind.configuration =>
      'Sign-in is unavailable. Please try again later.',
    AuthFailureKind.unknown => 'Unable to sign in. Please try again.',
  };
}

abstract interface class AuthGateway {
  Future<void> initialize();
  Stream<AuthSession?> get sessions;
  Future<AuthSession> signInWithGoogle();
  Future<AuthSession> signInWithApple();
  Future<void> signOut();
}
