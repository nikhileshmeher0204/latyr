import 'package:flutter/cupertino.dart';

/// Latyr spacing & geometry tokens — aligned with Apple HIG.
///
/// Apple uses an 8pt grid with 4pt half-grid for fine adjustments.
/// Corner radii follow the Continuous Cupertino curve for cards and
/// the standard circular value for pills.
class LSpacing {
  LSpacing._();

  // ─── Base Grid ─────────────────────────────────────────────────────────────

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double xl3 = 44.0; // Apple minimum tap target
  static const double xl4 = 56.0;

  // ─── Semantic Spacing ──────────────────────────────────────────────────────

  /// Standard screen horizontal padding (matches iOS edge-to-content)
  static const double screenH = 20.0;

  /// Standard screen top padding
  static const double screenTop = 12.0;

  /// Bottom inset so content is above the floating nav island
  static const double navIslandClear = 100.0;

  /// Gap between section header and content
  static const double sectionGap = 10.0;

  /// Gap between major sections
  static const double sectionSpacing = 24.0;

  /// Gap between cards in a list
  static const double cardGap = 10.0;

  /// Horizontal padding inside a card
  static const double cardPaddingH = 16.0;

  /// Vertical padding inside a card
  static const double cardPaddingV = 14.0;

  // ─── Border Radii ──────────────────────────────────────────────────────────

  /// Smallest rounding — tag pills, status chips
  static const double radiusXS = 8.0;

  /// Small — icon containers, small cards
  static const double radiusSM = 12.0;

  /// Medium — input fields, smaller cards
  static const double radiusMD = 16.0;

  /// Large — standard cards
  static const double radiusLG = 20.0;

  /// Extra large — hero cards, modal sheets
  static const double radiusXL = 24.0;

  /// Sheet modal top radius
  static const double radiusSheet = 28.0;

  /// Full pill / capsule
  static const double radiusPill = 100.0;

  // ─── Border Radii as BorderRadius objects ──────────────────────────────────

  static final BorderRadius brXS = BorderRadius.circular(radiusXS);
  static final BorderRadius brSM = BorderRadius.circular(radiusSM);
  static final BorderRadius brMD = BorderRadius.circular(radiusMD);
  static final BorderRadius brLG = BorderRadius.circular(radiusLG);
  static final BorderRadius brXL = BorderRadius.circular(radiusXL);
  static final BorderRadius brSheet = BorderRadius.only(
    topLeft: Radius.circular(radiusSheet),
    topRight: Radius.circular(radiusSheet),
  );
  static final BorderRadius brPill = BorderRadius.circular(radiusPill);

  // ─── Apple Minimum Tap Target ──────────────────────────────────────────────

  /// Apple HIG minimum: 44×44pt for any interactive element
  static const double minTapTarget = 44.0;

  // ─── Nav Island ────────────────────────────────────────────────────────────

  static const double navIslandHeight = 58.0;
  static const double navIslandMarginH = 18.0;
  static const double navIslandMarginV = 12.0;

  // ─── Glass Blur ────────────────────────────────────────────────────────────

  /// Standard card blur
  static const double blurCard = 24.0;

  /// Heavier nav bar / sheet blur
  static const double blurNav = 28.0;
}
