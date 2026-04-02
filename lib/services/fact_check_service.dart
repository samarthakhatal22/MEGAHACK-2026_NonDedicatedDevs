import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/fact_result.dart';

// ADDED: Constant map for official social sources organized by category
const Map<String, Map<String, List<String>>> kOfficialSocialSources = {
  "India": {
    "PMO India": ["@PMOIndia", "facebook.com/PMOIndia", "youtube.com/PMOIndia"],
    "Narendra Modi": [
      "@narendramodi",
      "facebook.com/narendramodi",
      "instagram.com/narendramodi",
    ],
    "President of India": [
      "@rashtrapatibhvn",
      "facebook.com/RashtrapatiBhavan",
    ],
    "Ministry of Home Affairs": ["@HMOIndia"],
    "Ministry of Finance": ["@FinMinIndia"],
    "Ministry of External Affairs": ["@MEAIndia"],
    "RBI (Reserve Bank of India)": ["@RBI", "youtube.com/ReserveBankOfIndia"],
    "SEBI": ["@SEBI_India"],
    "Indian Army": ["@adgpi"],
    "Indian Navy": ["@indiannavy"],
    "Indian Air Force": ["@IAF_MCC"],
    "ISRO": ["@isro", "youtube.com/ISRO Official"],
    "CBI India": ["@CBIHeadquarters"],
    "Income Tax India": ["@IncomeTaxIndia"],
    "CERT-In": ["@IndianCERT"],
    "TRAI": ["@TRAI"],
    "Aadhaar (UIDAI)": ["@UIDAI"],
    "Ministry of Health India": ["@MoHFW_INDIA"],
    "Doordarshan": ["@DDNewslive"],
    "PIB India": ["@PIB_India"],
  },
  "USA": {
    "White House": [
      "@WhiteHouse",
      "facebook.com/WhiteHouse",
      "instagram.com/whitehouse",
    ],
    "Donald Trump": ["@realDonaldTrump", "truthsocial.com/realDonaldTrump"],
    "US Department of State": ["@StateDept"],
    "US Department of Defense": ["@DeptofDefense"],
    "FBI": ["@FBI", "facebook.com/FBI"],
    "CIA": ["@CIA"],
    "FTC (Federal Trade Commission)": ["@FTC"],
    "FCC": ["@FCC"],
    "CDC": ["@CDCgov", "facebook.com/CDC"],
    "FDA": ["@US_FDA"],
    "NASA": ["@NASA", "youtube.com/NASA"],
    "US Secret Service": ["@SecretService"],
    "FEMA": ["@fema"],
    "IRS": ["@IRSnews"],
    "US Cybersecurity (CISA)": ["@CISAgov"],
    "US Senate": ["@USSenate"],
    "US House": ["@HouseFloor"],
    "US Supreme Court": ["@SupremeCourt_US"],
  },
  "Russia": {
    "Kremlin (President of Russia)": [
      "@KremlinRussia_E",
      "telegram.me/kremlinrus",
    ],
    "Vladimir Putin": ["vk.com/id0"],
    "Russian MFA": ["@MFA_Russia", "telegram.me/MID_Russia"],
    "Russian Ministry of Defense": ["@mod_russia", "telegram.me/mod_russia"],
    "RT (Russia Today - State Media)": ["@RT_com"],
    "TASS News Agency": ["@tassagency_en"],
    "Roscosmos": ["@roscosmos"],
  },
  "UK": {
    "UK Prime Minister": ["@10DowningStreet"],
    "UK Government": ["@UKGovernment", "facebook.com/ukgovernment"],
    "Foreign Commonwealth Office": ["@FCDOGovUK"],
    "UK Ministry of Defence": ["@DefenceHQ"],
    "GCHQ": ["@GCHQ"],
    "NHS": ["@NHSuk", "facebook.com/NHSuk"],
    "Bank of England": ["@bankofengland"],
    "UK Parliament": ["@UKParliament"],
    "Action Fraud UK": ["@actionfrauduk"],
    "National Cyber Security Centre UK": ["@NCSC"],
  },
  "China": {
    "Ministry of Foreign Affairs China": ["@MFA_China", "WeChat: MFA_China"],
    "Chinese Embassy": ["@ChineseEmbassy"],
    "Xinhua News (State Media)": ["@XHNews"],
    "People's Daily": ["@PDChina"],
    "Global Times": ["@globaltimesnews"],
    "CGTN": ["@CGTNOfficial"],
  },
  "European Union": {
    "European Commission": [
      "@EU_Commission",
      "facebook.com/EuropeanCommission",
    ],
    "European Parliament": ["@Europarl_EN"],
    "European Central Bank": ["@ecb"],
    "Europol": ["@Europol"],
    "EU Cybersecurity Agency (ENISA)": ["@enisa_eu"],
  },
  "France": {
    "Élysée (French President)": ["@Elysee"],
    "Emmanuel Macron": ["@EmmanuelMacron"],
    "French Government": ["@gouvernementFR"],
    "French MFA": ["@francediplo_EN"],
  },
  "Germany": {
    "German Federal Government": ["@Bundeskanzler"],
    "German MFA": ["@GermanyDiplo"],
    "Bundesbank": ["@bundesbank"],
  },
  "Japan": {
    "Prime Minister of Japan": ["@JPN_PMO"],
    "Japanese MFA": ["@MofaJapan_en"],
    "Bank of Japan": ["@Bank_of_Japan_e"],
  },
  "Australia": {
    "Australian Government": ["@ausgov"],
    "Australian PM": ["@AustralianPM"],
    "Australian Federal Police": ["@AFPMedia"],
    "ACCC (Scam Watch)": ["@ACCCScamWatch"],
    "Australian Cyber Security Centre": ["@AuCyber"],
  },
  "Canada": {
    "Government of Canada": ["@CanadaGovNews"],
    "Canadian PM": ["@CanadianPM"],
    "Royal Canadian Mounted Police": ["@rcmpgrcpolice"],
    "Bank of Canada": ["@bankofcanada"],
  },
  "Brazil": {
    "Brazilian Government": ["@govbr"],
    "Lula (President)": ["@LulaOficial"],
    "Brazilian Federal Police": ["@policiafederal"],
  },
  "South Africa": {
    "South African Government": ["@GovernmentZA"],
    "South African Reserve Bank": ["@SAReserveBank"],
  },
  "Saudi Arabia": {
    "Saudi Government": ["@Saudi_Gov"],
    "Saudi MFA": ["@KSAmofaEN"],
    "Saudi Aramco": ["@aramco"],
  },
  "International Organizations": {
    "United Nations": [
      "@UN",
      "facebook.com/unitednations",
      "youtube.com/unitednations",
    ],
    "WHO": ["@WHO", "facebook.com/WHO", "youtube.com/WHO"],
    "World Bank": ["@WorldBank"],
    "IMF": ["@IMFNews"],
    "Interpol": ["@INTERPOL_HQ", "facebook.com/INTERPOL"],
    "NATO": ["@NATO", "facebook.com/NATO"],
    "IAEA": ["@iaeaorg"],
    "UNESCO": ["@UNESCO"],
    "UNICEF": ["@UNICEF"],
    "Amnesty International": ["@amnesty"],
    "ICC (Int'l Criminal Court)": ["@IntlCrimCourt"],
    "ICRC (Red Cross)": ["@ICRC"],
    "WTO": ["@wto"],
    "UNHCR": ["@Refugees"],
    "ITU": ["@ITU"],
  },
};

