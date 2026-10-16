import 'package:flutter/material.dart';

/// GitHub Linguist official language color mappings and metric formatters.
class GitHubLanguageColors {
  static const Map<String, Color> _colors = {
    'typescript': Color(0xFF3178C6),
    'javascript': Color(0xFFF1E05A),
    'python': Color(0xFF3572A5),
    'rust': Color(0xFFDEA584),
    'go': Color(0xFF00ADD8),
    'dart': Color(0xFF00B4AB),
    'c++': Color(0xFFF34B7D),
    'c': Color(0xFF555555),
    'c#': Color(0xFF178600),
    'java': Color(0xFFB07219),
    'kotlin': Color(0xFFA97BFF),
    'swift': Color(0xFFF05138),
    'ruby': Color(0xFF701516),
    'php': Color(0xFF4F5D95),
    'html': Color(0xFFE34C26),
    'css': Color(0xFF563D7C),
    'shell': Color(0xFF89E051),
    'vue': Color(0xFF41B883),
    'svelte': Color(0xFFFF3E00),
    'lua': Color(0xFF000080),
    'scala': Color(0xFFC22D40),
    'zig': Color(0xFFEC915C),
    'elixir': Color(0xFF6E4A7E),
    'haskell': Color(0xFF5E5086),
  };

  /// Resolves the official GitHub language color or returns a neutral fallback.
  static Color resolve(String? language) {
    if (language == null || language.trim().isEmpty) {
      return const Color(0xFF8B949E);
    }
    final key = language.trim().toLowerCase();
    return _colors[key] ?? const Color(0xFF8B949E);
  }

  /// Formats raw counts (e.g. 133982 -> "134k", 15700 -> "15.7k").
  static String formatCount(dynamic value) {
    if (value == null) return '0';
    final int? count = int.tryParse(value.toString());
    if (count == null) return value.toString();

    if (count >= 1000000) {
      final millions = count / 1000000.0;
      return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}M';
    } else if (count >= 1000) {
      final thousands = count / 1000.0;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
    }
    return count.toString();
  }

  /// Formats ISO timestamps to relative recency (e.g. "Updated 2d ago", "Updated 3w ago").
  static String formatRelativeTime(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.trim().isEmpty) return '';
    final dt = DateTime.tryParse(isoTimestamp);
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays >= 365) {
      return 'Updated ${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays >= 30) {
      return 'Updated ${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays >= 7) {
      return 'Updated ${(diff.inDays / 7).floor()}w ago';
    } else if (diff.inDays >= 1) {
      return 'Updated ${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return 'Updated ${diff.inHours}h ago';
    } else {
      return 'Updated recently';
    }
  }
}
