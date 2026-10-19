import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/app.dart';

import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/home/presentation/home_providers.dart';

class _NoOpSseClient extends SseClient {
  _NoOpSseClient() : super();
  @override
  Future<void> connect() async {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('LatyrApp smoke test: renders navigation and Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sseClientProvider.overrideWithValue(_NoOpSseClient()),
          weatherProvider.overrideWith((ref) async => WeatherContext(
            city: 'Lakeland',
            temperature: 29.0,
            condition: 'Partly Cloudy',
          )),
        ],
        child: const CupertinoApp(
          localizationsDelegates: [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          home: LatyrTabNavigationScreen(),
        ),
      ),
    );

    // Verify Home top bar
    expect(find.text('All Captures'), findsOneWidget);

    // Verify Floating Navigation Bar tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}

