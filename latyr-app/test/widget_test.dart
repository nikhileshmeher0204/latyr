import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/app.dart';

void main() {
  testWidgets('LatyrApp smoke test: renders app bar and navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LatyrApp(),
      ),
    );

    expect(find.text('Latyr'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
  });
}
