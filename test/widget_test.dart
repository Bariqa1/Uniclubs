import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniclubs/screens/welcome_screen.dart';

void main() {
  testWidgets('TC-WIDGET-01: WelcomeScreen renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}