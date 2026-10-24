import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_scaffold.dart';

void main() {
  group('LatyrAppBar Tests', () {
    testWidgets('renders title, back button, and optional action', (tester) async {
      bool actionTapped = false;
      bool backTapped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LatyrAppBar(
              title: 'Movies',
              isDark: false,
              scaffoldBgColor: CupertinoColors.white,
              onBack: () => backTapped = true,
              actions: [
                LatyrAppBar.actionButton(
                  isDark: false,
                  onPressed: () => actionTapped = true,
                  child: const Icon(CupertinoIcons.share),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify title in upper case
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.share), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();
      expect(backTapped, isTrue);

      // Tap action button
      await tester.tap(find.byIcon(CupertinoIcons.share));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });

    testWidgets('renders optional titleLeading widget in bubble pill', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: LatyrAppBar(
              title: 'Cinema',
              titleLeading: Icon(CupertinoIcons.film, key: Key('film_icon')),
              isDark: true,
              scaffoldBgColor: CupertinoColors.black,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('film_icon')), findsOneWidget);
      expect(find.text('CINEMA'), findsOneWidget);
    });

    testWidgets('preferredHeight returns accurate topPadding + 68', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              final height = LatyrAppBar.preferredHeight(context);
              expect(height, greaterThan(58.0));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('persistent hero transition cross-fades smoothly between routes without type errors', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Column(
                  children: [
                    const LatyrAppBar(
                      title: 'Page One',
                      isDark: false,
                      scaffoldBgColor: CupertinoColors.white,
                    ),
                    CupertinoButton(
                      child: const Text('Push Next'),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const CupertinoPageScaffold(
                              child: LatyrAppBar(
                                title: 'Page Two',
                                isDark: true,
                                scaffoldBgColor: CupertinoColors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('PAGE ONE'), findsOneWidget);

      // Trigger navigation
      await tester.tap(find.text('Push Next'));

      // Pump mid-flight to exercise flightShuttleBuilder
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Complete transition
      await tester.pumpAndSettle();

      expect(find.text('PAGE TWO'), findsOneWidget);

      // Pop route to exercise reverse flightShuttleBuilder
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('PAGE ONE'), findsOneWidget);
    });
  });

  group('LatyrScaffold Tests', () {
    testWidgets('renders appBar, body, and backgroundAura', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: LatyrScaffold(
            appBar: LatyrAppBar(
              title: 'Sub-Category',
              isDark: false,
              scaffoldBgColor: CupertinoColors.white,
            ),
            backgroundAura: SizedBox(key: Key('aura')),
            body: Text('Body Content'),
          ),
        ),
      );

      expect(find.text('SUB-CATEGORY'), findsOneWidget);
      expect(find.byKey(const Key('aura')), findsOneWidget);
      expect(find.text('Body Content'), findsOneWidget);
    });
  });
}
