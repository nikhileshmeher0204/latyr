/// Semantic token types supported by Latyr's rich editorial summary engine.
enum SummaryTokenType {
  /// Regular plain editorial prose.
  plain,

  /// Yellow pastel marker highlighter (`==text==`).
  highlight,

  /// Cupertino red wavy underline (`~text~`).
  wavyUnderline,

  /// Editorial Georgia serif italic (`*text*`).
  italic,

  /// Inline 3D color icon (`[icon:name]`).
  icon3d,

  /// Actionable smart link (`[Label](scheme:payload)` or `[Label](url)`).
  smartLink,
}

/// An immutable token representing a parsed chunk of rich summary text.
class SummaryToken {
  final SummaryTokenType type;

  /// The text content to display.
  final String text;

  /// For [SummaryTokenType.icon3d], the key identifying the 3D asset (e.g. 'runner', 'rocket').
  final String? iconName;

  /// For [SummaryTokenType.smartLink], the action scheme (e.g. 'tip', 'github', 'maps', 'reminder', 'https').
  final String? actionScheme;

  /// Alias for [actionScheme].
  String? get actionType => actionScheme;

  /// For [SummaryTokenType.smartLink], the target query, URL, or definition text.
  final String? actionPayload;

  const SummaryToken({
    required this.type,
    required this.text,
    this.iconName,
    this.actionScheme,
    this.actionPayload,
  });

  /// Factory for a plain text token.
  const SummaryToken.plain(this.text)
      : type = SummaryTokenType.plain,
        iconName = null,
        actionScheme = null,
        actionPayload = null;

  /// Factory for a highlight token.
  const SummaryToken.highlight(this.text)
      : type = SummaryTokenType.highlight,
        iconName = null,
        actionScheme = null,
        actionPayload = null;

  /// Factory for a wavy underline token.
  const SummaryToken.wavyUnderline(this.text)
      : type = SummaryTokenType.wavyUnderline,
        iconName = null,
        actionScheme = null,
        actionPayload = null;

  /// Factory for an italic token.
  const SummaryToken.italic(this.text)
      : type = SummaryTokenType.italic,
        iconName = null,
        actionScheme = null,
        actionPayload = null;

  /// Factory for a 3D icon token.
  const SummaryToken.icon3d(this.iconName)
      : type = SummaryTokenType.icon3d,
        text = '',
        actionScheme = null,
        actionPayload = null;

  /// Factory for a smart link token.
  const SummaryToken.smartLink({
    required this.text,
    required this.actionScheme,
    required this.actionPayload,
  })  : type = SummaryTokenType.smartLink,
        iconName = null;

  @override
  String toString() => 'SummaryToken($type, "$text", icon: $iconName, action: $actionScheme:$actionPayload)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryToken &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          text == other.text &&
          iconName == other.iconName &&
          actionScheme == other.actionScheme &&
          actionPayload == other.actionPayload;

  @override
  int get hashCode => Object.hash(type, text, iconName, actionScheme, actionPayload);
}
