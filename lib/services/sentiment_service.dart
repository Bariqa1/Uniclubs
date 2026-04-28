import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class SentimentService {
  static const String _baseUrl = AppConstants.apiBaseUrl;

  Future<void> analyzeFeedback(String feedbackId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/analyze-sentiment'),
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
