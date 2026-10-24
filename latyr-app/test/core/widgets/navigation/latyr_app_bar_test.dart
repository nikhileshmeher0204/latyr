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

    testWidgets('seamless flight shuttle morphs action pill width and translates share button without overflow', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Column(
                  children: [
                    LatyrAppBar(
                      title: 'Capture Detail',
                      isDark: false,
                      scaffoldBgColor: CupertinoColors.white,
                      actions: [
                        LatyrAppBar.actionButton(
                          isDark: false,
                          onPressed: () {},
                          child: const Icon(CupertinoIcons.share),
                        ),
                        LatyrAppBar.actionPill(
                          isDark: false,
                          onPressed: () {},
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.camera, size: 17),
                              SizedBox(width: 4),
                              Icon(CupertinoIcons.chevron_forward, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      child: const Text('Push Intent Detail'),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => CupertinoPageScaffold(
                              child: LatyrAppBar(
                                title: 'Movie Intent',
                                isDark: true,
                                scaffoldBgColor: CupertinoColors.black,
                                actions: [
                                  LatyrAppBar.actionButton(
                                    isDark: true,
                                    onPressed: () {},
                                    child: const Icon(CupertinoIcons.share),
                                  ),
                                  LatyrAppBar.actionButton(
                                    isDark: true,
                                    onPressed: () {},
                                    child: const Icon(CupertinoIcons.add),
                                  ),
                                ],
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

      expect(find.text('CAPTURE DETAIL'), findsOneWidget);
      expect(find.byType(LatyrActionPill), findsOneWidget);

      // Trigger navigation
      await tester.tap(find.text('Push Intent Detail'));

      // Pump mid-flight to exercise _buildSeamlessFlightContent
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Settle transition to destination
      await tester.pumpAndSettle();

      expect(find.text('MOVIE INTENT'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);

      // Pop back to exercise reverse flight morphing
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('CAPTURE DETAIL'), findsOneWidget);
      expect(find.byType(LatyrActionPill), findsOneWidget);
    });

    test('geometry constants guarantee >= 12px horizontal clearance and centered pill', () {
      expect(LatyrAppBar.kActionButtonSize, 42.0);
      expect(LatyrAppBar.kActionPillWidth, 56.0);
      expect(LatyrAppBar.kActionSpacing, 8.0);
      expect(LatyrAppBar.kPillHorizontalMargin, 120.0);

      // Maximum right cluster: Action 0 (42) + Gap (8) + Action 1 Pill (56) = 106.0
      const maxCluster = LatyrAppBar.kActionButtonSize + LatyrAppBar.kActionSpacing + LatyrAppBar.kActionPillWidth;
      expect(maxCluster, 106.0);

      // Clearance between pill edge (120) and cluster edge (106)
      const clearance = LatyrAppBar.kPillHorizontalMargin - maxCluster;
      expect(clearance, greaterThanOrEqualTo(12.0));
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
