class FactResult {
  final int score;
  final String status;
  final String simpleDescription;
  final List<String> references;
  final bool? isAiGenerated;
  final String? authenticityReason;

  FactResult({
    required this.score,
    required this.status,
    required this.simpleDescription,
    required this.references,
    this.isAiGenerated,
    this.authenticityReason,
  });

  factory FactResult.fromJson(Map<String, dynamic> json) {
    return FactResult(
      score: json['accuracy_percentage'] ?? json['score'] ?? 0,
      status: json['status'] ?? 'Unknown',
      simpleDescription: json['easy_explanation'] ?? json['simpleDescription'] ?? '',
      references: List<String>.from(json['references'] ?? []),
      isAiGenerated: json['is_ai_generated'],
      authenticityReason: json['authenticity_reason'],
    );
  }
}
