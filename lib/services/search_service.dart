import 'dart:convert';
import 'package:http/http.dart' as http;

class PolicyResult {
  final String id;
  final String title;
  final String ministry;
  final String date;
  final String excerpt;
  final String status;
  final int pages;

  const PolicyResult({
    required this.id,
    required this.title,
    required this.ministry,
    required this.date,
    required this.excerpt,
    required this.status,
    required this.pages,
  });

  factory PolicyResult.fromJson(Map<String, dynamic> json) {
    return PolicyResult(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      ministry: (json['ministry'] ?? '').toString(),
      date: (json['date'] ?? json['publishedAt'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? json['summary'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      pages: _toInt(json['pages']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class WebResult {
  final String title;
  final String link;
  final String snippet;

  WebResult({required this.title, required this.link, required this.snippet});

  factory WebResult.fromJson(Map<String, dynamic> json) {
    return WebResult(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      snippet: json['snippet'] ?? '',
    );
  }
}

class SearchService {
  static const String apiKey = "AIzaSyC2_c4mDjUGo8ZW8P-7GhJHpJ1oQcoj_4c";
  static const String cx = "55e6560ed443a486a";
  static const String policySearchBaseUrl =
      'https://your-api-endpoint.com/search';

  Future<List<PolicyResult>> searchPolicies({
    String? query,
    String? ministry,
    String? year,
    String? status,
  }) async {
    try {
      final normalizedQuery = (query ?? '').trim();
      if (normalizedQuery.isEmpty) return [];

      final queryParams = <String, String>{'q': normalizedQuery};
      if (ministry != null && ministry.trim().isNotEmpty && ministry != 'All') {
        queryParams['ministry'] = ministry.trim();
      }
      if (status != null && status.trim().isNotEmpty && status != 'All') {
        queryParams['status'] = status.trim();
      }
      if (year != null && year.trim().isNotEmpty && year != 'All') {
        queryParams['year'] = year.trim();
      }

      final url = Uri.parse(
        policySearchBaseUrl,
      ).replace(queryParameters: queryParams);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Support both plain arrays and wrapped payloads from common APIs.
        final List<dynamic> rawItems = switch (decoded) {
          List<dynamic> list => list,
          Map<String, dynamic> map when map['results'] is List<dynamic> =>
            map['results'] as List<dynamic>,
          Map<String, dynamic> map when map['data'] is List<dynamic> =>
            map['data'] as List<dynamic>,
          _ => <dynamic>[],
        };

        final results = rawItems
            .whereType<Map<String, dynamic>>()
            .map(PolicyResult.fromJson)
            .toList();

        return _applyClientFilters(
          results,
          ministry: ministry,
          status: status,
          year: year,
        );
      } else {
        throw Exception("API search failed with status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Search failed: $e");
    }
  }

  List<PolicyResult> _applyClientFilters(
    List<PolicyResult> items, {
    String? ministry,
    String? status,
    String? year,
  }) {
    final normalizedMinistry = _normalizeFilter(ministry);
    final normalizedStatus = _normalizeFilter(status);
    final normalizedYear = _normalizeFilter(year);

    return items.where((item) {
      final ministryMatch = normalizedMinistry == null ||
          item.ministry.toLowerCase() == normalizedMinistry;
      final statusMatch = normalizedStatus == null ||
          item.status.toLowerCase() == normalizedStatus;
      final yearMatch = normalizedYear == null || item.date.contains(normalizedYear);

      return ministryMatch && statusMatch && yearMatch;
    }).toList();
  }

  String? _normalizeFilter(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty || v == 'All') return null;
    return v.toLowerCase();
  }

  Future<List<WebResult>> searchWeb(String query) async {
    try {
      final url = Uri.https(
        'www.googleapis.com',
        '/customsearch/v1',
        {
          'key': apiKey,
          'cx': cx,
          'q': query,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["items"] == null) return [];
        return (data["items"] as List)
            .map((item) => WebResult.fromJson(item))
            .toList();
      } else {
        throw Exception("Google search failed with status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Web search error: $e");
    }
  }
}
