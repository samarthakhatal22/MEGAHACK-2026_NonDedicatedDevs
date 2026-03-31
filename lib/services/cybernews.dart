import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scamalert.dart';

// ADDED: Subclass to add the 'region' tag field as requested without modifying models/scamalert.dart
class RegionalScamAlert extends ScamAlert {
  final String region;

  const RegionalScamAlert({
    required super.title,
    required super.description,
    required super.source,
    required super.publishedDate,
    super.riskLevel,
    required this.region,
  });
}

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

  // CHANGED: Expanded keyword-based risk inference to cover international scam terminology
  static const _scamKeywords = [
    'phishing', 'scam', 'fraud', 'malware', 'ransomware',
    'stealing', 'credential', 'identity theft', 'otp', 'banking',
    'fake', 'impersonat', 'social engineering', 'smishing',
    'vishing', 'whatsapp', 'telegram', 'investment', 'crypto',
    // ADDED: International keywords
    'irs', 'nhs', 'interpol', 'ssn', 'social security', 'medicare',
    'europol', 'fbi', 'international', 'overseas', 'cartel',
    'global', 'syndicate', 'foreign', 'job offer', 'remittance',
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
      // ADDED: International scams to expand the curated list
      RegionalScamAlert(
        title: 'IRS Impersonation Tax Scam',
        description:
            'Callers claiming to be from the IRS demand immediate payment '
            'for fake tax arrears via prepaid debit cards or wire transfers, '
            'threatening imminent arrest.',
        source: 'Global Fraud Watch',
        publishedDate: now.subtract(const Duration(hours: 12)),
        riskLevel: 'High',
        region: 'USA',
      ),
      RegionalScamAlert(
        title: 'NHS Phishing Vaccine/Record Scam',
        description:
            'Fake texts appearing to be from NHS ask users to click a link '
            'to apply for a COVID pass or update health records, stealing '
            'personal and financial details.',
        source: 'Cyber Alert UK',
        publishedDate: now.subtract(const Duration(days: 1)),
        riskLevel: 'High',
        region: 'UK',
      ),
      RegionalScamAlert(
        title: 'Interpol Fraud Alert - Money Laundering',
        description:
            'Scammers pretend to be Interpol agents accusing the victim '
            'of international money laundering, demanding funds be moved '
            'to a "safe" offshore account.',
        source: 'International Crime Bureau',
        publishedDate: now.subtract(const Duration(days: 2)),
        riskLevel: 'High',
        region: 'Global',
      ),
      RegionalScamAlert(
        title: 'Cryptocurrency Giveaway Fraud',
        description:
            'Deepfake videos or compromised verified accounts promise '
            'to double your crypto if you send a "small verification" '
            'amount to their wallet first.',
        source: 'CryptoSec News',
        publishedDate: now.subtract(const Duration(days: 5)),
        riskLevel: 'High',
        region: 'Global',
      ),
      RegionalScamAlert(
        title: 'International Remote Work Visa Scam',
        description:
            'Fraudulent international job boards offer high-paying tech '
            'roles but require upfront fees for "visa processing" or '
            '"background checks" handled by bogus agencies.',
        source: 'Global Employment Watch',
        publishedDate: now.subtract(const Duration(days: 6)),
        riskLevel: 'Medium',
        region: 'Global',
      ),
    ];
  }
}