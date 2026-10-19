/// Strongly-typed domain metadata model for GitHub Repository entities.
class GitHubRepoMetadata {
  final String fullName;
  final String owner;
  final String repoName;
  final String? avatarUrl;
  final int? stars;
  final int? forks;
  final int? watchers;
  final String? openIssues;
  final String language;
  final String license;
  final String? homepage;
  final String defaultBranch;
  final bool isArchived;
  final String? pushedAt;
  final List<String> topics;
  final Map<String, dynamic>? audit;
  final String repoUrl;

  const GitHubRepoMetadata({
    required this.fullName,
    required this.owner,
    required this.repoName,
    this.avatarUrl,
    this.stars,
    this.forks,
    this.watchers,
    this.openIssues,
    this.language = 'Code',
    this.license = 'Open Source',
    this.homepage,
    this.defaultBranch = 'main',
    this.isArchived = false,
    this.pushedAt,
    this.topics = const [],
    this.audit,
    required this.repoUrl,
  });

  /// Factory constructor to safely extract and normalize typed fields from untyped map.
  factory GitHubRepoMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackTitle,
    String? fallbackUrl,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};

    final rawFullName = meta['full_name']?.toString() ?? fallbackTitle ?? 'Untitled Repo';
    final parts = rawFullName.contains('/') ? rawFullName.split('/') : <String>[];
    final owner = meta['owner']?.toString() ?? (parts.isNotEmpty ? parts[0] : '');
    final repoName = meta['repo_name']?.toString() ?? (parts.length > 1 ? parts[1] : rawFullName);

    final avatarUrl = meta['owner_avatar_url']?.toString() ?? meta['avatar_url']?.toString();

    final rawTopics = meta['topics'];
    final List<String> topics = (rawTopics is List)
        ? rawTopics.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    final rawAudit = meta['resolution_audit'];
    final audit = rawAudit is Map<String, dynamic> ? rawAudit : null;

    final repoUrl = fallbackUrl ?? (rawFullName.isNotEmpty ? 'https://github.com/$rawFullName' : '');

    int? parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return GitHubRepoMetadata(
      fullName: rawFullName,
      owner: owner,
      repoName: repoName,
      avatarUrl: avatarUrl,
      stars: parseInt(meta['stars']),
      forks: parseInt(meta['forks']),
      watchers: parseInt(meta['watchers']),
      openIssues: meta['open_issues']?.toString(),
      language: meta['language']?.toString() ?? 'Code',
      license: meta['license']?.toString() ?? 'Open Source',
      homepage: meta['homepage']?.toString(),
      defaultBranch: meta['default_branch']?.toString() ?? 'main',
      isArchived: meta['is_archived'] == true,
      pushedAt: meta['pushed_at']?.toString(),
      topics: topics,
      audit: audit,
      repoUrl: repoUrl,
    );
  }

  /// Compact number formatter (e.g., 1400 -> "1.4k").
  static String formatCount(dynamic count) {
    if (count == null) return '0';
    final num? value = count is num ? count : num.tryParse(count.toString());
    if (value == null) return '0';
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }

  String get starsFormatted => formatCount(stars);
  String get forksFormatted => formatCount(forks);
  String get watchersFormatted => formatCount(watchers);
  String? get ownerAvatarUrl => avatarUrl;
}
