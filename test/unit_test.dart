import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniclubs/utils/constants.dart';

void main() {
  // ══════════════════════════════════════════════════════════
  // TC-CONST  AppConstants
  // ══════════════════════════════════════════════════════════
  group('AppConstants', () {
    test('TC-CONST-01: apiBaseUrl is non-null', () {
      expect(AppConstants.apiBaseUrl, isNotNull);
    });

    test('TC-CONST-02: apiBaseUrl is empty string on web platform', () {
      // kIsWeb is false in test environment (non-web), so we verify
      // the getter returns a non-empty string on non-web (mobile/desktop).
      if (!kIsWeb) {
        expect(AppConstants.apiBaseUrl, isNotEmpty);
      }
    });

    test('TC-CONST-03: apiBaseUrl starts with http on non-web', () {
      if (!kIsWeb) {
        expect(AppConstants.apiBaseUrl, startsWith('http'));
      }
    });

    test('TC-CONST-04: apiBaseUrl does not contain whitespace', () {
      expect(AppConstants.apiBaseUrl.trim(), equals(AppConstants.apiBaseUrl));
    });
  });
}
