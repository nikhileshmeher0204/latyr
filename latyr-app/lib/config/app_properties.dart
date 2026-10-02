/// Latyr Application & UI Configuration Properties.
///
/// Easily toggle UI features, blur effects, tints, and experimental settings here.
/// Values can be toggled directly by changing the default values below, or overridden
/// via `--dart-define` at build/run time:
///   `flutter run --dart-define=ENABLE_TOP_BLUR=false --dart-define=ENABLE_TOP_TINT=false`
class AppProperties {
  AppProperties._();

  /// Flag to enable or disable the progressive frosted background blur on top navigation bars
  /// and status bars across the application.
  ///
  /// Set to `false` to disable the blur shader completely.
  static const bool enableTopBlur = bool.fromEnvironment(
    'ENABLE_TOP_BLUR',
    defaultValue: true,
  );

  /// Flag to enable or disable the gradient wash tint on the top navigation bar area.
  ///
  /// Set to `false` to make the top bar area completely transparent without any background color tint.
  static const bool enableTopTint = bool.fromEnvironment(
    'ENABLE_TOP_TINT',
    defaultValue: true,
  );
}
