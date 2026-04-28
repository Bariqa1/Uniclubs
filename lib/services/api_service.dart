import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _base = AppConstants.apiBaseUrl;

  Future<List<Map<String, dynamic>>> getRecommendations(String userId, {int limit = 10}) async {
    try {
      final uri = Uri.parse('$_base/api/recommendations/$userId?limit=$limit');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> eventsJson = data['events'] ?? [];
        return eventsJson.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> invalidateRecommendationCache(String userId) async {
    try {
      final uri = Uri.parse('$_base/api/recommendations/$userId/cache');
      await http.delete(uri).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}