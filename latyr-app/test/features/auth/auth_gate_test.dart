import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/auth/presentation/auth_gate.dart';
import 'package:latyr_app/features/auth/presentation/auth_providers.dart';
import 'fake_auth_gateway.dart';

void main() {
  testWidgets(
    'protected child is never built before supported authentication',
    (tester) async {
      final gateway = FakeAuthGateway();
      var builds = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authGatewayProvider.overrideWithValue(gateway)],
          child: CupertinoApp(
            home: AuthGate(
              signedInBuilder: (_) {
                builds++;
                return const Text('Protected knowledge');
              },
            ),
          ),
        ),
      );
      expect(builds, 0);
      await tester.pumpAndSettle();
      expect(builds, 0);
      expect(find.text('Continue with Google'), findsOneWidget);
      gateway.events.add(const AuthSession(uid: 'owner', provider: 'password'));
      await tester.pumpAndSettle();
      expect(builds, 0);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Protected knowledge'), findsOneWidget);
      expect(builds, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      await gateway.events.close();
    },
  );

  testWidgets(
    'initialization error offers retry and does not instantiate protected child',
    (tester) async {
      final gateway = FakeAuthGateway()
        ..initializationError = StateError('secret config');
      var builds = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authGatewayProvider.overrideWithValue(gateway)],
          child: CupertinoApp(
            home: AuthGate(
              signedInBuilder: (_) {
                builds++;
                return const Text('Protected');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(builds, 0);
      expect(find.text('Try again'), findsOneWidget);
      gateway.initializationError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(builds, 0);
      await tester.pumpWidget(const SizedBox());
      await gateway.events.close();
    },
  );
}
