import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import '../models/scamalert.dart';
import 'cybernews.dart'; // keeps RapidAPI as fallback

/// Multi-source scam alert aggregator.
///
/// Fetches data from:
///   1. GNews API        (REST / JSON)
///   2. NewsAPI          (REST / JSON)
///   3. CERT-In RSS feed (XML / Atom)
///   4. RapidAPI         (existing [CyberNewsService] — used as fallback)
///
/// Then:
///   • Normalises all results into [ScamAlert] objects.
///   • Filters for scam-relevance with keyword matching.
///   • De-duplicates by title similarity.
///   • Classifies each alert into a human-readable category.
///   • Assigns a confidence score based on cross-source corroboration.
///   • Sorts: highest confidence first, then newest date.
///   • Groups the final list into [ScamAlertGroup] objects for the UI.
class MultiSourceScamService {
  MultiSourceScamService({http.Client? client})
    : _client = client ?? http.Client(),
      _rapidApi = CyberNewsService(client: client);

  final http.Client _client;
  final CyberNewsService _rapidApi; // existing service — untouched

  // ── API keys (replace with your own or pass via --dart-define) ─────────────
  static const String _gNewsApiKey = String.fromEnvironment(
    '406bbe0022aab4361a7c43a057c3f615',
  );
  static const String _newsApiKey = String.fromEnvironment(
    'a27a7d0e03414a98afde995ef1b4c993',
  );

