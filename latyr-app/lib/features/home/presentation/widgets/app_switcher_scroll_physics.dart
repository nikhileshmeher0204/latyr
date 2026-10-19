import 'package:flutter/widgets.dart';

/// AppSwitcherScrollPhysics
///
/// An authentic iOS App Switcher-grade scroll physics engine for Flutter.
///
/// Features:
/// 1. Unconstrained multi-card momentum flings: user can swipe across 5-6 cards
///    with a single vigorous flick, matching the iOS multitasking app switcher.
/// 2. Magnetic, critically-damped spring snapping: always lands and locks exactly
///    one card at the center slot upon coming to rest (no awkward halfway stopping).
/// 3. Authentic iOS rubber-band overscroll resistance and bounce at edges.
/// 4. Dynamic spring duration scaling based on distance for 120Hz silky smoothness.
class AppSwitcherScrollPhysics extends ScrollPhysics {
  /// Velocity required to travel one card distance during a fling.
  /// Lower values allow a flick to travel further across more cards.
  /// Tuned to 700.0 px/s so standard flings skip 2-4 cards, and fast swipes skip 5-6 cards.
  final double velocityPerCard;

  /// Minimum velocity required to register as an intentional flick rather than a slow drag release.
  final double minFlickVelocity;

  const AppSwitcherScrollPhysics({
    super.parent,
    this.velocityPerCard = 700.0,
    this.minFlickVelocity = 150.0,
  });

  @override
  AppSwitcherScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AppSwitcherScrollPhysics(
      parent: buildParent(ancestor),
      velocityPerCard: velocityPerCard,
      minFlickVelocity: minFlickVelocity,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // When out of bounds, apply authentic iOS cubic-root rubber banding
    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart =
        (position.minScrollExtent - position.pixels).clamp(0.0, double.infinity);
    final double overscrollPastEnd =
        (position.pixels - position.maxScrollExtent).clamp(0.0, double.infinity);
    final double overscrollPast =
        overscrollPastStart > 0 ? overscrollPastStart : overscrollPastEnd;

    // Standard iOS rubber-band equation: offset * (1 - overscroll / (overscroll + dimension * 0.5))
    final double friction = 1.0 -
        (overscrollPast / (overscrollPast + position.viewportDimension * 0.5));
    return offset * friction.clamp(0.05, 1.0);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    // 1. Boundary Handling: If already out of range, spring back to bounds
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        _kOverScrollSpring,
        position.pixels,
        position.minScrollExtent,
        velocity,
        tolerance: tolerance,
      );
    }
    if (position.pixels > position.maxScrollExtent) {
      return ScrollSpringSimulation(
        _kOverScrollSpring,
        position.pixels,
        position.maxScrollExtent,
        velocity,
        tolerance: tolerance,
      );
    }

    final double pageWidth = position.viewportDimension;
    if (pageWidth <= 0.0) return null;

    final double currentPage = position.pixels / pageWidth;
    final double absVelocity = velocity.abs();
    double targetPage;

    if (absVelocity < minFlickVelocity) {
      // Gentle release: magnetic snap to the nearest card
      targetPage = currentPage.roundToDouble();
    } else {
      // Momentum fling: momentum scales smoothly with velocity (Newtonian friction)
      final double direction = velocity.sign;
      final double cardsDelta = velocity / velocityPerCard;
      double candidate = currentPage + cardsDelta;

      // Ensure that any flick >= minFlickVelocity advances at least 1 whole card
      if (direction > 0 && candidate < currentPage.floorToDouble() + 1.0) {
        candidate = currentPage.floorToDouble() + 1.0;
      } else if (direction < 0 && candidate > currentPage.ceilToDouble() - 1.0) {
        candidate = currentPage.ceilToDouble() - 1.0;
      }

      targetPage = candidate.roundToDouble();
    }

    // Clamp to valid page range
    final double minPage = position.minScrollExtent / pageWidth;
    final double maxPage = position.maxScrollExtent / pageWidth;
    targetPage = targetPage.clamp(minPage, maxPage);

    final double targetPixels = targetPage * pageWidth;

    // If already at the target with negligible velocity, rest immediately
    if ((targetPixels - position.pixels).abs() < tolerance.distance &&
        absVelocity < tolerance.velocity) {
      return null;
    }

    // Dynamic spring calibration:
    // Scale duration with distance so 1 card snaps crisply in ~300ms,
    // while 5-6 cards glide smoothly over ~750ms before settling.
    final double distanceInCards = (targetPage - currentPage).abs();
    final double targetDuration =
        (0.30 + (distanceInCards * 0.08)).clamp(0.30, 0.82);
    final double omega = 4.0 / targetDuration; // Critical damping frequency
    const double mass = 1.0;
    final double stiffness = omega * omega * mass;
    final double damping = 2.0 * omega * mass * 0.98; // 0.98 ratio = organic Apple soft landing

    final SpringDescription customSpring = SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );

    return ScrollSpringSimulation(
      customSpring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }

  static const SpringDescription _kOverScrollSpring = SpringDescription(
    mass: 0.5,
    stiffness: 140.0,
    damping: 16.0,
  );
}
