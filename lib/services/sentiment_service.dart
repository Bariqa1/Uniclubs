import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SentimentService {
  static const String _baseUrl = kDebugMode
      ? 'http://10.0.2.2:8000/ai'
      : 'https://uniclubs-ai.onrender.com/ai';

  Future<void> analyzeFeedback(String feedbackId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-sentiment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'feedback_id': feedbackId,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Sentiment Analysis Success: ${response.body}");
      } else {
        debugPrint("⚠️ Analysis failed with status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error calling sentiment API: $e");
    }
  }
}