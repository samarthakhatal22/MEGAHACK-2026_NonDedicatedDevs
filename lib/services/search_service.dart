import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      title: (json['title'] ?? '').toString(),
      link: (json['url'] ?? json['link'] ?? '').toString(),
      snippet: (json['description'] ?? json['snippet'] ?? '').toString(),
    );
  }
}

class SearchService {
  static const String policyApiKeyHeader = String.fromEnvironment(
    'POLICY_API_KEY_HEADER',
    defaultValue: 'X-API-KEY',
  );
  static const String policySearchBaseUrl =
      String.fromEnvironment(
    'POLICY_SEARCH_BASE_URL',
    defaultValue: 'https://your-api-endpoint.com/search',
  );

  String get _effectivePolicyApiKey {
    if (dotenv.env['POLICY_API_KEY'] != null && dotenv.env['POLICY_API_KEY']!.isNotEmpty) return dotenv.env['POLICY_API_KEY']!;
    if (dotenv.env['NEWS_API_KEY'] != null && dotenv.env['NEWS_API_KEY']!.isNotEmpty) return dotenv.env['NEWS_API_KEY']!;
    return '';
  }

  String get _effectiveNewsApiKey {
    if (dotenv.env['NEWS_API_KEY'] != null && dotenv.env['NEWS_API_KEY']!.isNotEmpty) return dotenv.env['NEWS_API_KEY']!;
    return '';
  }

  Future<List<PolicyResult>> searchPolicies({
    String? query,
    String? ministry,
    String? year,
    String? status,
  }) async {
    try {
      final normalizedQuery = (query ?? '').trim();
      if (normalizedQuery.isEmpty) return [];

      if (policySearchBaseUrl.contains('your-api-endpoint.com')) {
        debugPrint(
          'POLICY_SEARCH_BASE_URL is not configured. Falling back to NewsAPI for search results.',
        );
        return _searchPoliciesViaNewsApi(
          normalizedQuery,
          ministry: ministry,
          status: status,
          year: year,
        );
      }

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

      final headers = <String, String>{'Accept': 'application/json'};
      final effectivePolicyApiKey = _effectivePolicyApiKey;
      if (effectivePolicyApiKey.isNotEmpty) {
        headers[policyApiKeyHeader] = effectivePolicyApiKey;
      } else {
        debugPrint(
          'No API key found. Add NEWS_API_KEY to .env file.',
        );
      }

      debugPrint('Policy request URL: $url');
      final response = await http.get(url, headers: headers);
      debugPrint('Policy response status: ${response.statusCode}');
      debugPrint('Policy response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

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
      }

      throw Exception(
        'Policy search failed (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      debugPrint('Search failed: $e');
      rethrow;
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

  Future<List<PolicyResult>> _searchPoliciesViaNewsApi(
    String query, {
    String? ministry,
    String? status,
    String? year,
  }) async {
    final effectiveNewsApiKey = _effectiveNewsApiKey;
    if (effectiveNewsApiKey.isEmpty) {
      throw Exception(
        'Search temporarily unavailable',
      );
    }

    final url = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'sortBy': 'publishedAt',
      'pageSize': '20',
      'language': 'en',
      'apiKey': effectiveNewsApiKey,
    });

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception(
        'NewsAPI fallback failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final articles = data['articles'];
    if (articles is! List) return [];

    final results = articles
        .whereType<Map<String, dynamic>>()
        .map((article) {
          final id = (article['url'] ?? article['title'] ?? '').toString();
          final title = (article['title'] ?? '').toString();
          final source = article['source'];
          final ministry = source is Map<String, dynamic>
              ? (source['name'] ?? 'News').toString()
              : 'News';
          final date = (article['publishedAt'] ?? '').toString();
          final excerpt =
              (article['description'] ?? article['content'] ?? '').toString();

          return PolicyResult(
            id: id,
            title: title,
            ministry: ministry,
            date: date,
            excerpt: excerpt,
            status: 'Active',
            pages: 1,
          );
        })
        .toList();

    return _applyClientFilters(
      results,
      ministry: ministry,
      status: status,
      year: year,
    );
  }

  Future<List<WebResult>> searchNews(String query) async {
    try {
      final effectiveNewsApiKey = _effectiveNewsApiKey;
      if (effectiveNewsApiKey.isEmpty) {
        throw Exception(
          'Search temporarily unavailable',
        );
      }

      final url = Uri.https('newsapi.org', '/v2/everything', {
        'q': query,
        'sortBy': 'publishedAt',
        'pageSize': '10',
        'apiKey': effectiveNewsApiKey,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final articles = data['articles'];
        if (articles is! List) return [];

        return articles
            .whereType<Map<String, dynamic>>()
            .map(WebResult.fromJson)
            .toList();
      }

      throw Exception('News API failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('News search error: $e');
    }
  }
}