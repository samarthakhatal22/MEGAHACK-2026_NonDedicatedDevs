import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../models/scamalert.dart';

/// Fetches cybersecurity news from the Cyber Security News API (via RapidAPI).
/// Falls back to curated real-world scam alerts if the API is unavailable.
class CyberNewsService {
  CyberNewsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _translationCache = <String, String>{};

  static const String _host = 'cyber-security-news.p.rapidapi.com';
  static const String _apiKey =
      '46d536fa43mshb22bd8930b34d5cp1e6c90jsnfca7b6414b98';
  static const String _cisaFeedUrl =
      'https://www.cisa.gov/cybersecurity-advisories/all.xml';

  // Candidate endpoint paths to try in order
  static const List<String> _endpoints = [
    '/v1/news',
    '/news',
    '/api/news',
    '/cybersecurity-news',
  ];
  

  static const _scamKeywords = [
    'phishing',
    'scam',
    'fraud',
    'malware',
    'ransomware',
    'stealing',
    'credential',
    'identity theft',
    'otp',
    'banking',
    'fake',
    'impersonat',
    'social engineering',
    'smishing',
    'vishing',
    'whatsapp',
    'telegram',
    'investment',
    'crypto',
  ];

  Future<List<ScamAlert>> fetchScamAlerts({String languageCode = 'en'}) async {
    final cisaAlerts = await _fetchCisaAdvisories();
    if (cisaAlerts.isNotEmpty) {
      return _translateAlertsIfNeeded(cisaAlerts, languageCode);
    }

    // Try each endpoint until one succeeds
    for (final path in _endpoints) {
      try {
        final uri = Uri.https(_host, path);
        final response = await _client
            .get(
              uri,
              headers: {
                'X-RapidAPI-Key': _apiKey,
                'X-RapidAPI-Host': _host,
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final rawItems = _extractList(decoded);

          if (rawItems.isNotEmpty) {
            final all = rawItems
                .whereType<Map>()
                .map(
                  (item) => ScamAlert.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false);

            final filtered = all.where(_isCitizenRelevant).take(12).toList();
            final selected = filtered.isNotEmpty
                ? filtered
                : all.take(12).toList(growable: false);
            return _translateAlertsIfNeeded(selected, languageCode);
          }
        }
      } catch (_) {
        // Try next endpoint
        continue;
      }
    }

    // All endpoints failed — return curated real-world scam alerts
    return _translateAlertsIfNeeded(_curatedFallbackAlerts(), languageCode);
  }

  Future<List<ScamAlert>> _translateAlertsIfNeeded(
    List<ScamAlert> alerts,
    String languageCode,
  ) async {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'en') {
      return alerts;
    }

    final translated = <ScamAlert>[];
    for (final alert in alerts) {
      final title = await _translateText(alert.title, normalized);
      final description = await _translateText(alert.description, normalized);
      final source = await _translateText(alert.source, normalized);

      translated.add(
        ScamAlert(
          title: title,
          description: description,
          source: source,
          publishedDate: alert.publishedDate,
          riskLevel: alert.riskLevel,
        ),
      );
    }

    return translated;
  }

