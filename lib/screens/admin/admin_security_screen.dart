import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  bool _isMfaEnabled = false;
  bool _isLoading = true;
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (doc.exists) {
        setState(() {
          _isMfaEnabled = doc.data()?['mfaEnabled'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleChangePassword() async {
    if (_userEmail == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _userEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Password reset link sent to $_userEmail"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleMFA() async {
    if (_uid == null) return;

    setState(() => _isMfaEnabled = !_isMfaEnabled);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'mfaEnabled': _isMfaEnabled,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMfaEnabled ? "🔐 2FA Enabled" : "🔓 2FA Disabled"),
          backgroundColor: _isMfaEnabled ? Colors.blue : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isMfaEnabled = !_isMfaEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FB),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Security & Access', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSecurityTile(
            Icons.lock_outline_rounded,
            'Change Password',
            'Send reset link to your email',
            onTap: _handleChangePassword,
          ),
          _buildSecurityTile(
            Icons.verified_user_outlined,
            'Two-Factor Authentication',
            _isMfaEnabled ? 'Currently Enabled' : 'Currently Disabled',
            trailing: Switch(
              value: _isMfaEnabled,
              onChanged: (_) => _toggleMFA(),
              activeThumbColor: const Color(0xFF3674B5),
            ),
          ),
          _buildSecurityTile(
              Icons.devices_rounded,
              'Active Sessions',
              'Manage connected devices',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scanning active devices...")));
              }
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: Color(0xFFE8F4FD), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF3674B5), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}