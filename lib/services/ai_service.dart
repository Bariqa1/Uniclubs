import 'dart:convert';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:http/http.dart' as http;
class AiService {
  static Future<String> sendMessage(String message, String userId) async{
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id" : userId ,
          "message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"];
      } else {
        return "Server error: ${response.statusCode}";
      }
    }catch(e){
      return "Error connecting to server";
    }

  }

  static Future<List<ChatMessage>> getMessages(String userId) async{
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/messages/$userId"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<ChatMessage>.from(data.map((msg) {
        return ChatMessage(
          text: msg["text"],
          user: ChatUser(
            id: msg["userId"],
            firstName: msg["userName"],),
          createdAt: DateTime.parse(msg["createdAt"]),
        );
      }));

    } else {
      throw Exception("Failed to load messages");
    }

  }
}