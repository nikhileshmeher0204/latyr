import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/widgets/rich_summary/summary_lexer.dart';
import 'package:latyr_app/core/widgets/rich_summary/summary_token.dart';

void main() {
  group('SummaryLexer Tokenization', () {
    test('handles empty or null text gracefully', () {
      expect(SummaryLexer.tokenize(null), isEmpty);
      expect(SummaryLexer.tokenize(''), isEmpty);
    });

    test('parses legacy unformatted plain text', () {
      const input = 'This is a regular summary without any markdown.';
      final tokens = SummaryLexer.tokenize(input);
      expect(tokens.length, 1);
      expect(tokens.first.type, SummaryTokenType.plain);
      expect(tokens.first.text, input);
    });

    test('parses yellow highlights ==text==', () {
      const input = 'Swarm LLM enables ==running 27B models== directly.';
      final tokens = SummaryLexer.tokenize(input);
      expect(tokens.length, 3);
      expect(tokens[0], const SummaryToken.plain('Swarm LLM enables '));
      expect(tokens[1], const SummaryToken.highlight('running 27B models'));
      expect(tokens[2], const SummaryToken.plain(' directly.'));
    });

    test('parses red wavy underlines ~text~', () {
      const input = 'It achieves this by ~splitting the model~ across devices.';
      final tokens = SummaryLexer.tokenize(input);
      expect(tokens.length, 3);
      expect(tokens[0], const SummaryToken.plain('It achieves this by '));
      expect(tokens[1], const SummaryToken.wavyUnderline('splitting the model'));
      expect(tokens[2], const SummaryToken.plain(' across devices.'));
    });

    test('parses editorial italics *text*', () {
      const input = 'Used for *fast decoding* in browsers.';
      final tokens = SummaryLexer.tokenize(input);
      expect(tokens.length, 3);
      expect(tokens[0], const SummaryToken.plain('Used for '));
      expect(tokens[1], const SummaryToken.italic('fast decoding'));
      expect(tokens[2], const SummaryToken.plain(' in browsers.'));
    });

    test('parses inline 3D icons [icon:runner]', () {
      const input = 'Super fast [icon:runner] and instant [icon:lightning] compute.';
      final tokens = SummaryLexer.tokenize(input);
      expect(tokens.length, 5);
      expect(tokens[0], const SummaryToken.plain('Super fast '));
      expect(tokens[1], const SummaryToken.icon3d('runner'));
      expect(tokens[2], const SummaryToken.plain(' and instant '));
      expect(tokens[3], const SummaryToken.icon3d('lightning'));
      expect(tokens[4], const SummaryToken.plain(' compute.'));
    });

    test('parses smart action links', () {
      const input = 'Check out [Swarm LLM](github:Swarm+LLM) at [Tartine SF](maps:Tartine+SF) and [WebGPU](tip:Browser+API).';
      final tokens = SummaryLexer.tokenize(input);
      expect(tokens.length, 7);

      expect(tokens[0], const SummaryToken.plain('Check out '));
      expect(tokens[1].type, SummaryTokenType.smartLink);
      expect(tokens[1].text, 'Swarm LLM');
      expect(tokens[1].actionScheme, 'github');
      expect(tokens[1].actionPayload, 'Swarm+LLM');

      expect(tokens[2], const SummaryToken.plain(' at '));
      expect(tokens[3].type, SummaryTokenType.smartLink);
      expect(tokens[3].text, 'Tartine SF');
      expect(tokens[3].actionScheme, 'maps');
      expect(tokens[3].actionPayload, 'Tartine+SF');

      expect(tokens[4], const SummaryToken.plain(' and '));
      expect(tokens[5].type, SummaryTokenType.smartLink);
      expect(tokens[5].text, 'WebGPU');
      expect(tokens[5].actionScheme, 'tip');
      expect(tokens[5].actionPayload, 'Browser+API');
    });

    test('strips all markup for database & search indexing', () {
      const input = 'Swarm LLM enables ==running 27B models== [icon:rocket] by ~splitting the model~ [icon:lightning] for *fast decoding* at [Tartine SF](maps:Tartine+SF).';
      final stripped = SummaryLexer.stripMarkup(input);
      expect(stripped, 'Swarm LLM enables running 27B models by splitting the model for fast decoding at Tartine SF.');
    });
  });
}
