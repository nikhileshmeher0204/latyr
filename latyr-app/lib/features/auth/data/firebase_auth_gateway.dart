import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latyr_app/features/auth/domain/auth_gateway.dart';

class FirebaseAuthGateway implements AuthGateway {
  final FirebaseAuth Function() getAuth;
  final GoogleSignIn _google;
  Future<void>? _googleInitialization;

  FirebaseAuthGateway({required this.getAuth, GoogleSignIn? google})
    : _google = google ?? GoogleSignIn.instance;

  @override
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    try {
      await getAuth().authStateChanges().first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  Stream<AuthSession?> get sessions => Stream<AuthSession?>.multi((sink) {
    final auth = getAuth();
    var generation = 0;
    String? observedUid;
    final subscription = auth.idTokenChanges().listen(
      (user) {
        final currentGeneration = ++generation;
        final uid = user == null || user.isAnonymous ? null : user.uid;
        if (uid == null || (observedUid != null && uid != observedUid)) {
          sink.add(null);
        }
        observedUid = uid;
        if (uid == null) return;
        unawaited(() async {
          try {
            final session = await _session(user);
            if (generation != currentGeneration ||
                auth.currentUser?.uid != uid ||
                auth.currentUser?.isAnonymous != false) {
              return;
            }
            sink.add(session);
          } catch (_) {
            if (generation == currentGeneration) {
              sink.addError(const AuthFailure(AuthFailureKind.unknown));
            }
          }
        }());
      },
      onError: (Object _) {
        generation++;
        sink.addError(const AuthFailure(AuthFailureKind.unknown));
      },
    );
    sink.onCancel = () {
      generation++;
      return subscription.cancel();
    };
  });

  Future<AuthSession> _session(User? user) async {
    if (user == null || user.isAnonymous) {
      throw const AuthFailure(AuthFailureKind.unknown);
    }
    final token = await user.getIdTokenResult();
    final current = getAuth().currentUser;
    if (current == null || current.isAnonymous || current.uid != user.uid) {
      throw const AuthFailure(AuthFailureKind.cancelled);
    }
    return AuthSession(uid: user.uid, provider: token.signInProvider ?? '');
  }

  @override
  Future<AuthSession> signInWithGoogle() => _authenticate(() async {
    final google = _google;
    try {
      await (_googleInitialization ??= google.initialize());
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure(AuthFailureKind.configuration);
    }
    final result = await getAuth().signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return _session(result.user);
  });

  @override
  Future<AuthSession> signInWithApple() => _authenticate(() async {
    final result = await getAuth().signInWithProvider(AppleAuthProvider());
    return _session(result.user);
  });

  Future<AuthSession> _authenticate(
    Future<AuthSession> Function() action,
  ) async {
    try {
      return await action();
    } on GoogleSignInException catch (error) {
      throw AuthFailure(switch (error.code) {
        GoogleSignInExceptionCode.canceled => AuthFailureKind.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthFailureKind.configuration,
        _ => AuthFailureKind.unknown,
      });
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'web-context-cancelled' ||
        'canceled' ||
        'user-cancelled' => AuthFailureKind.cancelled,
        'account-exists-with-different-credential' ||
        'credential-already-in-use' => AuthFailureKind.collision,
        'network-request-failed' => AuthFailureKind.network,
        'operation-not-allowed' ||
        'invalid-api-key' ||
        'app-not-authorized' => AuthFailureKind.configuration,
        _ => AuthFailureKind.unknown,
      });
    }
  }

  @override
  Future<void> signOut() async {
    await getAuth().signOut();
    if (_googleInitialization != null) {
      try {
        await _googleInitialization;
        await _google.signOut();
      } catch (_) {
        // Firebase already cleared this app's local session.
      }
    }
  }
}
