import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/auth/presentation/auth_providers.dart';
import 'fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway gateway;
  late AuthController controller;
  setUp(() {
    gateway = FakeAuthGateway();
    controller = AuthController(gateway);
  });
  tearDown(() async {
    controller.dispose();
    await gateway.events.close();
  });
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  for (final invalidation in [
    'external logout',
    'initialize retry',
    'stream error',
  ]) {
    test('late sign-in cannot reopen gate after $invalidation', () async {
      await controller.initialize();
      await settle();
      gateway.pendingSignIn = Completer<AuthSession>();
      final pending = controller.signInWithGoogle();
      if (invalidation == 'initialize retry') {
        await controller.initialize();
      } else if (invalidation == 'stream error') {
        gateway.events.addError(StateError('expired session'));
      } else {
        gateway.events.add(null);
      }
      await settle();
      gateway.pendingSignIn!.complete(
        const AuthSession(uid: 'old-owner', provider: 'google.com'),
      );
      await pending;
      expect(controller.state.phase, isNot(AuthPhase.signedIn));
      expect(controller.state.session, isNull);
    });
  }

  test(
    'failed sign-out Retry repeats sign-out instead of restoring old session',
    () async {
      gateway.current = const AuthSession(uid: 'owner', provider: 'google.com');
      await controller.initialize();
      await settle();
      gateway.signOutError = StateError('SDK sign-out failure');
      await controller.signOut();
      expect(controller.state.phase, AuthPhase.error);
      await controller.initialize();
      expect(gateway.signOutCalls, 2);
      expect(controller.state.phase, AuthPhase.error);
      expect(controller.state.session, isNull);
      gateway.signOutError = null;
      await controller.initialize();
      await settle();
      expect(controller.state.phase, AuthPhase.signedOut);
    },
  );

  test(
    'initializing waits for restored session; unsupported provider is denied',
    () async {
      expect(controller.state.phase, AuthPhase.initializing);
      gateway.current = const AuthSession(uid: 'owner', provider: 'password');
      await controller.initialize();
      await settle();
      expect(controller.state.phase, AuthPhase.signedOut);
      expect(controller.state.session, isNull);
    },
  );

  test(
    'initialization failure is sanitized, retry restores supported session',
    () async {
      gateway.initializationError = StateError('private SDK configuration');
      await controller.initialize();
      expect(controller.state.phase, AuthPhase.error);
      expect(controller.state.errorMessage, isNot(contains('private SDK')));
      gateway.initializationError = null;
      gateway.current = const AuthSession(uid: 'owner', provider: 'apple.com');
      await controller.initialize();
      await settle();
      expect(controller.state.phase, AuthPhase.signedIn);
    },
  );

  for (final provider in ['google.com', 'apple.com']) {
    test('$provider sign-in grants supported session', () async {
      await controller.initialize();
      await settle();
      await (provider == 'google.com'
          ? controller.signInWithGoogle()
          : controller.signInWithApple());
      expect(controller.state.session?.provider, provider);
      expect(controller.state.phase, AuthPhase.signedIn);
      expect(controller.state.isBusy, isFalse);
    });
  }

  test('duplicate sign-in calls launch exactly one SDK operation', () async {
    await controller.initialize();
    await settle();
    gateway.pendingSignIn = Completer<AuthSession>();
    final first = controller.signInWithGoogle();
    await controller.signInWithApple();
    await controller.signInWithGoogle();
    expect(gateway.googleCalls, 1);
    expect(gateway.appleCalls, 0);
    gateway.pendingSignIn!.complete(
      const AuthSession(uid: 'owner', provider: 'google.com'),
    );
    await first;
  });

  test('cancellation leaves gate signed out without an error', () async {
    await controller.initialize();
    await settle();
    gateway.signInError = const AuthFailure(AuthFailureKind.cancelled);
    await controller.signInWithGoogle();
    expect(controller.state.phase, AuthPhase.signedOut);
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.isBusy, isFalse);
  });

  test('credential collision does not merge accounts', () async {
    await controller.initialize();
    await settle();
    gateway.signInError = const AuthFailure(AuthFailureKind.collision);
    await controller.signInWithApple();
    expect(controller.state.session, isNull);
    expect(controller.state.errorMessage, contains('not been merged'));
  });

  test(
    'each token refresh increments revision; sign-out clears protected session',
    () async {
      gateway.current = const AuthSession(uid: 'owner', provider: 'google.com');
      await controller.initialize();
      await settle();
      final previousRevision = controller.state.revision;
      gateway.events.add(gateway.current);
      await settle();
      expect(controller.state.revision, previousRevision + 1);
      await controller.signOut();
      await settle();
      expect(gateway.signOutCalls, 1);
      expect(controller.state.phase, AuthPhase.signedOut);
      expect(controller.state.session, isNull);
    },
  );

  test(
    'auth stream error closes access and never exposes provider details',
    () async {
      gateway.current = const AuthSession(uid: 'owner', provider: 'google.com');
      await controller.initialize();
      await settle();
      gateway.events.addError(StateError('private refresh failure'));
      await settle();
      expect(controller.state.phase, AuthPhase.error);
      expect(controller.state.session, isNull);
      expect(controller.state.errorMessage, isNot(contains('private')));
    },
  );
}
