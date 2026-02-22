import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Register new user (always creates as 'student')
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    bool requestClubLeader = false,
  }) async {
    try {
      // 1. Create Firebase Auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create user profile in Firestore (role ALWAYS 'student')
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': 'student', // ALWAYS student on public registration
        'interests': [], // Empty interests initially
        'profileImage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'clubLeaderRequest': requestClubLeader ? 'pending' : null,
      });

      return {
        'success': true,
        'userId': userCredential.user!.uid,
        'message': 'Account created successfully!',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Get user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User profile not found. Please contact support.',
        };
      }

      String role = userDoc.get('role');

      return {
        'success': true,
        'userId': userCredential.user!.uid,
        'role': role,
        'message': 'Login successful!',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent! Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  /// Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}