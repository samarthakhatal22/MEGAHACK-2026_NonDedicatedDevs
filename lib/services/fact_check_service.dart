import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/fact_result.dart';

class FactCheckService {
  final String apiKey;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  FactCheckService({required this.apiKey});

  Future<FactResult> verifyClaim({String? text, Uint8List? imageBytes}) async {
    try {
      if ((text == null || text.trim().isEmpty) && imageBytes == null) {
        throw ArgumentError('Must provide either text or image.');
      }

      // Note: As of now, Groq's llama-3.3-70b-versatile might not support image inputs directly in this specific way.
      // We will focus on text-based verification for this implementation.
      // If imageBytes are provided, we'd ideally use a vision-capable model if available on Groq.
      
      final String systemPrompt = '''
You are a civic integrity bot. Find official Indian government notifications from pib.gov.in or india.gov.in to verify this claim. 
Always return your response as a valid JSON object matching exactly this format: 
{
  "accuracy_percentage": 0, 
  "status": "string", 
  "easy_explanation": "string",
  "references": ["link1", "link2"]
}
Do not include markdown blocks like ```json, just the raw JSON brackets.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text ?? 'Verify the claim in this image (Note: user provided an image).'}
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
      final String content = data['choices'][0]['message']['content'];
      
      final Map<String, dynamic> jsonMap = jsonDecode(content);
      return FactResult.fromJson(jsonMap);

    } catch (e) {
      print('CRITICAL: FactCheckService Error: $e');
      throw Exception('Failed to verify information: $e');
    }
  }
}
