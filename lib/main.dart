import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/student/student_dashboard.dart'; // Import dashboard

// Firebase initialization and app entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          seedColor: const Color(0xFF3674B5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const StudentDashboard(), // TEMP: Testing dashboard
      // home: const WelcomeScreen(), // Original home
      routes: {
        '/login': (context) => const Placeholder(), // TODO: Create LoginScreen
        '/register': (context) => const Placeholder(), // TODO: Create RegistrationScreen
      },
    );
  }
}
