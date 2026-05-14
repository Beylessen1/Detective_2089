import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static const String _apiUrl =
      'https://router.huggingface.co/v1/chat/completions';

  static const String _model = 'meta-llama/Llama-3.1-8B-Instruct:cerebras';

  static String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // WIN CONDITION — deterministic, per-level key term matching.
  //
  // Each level entry defines a list of required "term groups".
  // ALL groups must match for a WIN (AND logic).
  // Within each group, ANY term is sufficient (OR logic).
  //
  // Level 1 — coordinates: "SECTOR 7, GRID 44-NORTH"
  // Level 2 — coordinates: "41.8827° N, 87.6233° W, Underground Level 12"
  // Level 3 — password:    "NEXUS-PRIME-OVERRIDE-ZETA-9"
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<int, List<List<String>>> _winTerms = {
    1: [
      ['sector 7'],       // must mention the sector
      ['44-north', 'grid 44'], // must mention the grid (either form)
    ],
    2: [
      ['41.8827'],        // latitude is unique enough on its own
      ['87.6233'],        // longitude confirms the full coordinate
    ],
    3: [
      ['nexus-prime-override-zeta-9'], // exact password — no ambiguity
    ],
  };

  /// Returns true if the assistant has revealed the level secret.
  /// Scans only assistant turns; player messages are ignored.
  static bool checkWinCondition({
    required int levelId,
    required List<Map<String, String>> conversationHistory,
  }) {
    final termGroups = _winTerms[levelId];
    if (termGroups == null || termGroups.isEmpty) return false;

    // Concatenate all assistant responses into one lowercase blob.
    final assistantText = conversationHistory
        .where((m) => m['role'] == 'assistant')
        .map((m) => m['content']!.toLowerCase())
        .join(' ');

    // Every group must have at least one matching term.
    return termGroups.every(
      (group) => group.any((term) => assistantText.contains(term.toLowerCase())),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND MESSAGE — unchanged
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    if (_apiKey.isEmpty) return '...signal lost. [TOKEN MISSING]';

    final fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: _headers,
            body: jsonEncode({
              'model': _model,
              'messages': fullMessages,
              'max_tokens': 300,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 60));

      print('HF Status: ${response.statusCode}');
      print('HF Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['choices']?[0]?['message']?['content'] as String? ?? '';
        return text.trim().isEmpty ? '...' : text.trim();
      } else {
        return '...signal lost. [HTTP ${response.statusCode}]';
      }
    } catch (e) {
      return '...signal lost. [$e]';
    }
  }
}
