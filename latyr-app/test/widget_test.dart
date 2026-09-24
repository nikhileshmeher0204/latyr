import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/app.dart';

void main() {
  testWidgets('LatyrApp smoke test: renders Amber & Obsidian navigation and Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LatyrApp(),
      ),
    );

    // Verify Home headline
    expect(find.text('Good evening, Nikhilesh'), findsOneWidget);
    expect(find.text('Everything worth\ncoming back to.'), findsOneWidget);

    // Verify Ingestion Banner & For You section
    expect(find.text('Share anything. Forget nothing.'), findsOneWidget);
    expect(find.text('For you'), findsOneWidget);

    // Verify Navigation Island
    expect(find.text('Home'), findsOneWidget);
  });
}

