import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';

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
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
      },
    );
  }
}

/// Checks if user is already logged in and routes them directly,
/// skipping the welcome and login screens.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _resolveHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return const WelcomeScreen();

      final role = doc.data()?['role'] ?? 'student';
      if (role == 'student') return const StudentDashboard();
    } catch (_) {}

    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF3674B5)),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
