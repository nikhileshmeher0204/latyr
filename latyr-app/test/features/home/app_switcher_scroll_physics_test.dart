import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/home/presentation/widgets/app_switcher_scroll_physics.dart';

void main() {
  group('AppSwitcherScrollPhysics Tests', () {
    const physics = AppSwitcherScrollPhysics(
      velocityPerCard: 700.0,
      minFlickVelocity: 150.0,
    );

    test('gentle drag release snaps to nearest whole card', () {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 3000.0,
        pixels: 430.0, // viewportDimension = 400, page = 1.075
        viewportDimension: 400.0,
        axisDirection: AxisDirection.right,
        devicePixelRatio: 1.0,
      );

      final sim = physics.createBallisticSimulation(metrics, 50.0);
      expect(sim, isNotNull);
      expect(sim, isA<ScrollSpringSimulation>());
      // Should snap to page 1.0 -> 400.0 pixels
      final springSim = sim! as ScrollSpringSimulation;
      // Evaluate at large time t to verify final resting position
      expect(springSim.x(2.0), closeTo(400.0, 1.0));
    });

    test('fast swipe flings across multiple cards (5-6 cards)', () {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 4000.0,
        pixels: 400.0, // page 1.0
        viewportDimension: 400.0,
        axisDirection: AxisDirection.right,
        devicePixelRatio: 1.0,
      );

      // Fling forward with high velocity (3800 px/s)
      // 3800 / 700 = ~5.4 cards -> page 1 + 5.4 = ~6.4 -> page 6 (2400.0 px)
      final sim = physics.createBallisticSimulation(metrics, 3800.0);
      expect(sim, isNotNull);
      expect(sim, isA<ScrollSpringSimulation>());
      final springSim = sim! as ScrollSpringSimulation;
      expect(springSim.x(3.0), closeTo(2400.0, 2.0));
    });

    test('overscroll past minExtent triggers boundary spring back', () {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 2000.0,
        pixels: -120.0, // overscrolled past start
        viewportDimension: 400.0,
        axisDirection: AxisDirection.right,
        devicePixelRatio: 1.0,
      );

      final sim = physics.createBallisticSimulation(metrics, -200.0);
      expect(sim, isNotNull);
      final springSim = sim! as ScrollSpringSimulation;
      expect(springSim.x(2.0), closeTo(0.0, 1.0));
    });

    test('overscroll past maxExtent triggers boundary spring back', () {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 2000.0,
        pixels: 2150.0, // overscrolled past end
        viewportDimension: 400.0,
        axisDirection: AxisDirection.right,
        devicePixelRatio: 1.0,
      );

      final sim = physics.createBallisticSimulation(metrics, 300.0);
      expect(sim, isNotNull);
      final springSim = sim! as ScrollSpringSimulation;
      expect(springSim.x(2.0), closeTo(2000.0, 1.0));
    });
  });
}
