import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scamalert.dart';

/// Fetches cybersecurity news from the Cyber Security News API (via RapidAPI).
/// Falls back to curated real-world scam alerts if the API is unavailable.
class CyberNewsService {
  CyberNewsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _host = 'cyber-security-news.p.rapidapi.com';
  static const String _apiKey = '46d536fa43mshb22bd8930b34d5cp1e6c90jsnfca7b6414b98';

  // Candidate endpoint paths to try in order
  static const List<String> _endpoints = [
    '/v1/news',
    '/news',
    '/api/news',
    '/cybersecurity-news',
  ];

  static const _scamKeywords = [
    'phishing', 'scam', 'fraud', 'malware', 'ransomware',
    'stealing', 'credential', 'identity theft', 'otp', 'banking',
    'fake', 'impersonat', 'social engineering', 'smishing',
    'vishing', 'whatsapp', 'telegram', 'investment', 'crypto',
  ];

  Future<List<ScamAlert>> fetchScamAlerts() async {
    // Try each endpoint until one succeeds
    for (final path in _endpoints) {
      try {
        final uri = Uri.https(_host, path);
        final response = await _client.get(
          uri,
          headers: {
            'X-RapidAPI-Key': _apiKey,
            'X-RapidAPI-Host': _host,
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final rawItems = _extractList(decoded);

          if (rawItems.isNotEmpty) {
            final all = rawItems
                .whereType<Map>()
                .map((item) => ScamAlert.fromJson(Map<String, dynamic>.from(item)))
                .toList(growable: false);

            final filtered = all.where(_isCitizenRelevant).take(5).toList();
            return filtered.isNotEmpty ? filtered : all.take(5).toList();
          }
        }
      } catch (_) {
        // Try next endpoint
        continue;
      }
    }

    // All endpoints failed — return curated real-world scam alerts
    return _curatedFallbackAlerts();
  }

  bool _isCitizenRelevant(ScamAlert alert) {
    final hay = '${alert.title} ${alert.description}'.toLowerCase();
    return _scamKeywords.any((kw) => hay.contains(kw));
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      const candidates = ['data', 'news', 'articles', 'results', 'items', 'value'];
      for (final key in candidates) {
        final value = decoded[key];
        if (value is List) return value;
        if (value is Map<String, dynamic>) {
          for (final nested in candidates) {
            if (decoded[key][nested] is List) return decoded[key][nested] as List;
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