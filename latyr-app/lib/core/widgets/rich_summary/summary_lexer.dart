import 'summary_token.dart';

/// A high-performance, linear-time tokenizer that transforms Latyr's
/// extended editorial markdown into a list of typed [SummaryToken]s.
class SummaryLexer {
  SummaryLexer._();

  /// Unified regular expression capturing all supported markup tokens:
  /// Group 1 & 2: Highlight `==text==`
  /// Group 3 & 4: Wavy underline `~text~`
  /// Group 5 & 6: Italic `*text*`
  /// Group 7 & 8: 3D icon `[icon:name]`
  /// Group 9, 10, 11: Smart link `[text](target)`
  static final RegExp _tokenRegex = RegExp(
    r'(==(?<highlight>[^=\n]+)==)'
    r'|(~(?<wavy>[^~\n]+)~)'
    r'|(\*(?<italic>[^*\n]+)\*)'
    r'|(\[icon:(?<icon>[a-zA-Z0-9_\-]+)\])'
    r'|(\[(?<linkText>[^\]\n]+)\]\s*\((?<linkTarget>[^)\n]+)\))',
  );

  /// Tokenizes [rawText] into an ordered list of [SummaryToken] objects.
  ///
  /// Never throws on invalid syntax or unclosed tags; unparsed or plain
  /// portions are gracefully emitted as [SummaryTokenType.plain] tokens.
  static List<SummaryToken> tokenize(String? rawText) {
    if (rawText == null || rawText.isEmpty) {
      return const [];
    }

    final matches = _tokenRegex.allMatches(rawText);
    if (matches.isEmpty) {
      return [SummaryToken.plain(rawText)];
    }

    final tokens = <SummaryToken>[];
    int cursor = 0;

    for (final match in matches) {
      // Emit plain text preceding this match (if any)
      if (match.start > cursor) {
        tokens.add(SummaryToken.plain(rawText.substring(cursor, match.start)));
      }

      final highlight = match.namedGroup('highlight');
      final wavy = match.namedGroup('wavy');
      final italic = match.namedGroup('italic');
      final icon = match.namedGroup('icon');
      final linkText = match.namedGroup('linkText');
      final linkTarget = match.namedGroup('linkTarget');

      if (highlight != null && highlight.isNotEmpty) {
        tokens.add(SummaryToken.highlight(highlight));
      } else if (wavy != null && wavy.isNotEmpty) {
        tokens.add(SummaryToken.wavyUnderline(wavy));
      } else if (italic != null && italic.isNotEmpty) {
        tokens.add(SummaryToken.italic(italic));
      } else if (icon != null && icon.isNotEmpty) {
        tokens.add(SummaryToken.icon3d(icon.toLowerCase().trim()));
      } else if (linkText != null && linkTarget != null) {
        final parsedLink = _parseLinkTarget(linkText, linkTarget);
        tokens.add(parsedLink);
      }

      cursor = match.end;
    }

    // Emit trailing plain text (if any)
    if (cursor < rawText.length) {
      tokens.add(SummaryToken.plain(rawText.substring(cursor)));
    }

    return tokens;
  }

  /// Parses `scheme:payload` or handles direct URLs (`http://`, `https://`).
  static SummaryToken _parseLinkTarget(String text, String target) {
    final trimmedTarget = target.trim();

    if (trimmedTarget.startsWith('http://') || trimmedTarget.startsWith('https://')) {
      return SummaryToken.smartLink(
        text: text,
        actionScheme: 'https',
        actionPayload: trimmedTarget,
      );
    }

    final colonIdx = trimmedTarget.indexOf(':');
    if (colonIdx > 0 && colonIdx < trimmedTarget.length - 1) {
      final scheme = trimmedTarget.substring(0, colonIdx).trim().toLowerCase();
      final payload = trimmedTarget.substring(colonIdx + 1).trim();
      return SummaryToken.smartLink(
        text: text,
        actionScheme: scheme,
        actionPayload: payload,
      );
    }

    // Default fallback: search query
    return SummaryToken.smartLink(
      text: text,
      actionScheme: 'search',
      actionPayload: trimmedTarget,
    );
  }

  /// Strips all markup tags from [rawText], returning pristine plain text
  /// suitable for database full-text search indexing (`tsvector`) or vector embeddings.
  static String stripMarkup(String? rawText) {
    if (rawText == null || rawText.isEmpty) return '';
    return rawText
        .replaceAllMapped(RegExp(r'==([^=\n]+)=='), (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'~([^~\n]+)~'), (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'\*([^*\n]+)\*'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'\[icon:[a-zA-Z0-9_\-]+\]'), '')
        .replaceAllMapped(RegExp(r'\[([^\]\n]+)\]\s*\([^)\n]+\)'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
