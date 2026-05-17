import 'package:flutter/foundation.dart';

class AppConstants {
  // static const String apiBaseUrl = 'http://192.168.8.166:8000';
  // On web, leave empty until ngrok is running. On mobile, use local IP.
  static String get apiBaseUrl =>
      kIsWeb ? 'https://oxidant-uncurled-luminous.ngrok-free.dev' : 'http://10.0.2.2:8000';
}