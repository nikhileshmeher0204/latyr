/// LatyrProgressiveBlur
///
/// A zero-dependency, production-grade progressive backdrop blur widget.
///
/// ── What it does ────────────────────────────────────────────────────────────
/// Renders a true variable-sigma Gaussian blur over the scene behind it,
/// smoothly transitioning from [sigmaStart] at [begin] to [sigmaEnd] at [end]
/// (default: full blur at top, transparent at bottom).  A tint [child] is
/// painted above the blur layer so callers can overlay a colour gradient.
///
/// ── Runtime selection ───────────────────────────────────────────────────────
/// • Good devices (Impeller + Vulkan, Android API ≥ 29; all iOS):
///     Uses our custom 2-pass separable Gaussian fragment shader
///     (lib/shaders/latyr_progressive_blur.frag).
///     Single GPU pass — designed for 120 Hz ProMotion.
///
/// • Low-spec / Skia backend (Android < API 29, GLES-only, Web):
///     No blur is applied.  The [child] tint is still painted, so the
///     navigation bar / status bar area remains readable.
///     Zero GPU overhead on these devices.
///
/// ── Shader precache ─────────────────────────────────────────────────────────
/// Call [LatyrProgressiveBlur.precache()] before runApp() in main.dart to
/// compile the shader off the hot path and avoid an unblurred first frame.
///
/// ── Usage ───────────────────────────────────────────────────────────────────
/// ```dart
/// Positioned(
///   top: 0, left: 0, right: 0,
///   height: topPadding + 14.0,
///   child: IgnorePointer(
///     child: LatyrProgressiveBlur(
///       sigmaStart: 20.0,
///       sigmaEnd:   0.0,
///       child: DecoratedBox(
///         decoration: BoxDecoration(
///           gradient: LinearGradient(
///             begin: Alignment.topCenter,
///             end:   Alignment.bottomCenter,
///             colors: [bgColor.withValues(alpha: 0.85), Colors.transparent],
///           ),
///         ),
///       ),
///     ),
///   ),
/// )
/// ```

library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A zero-dependency progressive backdrop blur widget for Latyr.
/// See file-level doc above for full details.
class LatyrProgressiveBlur extends StatefulWidget {
  const LatyrProgressiveBlur({
    super.key,
    this.enabled = true,
    this.sigmaStart = 20.0,
    this.sigmaEnd = 0.0,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.child,
  });

  /// Whether the progressive blur is active. If false, renders only [child] (if any).
  final bool enabled;

  /// Gaussian sigma (logical pixels) at the [begin] alignment.
  /// Full blur intensity — typically the status-bar edge.
  final double sigmaStart;

  /// Gaussian sigma (logical pixels) at the [end] alignment.
  /// Should be 0.0 so the blur dissolves into crisp content with no hard edge.
  final double sigmaEnd;

  /// Where the maximum blur starts within the widget, default top-centre.
  final Alignment begin;

  /// Where the blur has fully dissolved, default bottom-centre.
  final Alignment end;

  /// Optional child painted *above* the blur layer (e.g. a tint gradient).
  final Widget? child;

  // ── Internal shader lifecycle ─────────────────────────────────────────────

  static const String _kShaderAsset = 'lib/shaders/latyr_progressive_blur.frag';
  static ui.FragmentProgram? _program;

  /// Compiles the shader off the hot path.
  /// Call this in main() before runApp() for a blur-on-first-frame experience.
  /// No-op on unsupported platforms.
  static Future<void> precache() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    try {
      _program ??= await ui.FragmentProgram.fromAsset(_kShaderAsset);
    } catch (e) {
      // Shader load failure is non-fatal: fallback (no blur) is used.
      debugPrint('[LatyrProgressiveBlur] shader load failed: $e');
    }
  }

  @override
  State<LatyrProgressiveBlur> createState() => _LatyrProgressiveBlurState();
}

