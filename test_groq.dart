import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final String apiKey =
      const String.fromEnvironment('GROQ_API_KEY').isNotEmpty
          ? const String.fromEnvironment('GROQ_API_KEY')
          : (Platform.environment['GROQ_API_KEY'] ?? '').trim();

  if (apiKey.isEmpty) {
    print(
      'ERROR: Set GROQ_API_KEY in your environment before running this test.',
    );
    return;
  }

  print('==== GROQ API TEST ====');
  print('API Key being used: ${apiKey.substring(0, 10)}...');

  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  final body = jsonEncode({
    'model': 'llama-3.3-70b-versatile',
    'messages': [
      {
        'role': 'system',
        'content':
            'You are a testing bot. Reply with exactly {"status": "SUCCESS"} and nothing else as a JSON object.',
      },
      {'role': 'user', 'content': 'Test request'},
    ],
    'response_format': {'type': 'json_object'},
    'temperature': 0.1,
  });

  print('\nSending request to $url...');
  print('Headers: Authorization: Bearer ${apiKey.substring(0, 5)}...');
  print('Body: $body');

  try {
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    print('\n==== GROQ API RESPONSE ====');
    print('Status Code: ${response.statusCode}');
    print('Response Body:\n${response.body}');

    if (response.statusCode == 200) {
      print(
        '\n✅ SUCCESS! Groq API is working perfectly with this key and model.',
      );
    } else {
      print('\n❌ FAILED! Groq API returned an error.');
    }
  } on FormatException catch (e) {
    print('❌ JSON Format Error: $e');
  } catch (e) {
    print('❌ Request Exception: $e');
  }
}
