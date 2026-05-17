import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dash_chat_2/dash_chat_2.dart';
import '../utils/constants.dart';

class AiService {
  static String get baseUrl => AppConstants.apiBaseUrl;

  static Future<String> sendMessage(String message, String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "message": message,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"] ?? "No response from AI";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Send Message Error: $e");
      return "Error connecting to server";
    }
  }

  static Future<List<ChatMessage>> getMessages(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/messages/$userId"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List history = data['history'] ?? [];
        
        final aiUser = ChatUser(id: "0", firstName: "AI Assistant");
        final currentUser = ChatUser(id: userId);

        return history.map((m) {
          return ChatMessage(
            text: m['content'] ?? "",
            user: m['role'] == 'ai' ? aiUser : currentUser,
            createdAt: DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Get Messages Error: $e");
      return [];
    }
  }

  static Future<double> predictAttendance(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/predict-attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return (result['predicted_attendance'] as num).toDouble();
      } else {
        throw Exception("Failed to get prediction");
      }
    } catch (e) {
      debugPrint("Prediction Error: $e");
      return 0.0;
    }
  }
}
