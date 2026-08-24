import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/subscription/presentation/paywall_modal.dart';

void main() {
  testWidgets('PaywallModal: renders monthly quota, perks and upgrade CTA button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: PaywallModal(usedCaptures: 15, quotaLimit: 30),
        ),
      ),
    );

    expect(find.text('LATYR PRO'), findsOneWidget);
    expect(find.text('Unlock Unlimited Knowledge'), findsOneWidget);
    expect(find.text('15 / 30 captures'), findsOneWidget);
    expect(find.text('1,000 Captures / Month'), findsOneWidget);
    expect(find.text('Upgrade to Pro — \$4.99 / month'), findsOneWidget);
  });
}
