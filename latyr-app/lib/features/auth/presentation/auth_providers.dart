import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/features/auth/data/firebase_auth_gateway.dart';
import 'package:latyr_app/features/auth/domain/auth_gateway.dart';

export 'package:latyr_app/features/auth/domain/auth_gateway.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final authGatewayProvider = Provider<AuthGateway>(
  (ref) => FirebaseAuthGateway(getAuth: () => ref.read(firebaseAuthProvider)),
);
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authGatewayProvider))..initialize();
  },
);

enum AuthPhase { initializing, signedOut, signedIn, error }

class AuthState {
  final AuthPhase phase;
  final AuthSession? session;
  final bool isBusy;
  final String? errorMessage;
  final int revision;

  const AuthState({
    this.phase = AuthPhase.initializing,
    this.session,
    this.isBusy = false,
    this.errorMessage,
    this.revision = 0,
  });
}

class AuthController extends StateNotifier<AuthState> {
  final AuthGateway _gateway;
  StreamSubscription<AuthSession?>? _subscription;
  int _generation = 0;
  bool _actionInFlight = false;
  int _accessEpoch = 0;
  int _operationId = 0;
  bool _signOutPending = false;

  AuthController(this._gateway) : super(const AuthState());

  Future<void> initialize() async {
    if (_signOutPending) {
      await signOut();
      return;
    }
    _operationId++;
    _accessEpoch++;
    _actionInFlight = false;
    final generation = ++_generation;
    state = AuthState(revision: state.revision);
    await _subscription?.cancel();
    try {
      await _gateway.initialize();
      if (!mounted || generation != _generation) return;
      _subscription = _gateway.sessions.listen(
        (session) {
          if (!mounted || generation != _generation) return;
          _setSession(session);
        },
        onError: (Object _) {
          if (!mounted || generation != _generation) return;
          _accessEpoch++;
          state = AuthState(
            phase: AuthPhase.error,
            revision: state.revision + 1,
            errorMessage: 'Unable to restore your session. Please try again.',
          );
        },
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = AuthState(
        phase: AuthPhase.error,
        revision: state.revision + 1,
        errorMessage: 'Unable to initialize sign-in. Please try again.',
      );
    }
  }

  void _setSession(AuthSession? session) {
    final supported = session?.isSupported ?? false;
    if (!supported || session?.uid != state.session?.uid) _accessEpoch++;
    state = AuthState(
      phase: supported ? AuthPhase.signedIn : AuthPhase.signedOut,
      session: supported ? session : null,
      isBusy: _actionInFlight,
      revision: state.revision + 1,
    );
  }

  Future<void> signInWithGoogle() => _signIn(_gateway.signInWithGoogle);
  Future<void> signInWithApple() => _signIn(_gateway.signInWithApple);

  Future<void> _signIn(Future<AuthSession> Function() operation) async {
    if (_actionInFlight || state.phase != AuthPhase.signedOut) return;
    _actionInFlight = true;
    final operationId = ++_operationId;
    final accessEpoch = _accessEpoch;
    final generation = _generation;
    state = AuthState(
      phase: AuthPhase.signedOut,
      isBusy: true,
      revision: state.revision,
    );
    try {
      final session = await operation();
      if (!mounted || generation != _generation || accessEpoch != _accessEpoch) {
        return;
      }
      _actionInFlight = false;
      _setSession(session);
    } catch (error) {
      if (!mounted || generation != _generation || accessEpoch != _accessEpoch) {
        return;
      }
      _actionInFlight = false;
      final failure = error is AuthFailure
          ? error
          : const AuthFailure(AuthFailureKind.unknown);
      state = AuthState(
        phase: AuthPhase.signedOut,
        revision: state.revision + 1,
        errorMessage: failure.kind == AuthFailureKind.cancelled
            ? null
            : failure.message,
      );
    } finally {
      if (mounted && operationId == _operationId) {
        _actionInFlight = false;
        if (state.isBusy) {
          state = AuthState(
            phase: state.phase,
            session: state.session,
            errorMessage: state.errorMessage,
            revision: state.revision,
          );
        }
      }
    }
  }

  Future<void> signOut() async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    _signOutPending = true;
    _operationId++;
    _accessEpoch++;
    _generation++;
    state = AuthState(
      phase: AuthPhase.signedOut,
      isBusy: true,
      revision: state.revision + 1,
    );
    try {
      await _subscription?.cancel();
      await _gateway.signOut();
      _signOutPending = false;
      _actionInFlight = false;
      if (mounted) await initialize();
    } catch (_) {
      _actionInFlight = false;
      if (!mounted) return;
      state = AuthState(
        phase: AuthPhase.error,
        revision: state.revision + 1,
        errorMessage: 'Unable to sign out. Please try again.',
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
