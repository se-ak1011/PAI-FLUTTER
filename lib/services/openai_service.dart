import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

final openAIServiceProvider = Provider<OpenAIService>((ref) => OpenAIService());

class OpenAIService {
  static final _url = '${Env.supabaseUrl}/functions/v1/openai-proxy';

  /// Generates a structured quote including scope of work and a materials list
  /// based on the job title and description provided by a customer.
  Future<AIQuoteResponse> generateJobQuote({
    required String title,
    String? description,
    String? trade,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw StateError('User must be signed in to generate AI quotes.');
    }

    final prompt = '''
    Act as an expert UK quantity surveyor. Analyze this job:
    Title: $title
    Description: ${description ?? 'No description provided'}
    Trade Category: ${trade ?? 'General'}

    Provide a professional breakdown including:
    1. A concise scope of work (ai_scope).
    2. A technical list of essential materials needed (ai_materials).
    3. Estimated labor time (informative only).

    Return ONLY a JSON object with keys: "ai_scope" (string) and "ai_materials" (array of strings).
    ''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional construction estimation assistant. You return data in valid JSON format.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to generate AI quote: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    final parsedContent = jsonDecode(content) as Map<String, dynamic>;

    return AIQuoteResponse(
      scope: parsedContent['ai_scope'] as String,
      materials: List<String>.from(parsedContent['ai_materials'] ?? []),
    );
  }

  /// General chat completion for arbitrary contractor queries
  Future<String> chat({
    String model = 'gpt-4o-mini',
    required List<Map<String, String>> messages,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw StateError('Not signed in');
    }

    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception('OpenAI error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['choices'] as List).first['message']['content'] as String;
  }
}

class AIQuoteResponse {
  final String scope;
  final List<String> materials;

  AIQuoteResponse({
    required this.scope,
    required this.materials,
  });
}