import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';

enum AmbientBackgroundMode { ambient, alabaster, obsidian }

/// Full-bleed adaptive background — warm golden mesh in light, obsidian in dark.
///
/// In ambient mode (default): auto-selects between warm honey gradient (light)
/// and obsidian with subtle amber glow (dark) based on system brightness.
class AmbientMeshBackground extends StatelessWidget {
  final Widget child;
  final AmbientBackgroundMode mode;

  const AmbientMeshBackground({
    super.key,
    required this.child,
    this.mode = AmbientBackgroundMode.ambient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (mode == AmbientBackgroundMode.obsidian ||
        (mode == AmbientBackgroundMode.ambient && isDark)) {
      return _buildDarkBackground();
    }

    // Light / Alabaster
    return _buildLightBackground();
  }

  Widget _buildLightBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        gradient: RadialGradient(
          center: Alignment(1.0, 0.7),
          radius: 1.4,
          colors: [
            LColors.ambientHoney,
            LColors.ambientWarmGlow,
            Color(0xFFFAF9F6),
          ],
          stops: [0.0, 0.45, 0.85],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft secondary top-right ambient warmth
          Positioned(
            top: -100,
            right: -60,
            width: 320,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LColors.ambientWheat.withValues(alpha: 0.4),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildDarkBackground() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E10),
        gradient: RadialGradient(
          center: const Alignment(0.7, -0.5),
          radius: 1.3,
          colors: [
            LColors.brandAmber.withValues(alpha: 0.06), // very subtle amber glow
            const Color(0x00000000),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom-left subtle secondary glow
          Positioned(
            bottom: -80,
            left: -40,
            width: 280,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LColors.brandAmber.withValues(alpha: 0.04),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
