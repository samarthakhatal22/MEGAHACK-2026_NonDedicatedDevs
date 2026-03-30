/// Scam alert data model.
///
/// New fields [category] and [confidenceScore] default to safe values so
/// every existing call-site that only passes the original five fields
/// continues to compile and run without modification.
class ScamAlert {
  final String title;
  final String description;
  final String source;
  final DateTime? publishedDate;

  /// 'High' | 'Medium' | 'Low'  (inferred from content or supplied explicitly)
  final String riskLevel;

  /// Human-readable category: 'UPI Fraud', 'WhatsApp Scam', 'Job Scam',
  /// 'Investment Scam', 'Delivery Scam', 'Phishing', 'Other'
  final String category;

  /// How many independent sources reported this topic.
  /// 1 → Low   2 → Medium   3+ → High
  final int confidenceScore;

  const ScamAlert({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedDate,
    this.riskLevel = 'Medium',
    // ── new optional fields with safe defaults ──────────────────────────────
    this.category = 'Other',
    this.confidenceScore = 1,
  });

  // ── Convenience label for confidence score ────────────────────────────────
  /// Returns 'High' | 'Medium' | 'Low' based on [confidenceScore].
  String get confidenceLevel {
    if (confidenceScore >= 3) return 'High';
    if (confidenceScore == 2) return 'Medium';
    return 'Low';
  }

  // ── Factory: build from raw JSON (RapidAPI / GNews / NewsAPI shapes) ──────
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
    final resolvedDesc =
        description.isEmpty ? 'No description available.' : description;
    final combined = '$resolvedTitle $resolvedDesc';

    return ScamAlert(
      title: resolvedTitle,
      description: resolvedDesc,
      source: source.isEmpty ? 'Cyber Security News' : source,
      publishedDate: DateTime.tryParse(dateText),
      riskLevel: inferRisk(combined),
      category: classifyCategory(combined),
      confidenceScore: 1, // set by the orchestrating service after merging
    );
  }

  /// Returns a copy of this alert with updated fields.
  ScamAlert copyWith({
    String? title,
    String? description,
    String? source,
    DateTime? publishedDate,
    String? riskLevel,
    String? category,
    int? confidenceScore,
  }) {
    return ScamAlert(
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      publishedDate: publishedDate ?? this.publishedDate,
      riskLevel: riskLevel ?? this.riskLevel,
      category: category ?? this.category,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  // ── Risk inference ───────────────────────────────────────────────────────
  static const List<String> _highKeywords = [
    'phishing', 'ransomware', 'malware', 'banking', 'credential',
    'steal', 'stolen', 'fraud', 'breach', 'hack', 'zero-day',
    'bitcoin', 'crypto', 'extortion', 'identity theft',
  ];

  static const List<String> _lowKeywords = [
    'awareness', 'guide', 'tips', 'how to', 'best practice',
    'advisory', 'update available',
  ];

  /// Infers a risk level string ('High' | 'Medium' | 'Low') from free text.
  /// Public so other service files can reuse the logic.
  static String inferRisk(String text) {
    final lower = text.toLowerCase();
    for (final kw in _highKeywords) {
      if (lower.contains(kw)) return 'High';
    }
    for (final kw in _lowKeywords) {
      if (lower.contains(kw)) return 'Low';
    }
    return 'Medium';
  }

  // ── Category classification ───────────────────────────────────────────────
  /// Classifies a piece of text into a scam category.
  /// Exposed as a public static so the multi-source service can reuse it.
  static String classifyCategory(String text) {
    final lower = text.toLowerCase();

    if (_containsAny(lower, [
      'upi', 'gpay', 'phonepe', 'paytm', 'bhim', 'neft', 'rtgs',
      'bank transfer', 'qr code', 'payment', 'transaction',
    ])) { return 'UPI Fraud'; }

    if (_containsAny(lower, [
      'whatsapp', 'telegram', 'facebook', 'instagram', 'social media',
      'message', 'forward', 'viral',
    ])) { return 'WhatsApp Scam'; }

    if (_containsAny(lower, [
      'job', 'work from home', 'part-time', 'part time', 'hiring',
      'recruitment', 'vacancy', 'salary', 'internship', 'freelance',
    ])) { return 'Job Scam'; }

    if (_containsAny(lower, [
      'invest', 'stock', 'trading', 'forex', 'crypto', 'bitcoin',
      'returns', 'profit', 'ponzi', 'scheme', 'mutual fund',
    ])) { return 'Investment Scam'; }

    if (_containsAny(lower, [
      'delivery', 'courier', 'fedex', 'bluedart', 'dtdc', 'amazon',
      'flipkart', 'parcel', 'package', 'customs',
    ])) { return 'Delivery Scam'; }

    if (_containsAny(lower, [
      'phishing', 'otp', 'aadhaar', 'pan card', 'kyc', 'sim swap',
      'email', 'password', 'link', 'url', 'login',
    ])) { return 'Phishing'; }

    return 'Other';
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  // ── JSON helper utilities ─────────────────────────────────────────────────
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

// ── Grouped model (optional, used by the category-sections UI) ───────────────
class ScamAlertGroup {
  final String category;
  final List<ScamAlert> alerts;

  const ScamAlertGroup({required this.category, required this.alerts});
}
