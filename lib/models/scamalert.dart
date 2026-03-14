class ScamAlert {
  final String title;
  final String description;
  final String source;
  final DateTime? publishedDate;
  final String riskLevel; // 'High', 'Medium', 'Low'

  const ScamAlert({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedDate,
    this.riskLevel = 'Medium',
  });

  factory ScamAlert.fromJson(Map<String, dynamic> json) {
    final title = _pickString(json, ['title', 'headline', 'name']);
    final description = _pickString(json, [
      'description',
      'summary',
      'content',
      'snippet',
    ]);
    final source = _extractSource(json);
    final dateText = _pickString(json, [
      'publishedAt',
      'published_date',
      'pubDate',
      'date',
      'created_at',
    ]);

    final resolvedTitle = title.isEmpty ? 'Untitled Alert' : title;
    final resolvedDesc  = description.isEmpty ? 'No description available.' : description;

    return ScamAlert(
      title:         resolvedTitle,
      description:   resolvedDesc,
      source:        source.isEmpty ? 'Cyber Security News' : source,
      publishedDate: DateTime.tryParse(dateText),
        riskLevel:     _inferRisk('$resolvedTitle $resolvedDesc'),
    );
  }

  // ── Risk inference from keywords ────────────────────────────────────────
  static const _highKeywords = [
    'phishing', 'ransomware', 'malware', 'banking', 'credential',
    'steal', 'stolen', 'fraud', 'breach', 'hack', 'zero-day',
    'bitcoin', 'crypto', 'extortion', 'identity theft',
  ];

  static const _lowKeywords = [
    'awareness', 'guide', 'tips', 'how to', 'best practice',
    'advisory', 'update available',
  ];

  static String _inferRisk(String text) {
    final lower = text.toLowerCase();
    for (final kw in _highKeywords) {
      if (lower.contains(kw)) return 'High';
    }
    for (final kw in _lowKeywords) {
      if (lower.contains(kw)) return 'Low';
    }
    return 'Medium';
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static String _extractSource(Map<String, dynamic> json) {
    final direct = _pickString(json, ['source', 'source_name', 'publisher']);
    if (direct.isNotEmpty) return direct;

    final sourceObj = json['source'];
    if (sourceObj is Map<String, dynamic>) {
      return _pickString(sourceObj, ['name', 'title', 'id']);
    }
    return '';
  }

  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}