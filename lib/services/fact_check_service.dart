import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fact_result.dart';

class FactCheckService {
  final String? apiKey;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  FactCheckService({this.apiKey});

  String get _effectiveApiKey => apiKey ?? const String.fromEnvironment('GROQ_API_KEY');

  Future<FactResult> verifyClaim({String? text, Uint8List? imageBytes, String? imageUrl}) async {
    try {
      if ((text == null || text.trim().isEmpty) && imageBytes == null && imageUrl == null) {
        throw ArgumentError('Must provide text, image bytes, or an image URL.');
      }

      final String systemPrompt = '''
You are a civic integrity bot. Find official Indian government notifications from pib.gov.in or india.gov.in to verify this claim or image. 
Always return your response as a valid JSON object matching exactly this format: 
{
  "accuracy_percentage": 0, 
  "status": "string", 
  "easy_explanation": "string",
  "references": ["https://link1", "https://link2"],
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
          'image_url': {'url': imageUrl}
        });
      } else if (imageBytes != null) {
        final base64Image = base64Encode(imageBytes);
        requestMessages.add({
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
        });
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_effectiveApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': requestMessages}
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Groq API Error: ${error['error']['message'] ?? response.body}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final String responseText = data['choices'][0]['message']['content'];
      
      final Map<String, dynamic> jsonMap = jsonDecode(responseText);
      return FactResult.fromJson(jsonMap);

    } catch (e) {
      debugPrint('CRITICAL: FactCheckService Error: $e');
      throw Exception('Failed to verify information: $e');
    }
  }
}
