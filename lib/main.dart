import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const UniClubsApp());
}

class UniClubsApp extends StatelessWidget {
  const UniClubsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniClubs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/login': (context) => const Placeholder(), // TODO: Create LoginScreen
        '/register': (context) => const Placeholder(), // TODO: Create RegistrationScreen
      },
    );
  }
}
