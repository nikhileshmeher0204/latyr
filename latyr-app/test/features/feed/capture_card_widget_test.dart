import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/feed/presentation/widgets/capture_card_widget.dart';

void main() {
  testWidgets('CaptureCardWidget: renders movie entity card with rating and WATCH CTA', (tester) async {
    final capture = LocalCapture(
      id: 'test-card-1',
      contentType: 'URL',
      status: 'COMPLETED',
      intent: 'WATCH',
      category: 'Entertainment',
      originalCaption: 'Best psychological thriller on Netflix: Dark',
      audioTranscript: 'You have to watch Dark, it is a masterpiece about time travel.',
      entitiesJson: '[{"title":"Dark","entity_type":"TV_SHOW","action_cta":"WATCH","description":"A missing child sets four families on a frantic hunt.","metadata":{"rating":8.8,"release_year":"2017"}}]',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CaptureCardWidget(capture: capture),
        ),
      ),
    );

    expect(find.text('WATCH'), findsNWidgets(2)); // Intent badge + CTA button
    expect(find.text('Entertainment'), findsOneWidget);
    expect(find.text('Best psychological thriller on Netflix: Dark'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('8.8'), findsOneWidget);
    expect(find.text('2017'), findsOneWidget);
  });
}
