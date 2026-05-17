import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class SentimentService {
  static String get _baseUrl => AppConstants.apiBaseUrl;

  Future<void> analyzeFeedback(String feedbackId, String text) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final optOut = userDoc.data()?['sentimentOptOut'] == true;
        if (optOut) {
          await FirebaseFirestore.instance.collection('feedback').doc(feedbackId).update({
            'sentimentLabel': 'Neutral',
            'sentimentScore': 0.5,
            'aiStatus': 'AI_DISABLED',
          });
          return;
        }
      }

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
