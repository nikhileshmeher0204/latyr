import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/auth/presentation/auth_providers.dart';

class AuthGate extends ConsumerWidget {
  final WidgetBuilder signedInBuilder;
  const AuthGate({super.key, required this.signedInBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    return switch (state.phase) {
      AuthPhase.signedIn => signedInBuilder(context),
      AuthPhase.signedOut => const SignInScreen(),
      AuthPhase.initializing => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      AuthPhase.error => CupertinoPageScaffold(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: LTypography.body,
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).initialize(),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    };
  }
}

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Latyr',
                  style: LTypography.largeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to capture and explore your saved knowledge.',
                  style: LTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  onPressed: state.isBusy ? null : controller.signInWithGoogle,
                  child: const Text('Continue with Google'),
                ),
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: state.isBusy ? null : controller.signInWithApple,
                  child: const Text('Continue with Apple'),
                ),
                if (state.isBusy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(),
                  ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: LTypography.callout,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(authControllerProvider).isBusy;
    return CupertinoButton(
      onPressed: busy
          ? null
          : () => ref.read(authControllerProvider.notifier).signOut(),
      child: const Text('Sign out'),
    );
  }
}