class _LatyrProgressiveBlurState extends State<LatyrProgressiveBlur> {
  @override
  void initState() {
    super.initState();
    // If the shader is not yet loaded (e.g. precache wasn't called), kick off
    // an async load and redraw once it completes.
    if (LatyrProgressiveBlur._program == null &&
        ui.ImageFilter.isShaderFilterSupported) {
      LatyrProgressiveBlur.precache().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = LatyrProgressiveBlur._program;

    // ── Fallback: no blur ────────────────────────────────────────────────────
    // If disabled via flag, shader not supported (Skia backend, Android < API 29),
    // or shader not yet loaded: render only the tint child — zero GPU overhead.
    if (!widget.enabled || !ui.ImageFilter.isShaderFilterSupported || program == null) {
      return widget.child ?? const SizedBox.shrink();
    }

    // ── High-quality shader path ─────────────────────────────────────────────
    return _ShaderProgressiveBlur(
      program: program,
      sigmaStart: widget.sigmaStart.clamp(0.0, 100.0),
      sigmaEnd: widget.sigmaEnd.clamp(0.0, 100.0),
      begin: widget.begin,
      end: widget.end,
      viewSize: MediaQuery.sizeOf(context),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal RenderObject-based widget
//
// Uses a custom RenderObject so we can obtain the widget's *global* position
// at paint time (after layout) and convert it to the normalised texture
// coordinates that the shader expects.
// ─────────────────────────────────────────────────────────────────────────────

class _ShaderProgressiveBlur extends SingleChildRenderObjectWidget {
  const _ShaderProgressiveBlur({
    required this.program,
    required this.sigmaStart,
    required this.sigmaEnd,
    required this.begin,
    required this.end,
    required this.viewSize,
    required this.devicePixelRatio,
    super.child,
  });

  final ui.FragmentProgram program;
  final double sigmaStart;
  final double sigmaEnd;
  final Alignment begin;
  final Alignment end;
  final Size viewSize;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShaderProgressiveBlur(
        program: program,
        sigmaStart: sigmaStart,
        sigmaEnd: sigmaEnd,
        begin: begin,
        end: end,
        viewSize: viewSize,
        devicePixelRatio: devicePixelRatio,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderShaderProgressiveBlur renderObject) {
    renderObject
      ..sigmaStart = sigmaStart
      ..sigmaEnd = sigmaEnd
      ..begin = begin
      ..end = end
      ..viewSize = viewSize
      ..devicePixelRatio = devicePixelRatio;
  }
}

class _RenderShaderProgressiveBlur extends RenderProxyBox {
  // ignore: prefer_initializing_formals
  _RenderShaderProgressiveBlur({
    required ui.FragmentProgram program,
    required double sigmaStart,
    required double sigmaEnd,
    required Alignment begin,
    required Alignment end,
    required Size viewSize,
    required double devicePixelRatio,
  })  : _sigmaStart = sigmaStart,
        _sigmaEnd = sigmaEnd,
        _begin = begin,
        _end = end,
        _viewSize = viewSize,
        _devicePixelRatio = devicePixelRatio,
        // Allocate two shader instances — one per convolution pass.
        // They share the same program (same GPU binary) but hold independent
        // uniform state, so each pass can be configured separately without
        // interference.
        _hShader = program.fragmentShader(),
        _vShader = program.fragmentShader();

  // ── Two-pass convolution shader instances ────────────────────────────────
  final ui.FragmentShader _hShader; // horizontal pass
  final ui.FragmentShader _vShader; // vertical   pass

  // The composed filter is recreated each paint because the engine snapshots
  // uniform state at first use (late-final on the native side).  Reusing a
  // stale filter would ignore uniform changes.
  ui.ImageFilter? _filter;

  // ── Mutable properties (mark needs-paint when changed) ───────────────────

  double _sigmaStart;
  double get sigmaStart => _sigmaStart;
  set sigmaStart(double v) {
    if (v == _sigmaStart) return;
    _sigmaStart = v;
    markNeedsPaint();
  }

  double _sigmaEnd;
  double get sigmaEnd => _sigmaEnd;
  set sigmaEnd(double v) {
    if (v == _sigmaEnd) return;
    _sigmaEnd = v;
    markNeedsPaint();
  }

  Alignment _begin;
  Alignment get begin => _begin;
  set begin(Alignment v) {
    if (v == _begin) return;
    _begin = v;
    markNeedsPaint();
  }

  Alignment _end;
  Alignment get end => _end;
  set end(Alignment v) {
    if (v == _end) return;
    _end = v;
    markNeedsPaint();
  }

  Size _viewSize;
  Size get viewSize => _viewSize;
  set viewSize(Size v) {
    if (v == _viewSize) return;
    _viewSize = v;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double v) {
    if (v == _devicePixelRatio) return;
    _devicePixelRatio = v;
    markNeedsPaint();
  }

  // ── Compositing ──────────────────────────────────────────────────────────

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  // ── Uniform configuration ────────────────────────────────────────────────
  //
  // Uniform layout (matches latyr_progressive_blur.frag):
  //   [0,1]  vec2  u_size         — engine auto-fills, skip
  //   [1]    sampler2D u_texture  — engine auto-binds, skip
  //   [2]    float u_sigma_start
  //   [3]    float u_sigma_end
  //   [4]    float u_direction
  //   [5]    float u_begin_x
  //   [6]    float u_begin_y
  //   [7]    float u_end_x
  //   [8]    float u_end_y
  void _configureShader(
    ui.FragmentShader shader,
    double direction,
    Offset beginNorm,
    Offset endNorm,
  ) {
    shader
      ..setFloat(2, _sigmaStart * _devicePixelRatio) // convert logical → physical px
      ..setFloat(3, _sigmaEnd * _devicePixelRatio)
      ..setFloat(4, direction)
      ..setFloat(5, beginNorm.dx)
      ..setFloat(6, beginNorm.dy)
      ..setFloat(7, endNorm.dx)
      ..setFloat(8, endNorm.dy);
  }

  // ── Paint ────────────────────────────────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    // Obtain the widget's global (screen) position at paint time.
    // localToGlobal(Offset.zero) is accurate even when the widget has been
    // repositioned purely through compositing (e.g. Positioned in a Stack).
    final Offset globalTopLeft = localToGlobal(Offset.zero);

    // Convert to normalised [0,1] coordinates inside the background snapshot,
    // which covers the full logical viewport.
    final double l = (globalTopLeft.dx / _viewSize.width).clamp(0.0, 1.0);
    final double t = (globalTopLeft.dy / _viewSize.height).clamp(0.0, 1.0);
    final double r =
        ((globalTopLeft.dx + size.width) / _viewSize.width).clamp(0.0, 1.0);
    final double b =
        ((globalTopLeft.dy + size.height) / _viewSize.height).clamp(0.0, 1.0);

    // Map Alignment(-1..1) to the widget's normalised region on screen.
    Offset alignToNorm(Alignment a) => Offset(
          l + (a.x + 1.0) / 2.0 * (r - l),
          t + (a.y + 1.0) / 2.0 * (b - t),
        );

    final Offset beginNorm = alignToNorm(_begin);
    final Offset endNorm = alignToNorm(_end);

    // Write uniforms then recreate the filter (must happen AFTER setFloat).
    _configureShader(_hShader, 0.0, beginNorm, endNorm); // horizontal pass
    _configureShader(_vShader, 1.0, beginNorm, endNorm); // vertical   pass

    _filter = ui.ImageFilter.compose(
      inner: ui.ImageFilter.shader(_hShader),
      outer: ui.ImageFilter.shader(_vShader),
    );

    // Push a BackdropFilterLayer so Flutter composites the blur against the
    // scene content that was rendered *before* this layer.
    assert(needsCompositing);
    layer ??= BackdropFilterLayer();
    layer!
      ..filter = _filter
      ..blendMode = BlendMode.srcOver;
    context.pushLayer(layer!, super.paint, offset);
  }

  @override
  void dispose() {
    _hShader.dispose();
    _vShader.dispose();
    super.dispose();
  }
}
