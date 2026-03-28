class FactResult {
  final int score;
  final String status;
  final String simpleDescription;
  final List<String> references;
  final bool? isAiGenerated;
  final String? authenticityReason;
  // ADDED: New natively nullable fields (Change 1)
  final List<String>? socialSourcesChecked;
  final String? deepAnalysis;

  FactResult({
    required this.score,
    required this.status,
    required this.simpleDescription,
    required this.references,
    this.isAiGenerated,
    this.authenticityReason,
    this.socialSourcesChecked,
    this.deepAnalysis,
  });

  factory FactResult.fromJson(Map<String, dynamic> json, [List<String>? parsedSources, String? analysis]) {
    List<String>? finalSources = parsedSources;
    if (json.containsKey('socialSourcesChecked') || json.containsKey('social_sources_checked')) {
      final explicit = json['socialSourcesChecked'] ?? json['social_sources_checked'];
      if (explicit is List) {
        finalSources ??= [];
        for (final item in explicit) {
          if (!finalSources.contains(item.toString())) {
            finalSources.add(item.toString());
          }
        }
      }
    }

    return FactResult(
      score: json['accuracy_percentage'] ?? json['score'] ?? 0,
      status: json['status'] ?? 'Unknown',
      simpleDescription: json['easy_explanation'] ?? json['simpleDescription'] ?? '',
      references: List<String>.from(json['references'] ?? []),
      isAiGenerated: json['is_ai_generated'],
      authenticityReason: json['authenticity_reason'],
      socialSourcesChecked: finalSources?.isNotEmpty == true ? finalSources : null,
      deepAnalysis: analysis ?? json['deep_analysis'] ?? json['deepAnalysis'],
    );
  }
}
