/// Latyr Progressive Blur — Owned Fragment Shader
/// 
/// A 2-pass separable Gaussian backdrop filter with per-pixel variable sigma.
/// Matches Figma "Effects → Background blur → Progressive" behaviour.
///
/// Engine contract (Impeller / BackdropFilterLayer via ui.ImageFilter.shader):
///   uniform[0]: vec2  u_size     — engine auto-fills: input texture size (physical px)
///   uniform[1]: sampler2D        — engine auto-binds: background snapshot
///   uniform[2]: float u_sigma_start
///   uniform[3]: float u_sigma_end
///   uniform[4]: float u_direction  (0 = horizontal pass, 1 = vertical pass)
///   uniform[5]: float u_begin_x
///   uniform[6]: float u_begin_y    (gradient start, normalised 0-1, top-to-bottom)
///   uniform[7]: float u_end_x
///   uniform[8]: float u_end_y      (gradient end,   normalised 0-1, top-to-bottom)
///
/// Performance notes:
///   • MAX_RADIUS 37 → max kernel = 75 taps/pass.  Sigma is clamped to 12.3 px
///     (physical), which at 3× DPI = 4.1 logical px — more than enough for a
///     status-bar blur that fully dissolves within ~60–70 px height.
///   • Two-pass separable convolution: total taps ≤ 75 + 75 = 150 per pixel,
///     vs a naive 2-D kernel which would be 75² = 5 625.
///   • At sigma < 0.5 px the shader early-exits with a plain texture sample
///     (the no-blur region at the transparent end of the gradient costs nothing).

#version 460 core
#include <flutter/runtime_effect.glsl>

// Maximum Gaussian half-radius supported.
// kernel_size_max = 2 * MAX_RADIUS + 1 = 75 taps.
// Supports sigma up to MAX_RADIUS / 3.0 ≈ 12.3 physical pixels.
#define MAX_RADIUS 37

uniform vec2 u_size;         // physical-pixel size of the background snapshot
uniform sampler2D u_texture; // background snapshot (auto-bound by the engine)

uniform float u_sigma_start; // Gaussian sigma (physical px) at the gradient start
uniform float u_sigma_end;   // Gaussian sigma (physical px) at the gradient end
uniform float u_direction;   // 0 = horizontal pass, 1 = vertical pass
uniform float u_begin_x;     // gradient start — normalised x in screen [0,1]
uniform float u_begin_y;     // gradient start — normalised y in screen [0,1]
uniform float u_end_x;       // gradient end   — normalised x in screen [0,1]
uniform float u_end_y;       // gradient end   — normalised y in screen [0,1]

out vec4 frag_color;

void main() {
  // FlutterFragCoord is the vertex-interpolated position in the rectangle
  // allocated by the engine for this BackdropFilter layer (usually the entire
  // screen).  Dividing by u_size gives the normalised UV in [0, 1].
  vec2 uv = FlutterFragCoord().xy / u_size;

  // On OpenGL ES (Impeller's GLES backend) the texture y-axis is flipped
  // relative to FlutterFragCoord's top-to-bottom convention.
  vec2 sample_uv = uv;
#ifdef IMPELLER_TARGET_OPENGLES
  sample_uv.y = 1.0 - uv.y;
#endif

  // ── Progressive sigma ────────────────────────────────────────────────────
  // Project this fragment's UV onto the begin→end axis to get a blend factor
  // t ∈ [0, 1].  Uses a safe denominator to avoid NaN when begin == end.
  vec2 begin_pt = vec2(u_begin_x, u_begin_y);
  vec2 end_pt   = vec2(u_end_x,   u_end_y);
  vec2 axis     = end_pt - begin_pt;
  float denom   = max(dot(axis, axis), 1e-10);
  float t       = clamp(dot(uv - begin_pt, axis) / denom, 0.0, 1.0);
  float sigma   = mix(u_sigma_start, u_sigma_end, t);

  // ── Early exit — no blur ─────────────────────────────────────────────────
  // At the transparent end of the gradient, sigma approaches 0.  Skip the
  // convolution loop entirely for sub-pixel sigmas.
  if (sigma < 0.5) {
    frag_color = texture(u_texture, sample_uv);
    return;
  }

  // ── Clamp sigma to kernel capacity ──────────────────────────────────────
  // MAX_RADIUS = 37 → supports sigma up to 37.0/3.0 ≈ 12.3 physical pixels.
  // All arithmetic kept in float to satisfy both SkSL and GLSL compilers.
  // (SkSL does not support min(int, int).)
  float max_radius_f = 37.0;
  sigma = min(sigma, max_radius_f / 3.0);

  // Radius as float, then cast to int once clamped.
  float radius_f  = clamp(ceil(3.0 * sigma), 0.0, max_radius_f);
  int   radius    = int(radius_f);
  float kernel_f  = 2.0 * radius_f + 1.0;

  // Convolution direction vector (one axis per pass).
  vec2 dir = u_direction < 0.5 ? vec2(1.0, 0.0) : vec2(0.0, 1.0);

  // ── Separable Gaussian convolution ──────────────────────────────────────
  vec4  color        = vec4(0.0);
  float total_weight = 0.0;

  // Loop bound MUST be a literal constant for SkSL compatibility.
  // We iterate 2*37+1 = 75 times maximum and break early using a float
  // comparison against kernel_f (avoids int arithmetic that SkSL rejects).
  for (int i = 0; i < 75; i++) {
    float fi = float(i);
    if (fi >= kernel_f) break;

    float tap    = fi - radius_f;
    float weight = exp(-(tap * tap) / (2.0 * sigma * sigma));
    total_weight += weight;

    vec2 offset = vec2(tap) / u_size;
    color += texture(u_texture, sample_uv + offset * dir) * weight;
  }

  frag_color = color / total_weight;
}
