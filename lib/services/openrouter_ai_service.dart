// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterAIService {
  static const apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

  Future<List<Map<String, dynamic>>> generateTasks(String prompt) async {
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    final body = {
      "model": "meta-llama/llama-3-8b-instruct", // ✅ WORKING MODEL
      "messages": [
        {
          "role": "system",
          "content":
              "You are a task generator. Respond ONLY with valid JSON array. No text.",
        },
        {
          "role": "user",
          "content":
              """
Generate 6 tasks for this goal: $prompt.

Return ONLY JSON array like:
[
  {"title":"...", "description":"...", "category":"School", "priority":"High"},
  ...
]

Category must be only: School, Work, Personal
Priority must be only: High, Medium, Low
""",
        },
      ],
      "temperature": 0.7,
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
        "HTTP-Referer": "http://localhost",
        "X-Title": "Gira Task Manager",
      },
      body: jsonEncode(body),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("OpenRouter Error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    String text = data["choices"][0]["message"]["content"];

    text = text.replaceAll("```json", "").replaceAll("```", "").trim();

    final decoded = jsonDecode(text);

    return List<Map<String, dynamic>>.from(decoded);
  }
}