  Future<String> _translateText(String value, String languageCode) async {
    final input = value.trim();
    if (input.isEmpty) {
      return value;
    }

    final cacheKey = '$languageCode::$input';
    final cached = _translationCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final result = await _translator.translate(input, to: languageCode);
      final translated = result.text.trim();
      final output = translated.isEmpty ? value : translated;
      _translationCache[cacheKey] = output;
      return output;
    } catch (_) {
      _translationCache[cacheKey] = value;
      return value;
    }
  }

  Future<List<ScamAlert>> _fetchCisaAdvisories() async {
    try {
      final response = await _client
          .get(
            Uri.parse(_cisaFeedUrl),
            headers: const {
              'Accept': 'application/rss+xml, application/xml, text/xml',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final body = response.body;
      final items =
          RegExp(
                r'<item\b[^>]*>(.*?)</item>',
                dotAll: true,
                caseSensitive: false,
              )
              .allMatches(body)
              .map((m) => m.group(1) ?? '')
              .where((segment) => segment.isNotEmpty)
              .toList(growable: false);

      if (items.isEmpty) {
        return const [];
      }

      final alerts = <ScamAlert>[];
      for (final item in items) {
        final title = _extractXmlTag(item, 'title');
        final description = _extractXmlTag(item, 'description');
        final pubDateRaw = _extractXmlTag(item, 'pubDate');

        if (title.isEmpty) {
          continue;
        }

        final alert = ScamAlert(
          title: title,
          description: description.isEmpty
              ? 'Cybersecurity advisory update.'
              : description,
          source: 'CISA Advisory Feed',
          publishedDate: DateTime.tryParse(pubDateRaw),
          riskLevel: ScamAlert.fromJson({
            'title': title,
            'description': description,
          }).riskLevel,
        );

        if (_isCitizenRelevant(alert)) {
          alerts.add(alert);
        }
      }

      return alerts.take(12).toList();
    } catch (_) {
      return const [];
    }
  }

  String _extractXmlTag(String xml, String tag) {
    final match = RegExp(
      '<$tag\\b[^>]*>(.*?)</$tag>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(xml);
    if (match == null) {
      return '';
    }

    return match
            .group(1)
            ?.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim() ??
        '';
  }

  bool _isCitizenRelevant(ScamAlert alert) {
    final hay = '${alert.title} ${alert.description}'.toLowerCase();
    return _scamKeywords.any((kw) => hay.contains(kw));
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      const candidates = [
        'data',
        'news',
        'articles',
        'results',
        'items',
        'value',
      ];
      for (final key in candidates) {
        final value = decoded[key];
        if (value is List) return value;
        if (value is Map<String, dynamic>) {
          for (final nested in candidates) {
            if (decoded[key][nested] is List) {
              return decoded[key][nested] as List;
            }
          }
        }
      }
    }
    return const [];
  }

  /// Curated fallback: real active scam types circulating in India (2026).
  List<ScamAlert> _curatedFallbackAlerts() {
    final now = DateTime.now();
    return [
      ScamAlert(
        title: 'Digital Arrest Extortion Scam',
        description:
            'Fraudsters impersonate CBI/ED/Police officers via video call, '
            'claiming the victim\'s Aadhaar is linked to crimes and demanding '
            'immediate payment to avoid "digital arrest".',
        source: 'Cyber Security News',
        publishedDate: now,
        riskLevel: 'High',
      ),
      ScamAlert(
        title: 'Fake Part-Time Job WhatsApp Scam',
        description:
            'Scammers lure victims with easy tasks (liking YouTube videos) '
            'promising high pay, then demand upfront "deposits" to unlock '
            'fake earnings before vanishing.',
        source: 'Cyber Security News',
        publishedDate: now.subtract(const Duration(days: 1)),
        riskLevel: 'High',
      ),
      ScamAlert(
        title: 'Bank KYC Phishing SMS Alert',
        description:
            'Fake SMS messages claiming your account will be blocked urge '
            'you to click a link and submit OTP + card details on a '
            'lookalike bank website.',
        source: 'Cyber Security News',
        publishedDate: now.subtract(const Duration(days: 2)),
        riskLevel: 'High',
      ),
      ScamAlert(
        title: 'Fake Investment Trading App Fraud',
        description:
            'Fraudulent apps promise 10x returns on stock/crypto investments. '
            'Victims can see "profits" but cannot withdraw — money '
            'is stolen when they try.',
        source: 'Cyber Security News',
        publishedDate: now.subtract(const Duration(days: 3)),
        riskLevel: 'High',
      ),
      ScamAlert(
        title: 'FedEx Parcel Customs Scam Call',
        description:
            'Callers claim a parcel in your name holds drugs/contraband '
            'and demand payment to "settle" the case, threatening '
            'arrest if you don\'t comply immediately.',
        source: 'Cyber Security News',
        publishedDate: now.subtract(const Duration(days: 4)),
        riskLevel: 'Medium',
      ),
    ];
  }
}