  // ── Scam-relevance keywords ────────────────────────────────────────────────
  static const List<String> _scamKeywords = [
    'scam',
    'fraud',
    'phishing',
    'otp',
    'upi',
    'cybercrime',
    'cyber crime',
    'ransomware',
    'malware',
    'identity theft',
    'smishing',
    'vishing',
    'whatsapp',
    'financial fraud',
    'digital arrest',
    'fake job',
    'investment scam',
    'bank fraud',
    'credit card fraud',
    'sim swap',
    'kyc fraud',
    'aadhaar',
    'impersonat',
    'social engineering',
    'data breach',
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns up to [limit] scam alerts merged from all sources.
  /// Falls back gracefully if individual sources fail.
  Future<List<ScamAlert>> fetchScamAlerts({int limit = 20}) async {
    // Fire all fetchers concurrently for speed.
    final results = await Future.wait([
      _fetchGNews(),
      _fetchNewsApi(),
      _fetchCertInRss(),
      _fetchRapidApi(),
    ]);

    // Flatten all raw alerts into one list.
    final allAlerts = results.expand((list) => list).toList();
    debugPrint("[ScamService] Total alerts fetched: ${allAlerts.length}");

    if (allAlerts.isEmpty) {
      debugPrint(
        '[MultiSourceScamService] No alerts from any source — returning empty list.',
      );
      return [];
    }

    // Pipeline: filter → deduplicate → assign confidence → sort → limit.
    final filtered = _filterScamRelevant(allAlerts);
    final deduped = _deduplicate(filtered);
    final scored = _assignConfidenceScores(deduped, results);
    final sorted = _sort(scored);

    return sorted.take(limit).toList();
  }

  /// Returns alerts grouped by category for the category-sections UI.
  Future<List<ScamAlertGroup>> fetchGroupedAlerts({int limit = 30}) async {
    final alerts = await fetchScamAlerts(limit: limit);
    return _groupByCategory(alerts);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FETCHERS — one per source
  // ══════════════════════════════════════════════════════════════════════════

  /// GNews API: https://gnews.io/docs/
  Future<List<ScamAlert>> _fetchGNews() async {
    if (_gNewsApiKey.isEmpty) {
      debugPrint('[MultiSourceScamService] GNews key not set — skipping.');
      return [];
    }
    try {
      final uri = Uri.https('gnews.io', '/api/v4/search', {
        'q': 'scam OR fraud OR phishing OR cybercrime',
        'lang': 'en',
        'country': 'in',
        'max': '10',
        'token': _gNewsApiKey,
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          '[MultiSourceScamService] API Error: ${response.statusCode}',
        );
        // debugPrint(
        //   '[MultiSourceScamService] GNews HTTP ${response.statusCode}',
        // );
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final articles = (data['articles'] as List?) ?? [];

      return articles.map((a) {
        final map = Map<String, dynamic>.from(a as Map);
        // GNews nests source as { "name": "...", "url": "..." }
        final sourceName =
            (map['source'] as Map?)?['name'] as String? ?? 'GNews';
        return ScamAlert(
          title: map['title'] as String? ?? 'Untitled',
          description: map['description'] as String? ?? '',
          source: 'GNews · $sourceName',
          publishedDate: DateTime.tryParse(map['publishedAt'] as String? ?? ''),
          riskLevel: ScamAlert.inferRisk(
            '${map['title']} ${map['description']}',
          ),
          category: ScamAlert.classifyCategory(
            '${map['title']} ${map['description']}',
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('[MultiSourceScamService] Exception: $e');
      // debugPrint('[MultiSourceScamService] GNews error: $e');
      return [];
    }
  }

  /// NewsAPI: https://newsapi.org/docs/
  Future<List<ScamAlert>> _fetchNewsApi() async {
    if (_newsApiKey.isEmpty) {
      debugPrint('[MultiSourceScamService] NewsAPI key not set — skipping.');
      return [];
    }
    try {
      final uri = Uri.https('newsapi.org', '/v2/everything', {
        'q': 'scam OR fraud OR phishing OR cybercrime India',
        'language': 'en',
        'sortBy': 'publishedAt',
        'pageSize': '10',
        'apiKey': _newsApiKey,
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          '[MultiSourceScamService] API Error: ${response.statusCode}',
        );
        // debugPrint(
        //   '[MultiSourceScamService] NewsAPI HTTP ${response.statusCode}',
        // );
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final articles = (data['articles'] as List?) ?? [];

      return articles.map((a) {
        final map = Map<String, dynamic>.from(a as Map);
        final sourceName =
            (map['source'] as Map?)?['name'] as String? ?? 'NewsAPI';
        final combined = '${map['title']} ${map['description']}';
        return ScamAlert(
          title: map['title'] as String? ?? 'Untitled',
          description: map['description'] as String? ?? '',
          source: 'NewsAPI · $sourceName',
          publishedDate: DateTime.tryParse(map['publishedAt'] as String? ?? ''),
          riskLevel: ScamAlert.inferRisk(combined),
          category: ScamAlert.classifyCategory(combined),
        );
      }).toList();
    } catch (e) {
      debugPrint('[MultiSourceScamService] Exception: $e');
      // debugPrint('[MultiSourceScamService] NewsAPI error: $e');
      return [];
    }
  }

  Future<List<ScamAlert>> _fetchCertInRss() async {
    try {
      const feedUrl = 'https://www.cert-in.org.in/RSS/Advisories.rss';
      final response = await _client
          .get(Uri.parse(feedUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          '[MultiSourceScamService] API Error: ${response.statusCode}',
        );
        // debugPrint(
        //   '[MultiSourceScamService] CERT-In RSS HTTP ${response.statusCode}',
        // );
        return [];
      }

      final feed = RssFeed.parse(response.body);
      final List<ScamAlert> alerts = [];

      for (final item in feed.items ?? <RssItem>[]) {
        final title = item.title?.trim() ?? '';
        final desc = item.description?.trim() ?? 'No description.';
        if (title.isEmpty) continue;

        final combined = '$title $desc';
        alerts.add(
          ScamAlert(
            title: title,
            description: desc,
            source: 'CERT-In',
            publishedDate: item.pubDate,
            riskLevel: ScamAlert.inferRisk(combined),
            category: ScamAlert.classifyCategory(combined),
          ),
        );
      }
      return alerts;
    } catch (e) {
      debugPrint('[MultiSourceScamService] Exception: $e');
      // debugPrint('[MultiSourceScamService] CERT-In RSS error: $e');
      return [];
    }
  }

  /// RapidAPI — delegates to the existing [CyberNewsService].
  /// Always used as a final fallback and additional source.
  Future<List<ScamAlert>> _fetchRapidApi() async {
    try {
      // Add general timeout wrapping if rapid api doesn't handle it
      return await _rapidApi.fetchScamAlerts().timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('[MultiSourceScamService] Exception: $e');
      // debugPrint('[MultiSourceScamService] RapidAPI error: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PIPELINE STEPS
  // ══════════════════════════════════════════════════════════════════════════

  /// Keep only alerts whose title+description contain at least one scam keyword.
  List<ScamAlert> _filterScamRelevant(List<ScamAlert> alerts) {
    return alerts.where((a) {
      final hay = '${a.title} ${a.description}'.toLowerCase();
      return _scamKeywords.any((kw) => hay.contains(kw));
    }).toList();
  }

  /// Remove near-duplicate alerts by using normalized titles.
  List<ScamAlert> _deduplicate(List<ScamAlert> alerts) {
    final Set<String> seenNormTitles = {};
    final List<ScamAlert> unique = [];

    for (final candidate in alerts) {
      // Normalize: lowercase, trim, remove extra spaces
      final normTitle = candidate.title.toLowerCase().trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      if (!seenNormTitles.contains(normTitle)) {
        seenNormTitles.add(normTitle);
        unique.add(candidate);
      }
    }
    return unique;
  }

  /// Assign confidence scores:
  /// - Base score is 1 (Low)
  /// - 2 sources = Medium
  /// - 3+ sources = High
  /// - If CERT-In is a source, boost to High (3)
  List<ScamAlert> _assignConfidenceScores(
    List<ScamAlert> alerts,
    List<List<ScamAlert>> sourceResults,
  ) {
    return alerts.map((alert) {
      int score = 0;
      final normTitle = alert.title.toLowerCase().trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      bool hasCertIn = false;

      for (final sourceList in sourceResults) {
        final foundInSource = sourceList.any((s) {
          final sNormTitle = s.title.toLowerCase().trim().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
          if (sNormTitle == normTitle) {
            if (s.source.contains('CERT-In')) hasCertIn = true;
            return true;
          }
          return false;
        });
        if (foundInSource) score++;
      }

      if (hasCertIn || alert.source.contains('CERT-In')) {
        score = 3; // Boost confidence to High
      } else if (score < 1) {
        score = 1;
      }

      return alert.copyWith(confidenceScore: score.clamp(1, 3));
    }).toList();
  }

  /// Sort: highest confidence first; ties broken by newest date.
  List<ScamAlert> _sort(List<ScamAlert> alerts) {
    alerts.sort((a, b) {
      final cConf = b.confidenceScore.compareTo(a.confidenceScore);
      if (cConf != 0) return cConf;
      final aDate = a.publishedDate ?? DateTime(2000);
      final bDate = b.publishedDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return alerts;
  }

  /// Group a flat list of alerts by [ScamAlert.category].
  List<ScamAlertGroup> _groupByCategory(List<ScamAlert> alerts) {
    // Preserve meaningful category order.
    const order = [
      'UPI Fraud',
      'Phishing',
      'WhatsApp Scam',
      'Investment Scam',
      'Job Scam',
      'Delivery Scam',
      'Other',
    ];

    final Map<String, List<ScamAlert>> map = {};
    for (final alert in alerts) {
      map.putIfAbsent(alert.category, () => []).add(alert);
    }

    return order
        .where((cat) => map.containsKey(cat))
        .map((cat) => ScamAlertGroup(category: cat, alerts: map[cat]!))
        .toList();
  }
}
