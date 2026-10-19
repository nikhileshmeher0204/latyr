/// Strongly-typed domain metadata model for Quote entities.
class QuoteMetadata {
  final String quoteText;
  final String? author;
  final String? sourceWork;
  final String? year;
  final String? context;

  const QuoteMetadata({
    required this.quoteText,
    this.author,
    this.sourceWork,
    this.year,
    this.context,
  });

  factory QuoteMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackQuote,
    String? fallbackAuthor,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};

    return QuoteMetadata(
      quoteText: meta['quote']?.toString() ?? meta['text']?.toString() ?? fallbackQuote ?? '',
      author: meta['author']?.toString() ?? fallbackAuthor,
      sourceWork: meta['source_work']?.toString() ?? meta['source']?.toString(),
      year: meta['year']?.toString(),
      context: meta['context']?.toString(),
    );
  }
}