class FactCheckService {
  final String? _injectedApiKey;
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  FactCheckService({String? apiKey}) : _injectedApiKey = apiKey;

  String get _effectiveApiKey {
    final key = _injectedApiKey != null && _injectedApiKey.isNotEmpty
        ? _injectedApiKey
        : (dotenv.env['GROQ_API_KEY'] ??
              const String.fromEnvironment('GROQ_API_KEY'));
    return key;
  }

  // ADDED: Helper function to flatten the map into a formatted string
  String _buildSourceContext() {
    final buffer = StringBuffer();
    kOfficialSocialSources.forEach((region, entities) {
      buffer.writeln('[$region]');
      entities.forEach((entity, handles) {
        buffer.writeln('- $entity: ${handles.join(", ")}');
      });
    });
    return buffer.toString();
  }

  Future<FactResult> verifyClaim({
    String? text,
    Uint8List? imageBytes,
    String? imageUrl,
  }) async {
    try {
      if ((text == null || text.trim().isEmpty) &&
          imageBytes == null &&
          imageUrl == null) {
        throw ArgumentError('Must provide text, image bytes, or an image URL.');
      }

      final inputText = (text ?? '').trim();
      if (_effectiveApiKey.trim().isEmpty) {
        return _fallbackResult(inputText, reason: 'API key missing');
      }

      // CHANGED: Updated system prompt to include cross-reference instructions and context
      final String systemPrompt =
          '''
You are a civic integrity bot. Find official government notifications from recognized sources to verify this claim or image. 

Cross-reference the following verified official government and institutional social media accounts when assessing credibility: 
${_buildSourceContext()}

Always return your response as a valid JSON object matching exactly this format: 
{
  "accuracy_percentage": 0, 
  "status": "string", 
  "easy_explanation": "string",
  "references": ["https://link1", "https://link2"],
  "social_sources_checked": ["@handle1", "@handle2"],
  "is_ai_generated": boolean,
  "authenticity_reason": "string (why it is or isn't AI generated/manipulated)"
}
IMPORTANT: References MUST be full URLs starting with https://.
Do not include markdown blocks like ```json, just the raw JSON brackets.
''';

      List<Map<String, dynamic>> requestMessages = [];
      if (text != null && text.trim().isNotEmpty) {
        requestMessages.add({'type': 'text', 'text': text});
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestMessages.add({
          'type': 'image_url',
          'image_url': {'url': imageUrl},
        });
      } else if (imageBytes != null) {
        final base64Image = base64Encode(imageBytes);
        requestMessages.add({
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
        });
      }

      debugPrint('==== GROQ API REQUEST DEBUG ====');
      debugPrint('Effective API Key: ${_effectiveApiKey.substring(0, math.min(_effectiveApiKey.length, 10))}...');
      debugPrint('Model: $_model');
      
      final requestBody = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': requestMessages},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.1,
      });
      debugPrint('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_effectiveApiKey',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      debugPrint('==== GROQ API RESPONSE ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        String errorMessage = response.body;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['error']?['message']?.toString() ?? response.body;
        } catch (_) {
          // Keep raw body.
        }

        final lowered = errorMessage.toLowerCase();
        if (response.statusCode == 401 || lowered.contains('invalid api key')) {
          return _fallbackResult(inputText, reason: 'Invalid or missing API key: $errorMessage');
        }

        return _fallbackResult(inputText, reason: 'HTTP ${response.statusCode}: $errorMessage');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final String responseText = data['choices'][0]['message']['content'];
      debugPrint('Parsed Content: $responseText');

      final Map<String, dynamic> jsonMap = jsonDecode(responseText);
      // CHANGED: Extract mentioned handles into a new optional field
      List<String> extractedHandles = [];
      for (var entities in kOfficialSocialSources.values) {
        for (var handles in entities.values) {
          for (final handle in handles) {
            if (responseText.contains(handle) &&
                !extractedHandles.contains(handle)) {
              extractedHandles.add(handle);
            }
          }
        }
      }

      // CHANGED: Returned FactResult with sources
      return FactResult.fromJson(
        jsonMap,
        extractedHandles.isNotEmpty ? extractedHandles : null,
      );
    } catch (e) {
      debugPrint('CRITICAL: FactCheckService Error: $e');
      return _fallbackResult((text ?? '').trim(), reason: e.toString());
    }
  }

  FactResult _fallbackResult(String inputText, {required String reason}) {
    final isHindi = _containsDevanagari(inputText);
    final explanation = isHindi
        ? 'अभी तथ्य जांच सेवा अस्थायी रूप से उपलब्ध नहीं है। कृपया आधिकारिक स्रोत (PIB, भारत सरकार पोर्टल) से पुष्टि करें और थोड़ी देर बाद पुनः प्रयास करें。\n\nकारण: $reason'
        : 'Fact check service is temporarily unavailable. Please verify from official sources (PIB, Government of India portals) and try again shortly.\n\nReason: $reason';

    return FactResult(
      score: 0,
      status: isHindi ? 'सेवा अनुपलब्ध' : 'Service Unavailable',
      simpleDescription: explanation,
      references: const ['https://pib.gov.in', 'https://www.india.gov.in'],
      isAiGenerated: null,
      authenticityReason: isHindi
          ? 'तकनीकी कारण: $reason'
          : 'Technical reason: $reason',
    );
  }

  bool _containsDevanagari(String value) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(value);
  }

  // ADDED: Method to get deeper context and verification details based on history
  Future<String> getDeepAnalysis(
    List<Map<String, dynamic>> conversationHistory,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_effectiveApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': conversationHistory,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'Groq API Error: ${error['error']['message'] ?? response.body}',
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('CRITICAL: FactCheckService getDeepAnalysis Error: $e');
      throw Exception('Failed to get deeper analysis: $e');
    }
  }
}
