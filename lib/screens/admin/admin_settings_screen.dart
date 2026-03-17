import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailAlertsEnabled = true;

  bool _isLoading = true;
  final _authService = AuthService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadRealSettings();
  }

  Future<void> _loadRealSettings() async {
    try {
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _notificationsEnabled = data['pushNotifications'] ?? true;
          _emailAlertsEnabled = data['emailAlerts'] ?? true;
        }
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFirebaseSetting(String key, bool value) async {
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        key: value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating $key: $e");
    }
  }

  void _clearRealCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Cache cleared successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLogout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
        ),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
        title: const Text(
          'System Settings',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            'Push Notifications',
            _notificationsEnabled,
                (val) {
              setState(() => _notificationsEnabled = val);
              _updateFirebaseSetting('pushNotifications', val);
            },
          ),
          _buildSwitchTile(
            'Email Alerts',
            _emailAlertsEnabled,
                (val) {
              setState(() => _emailAlertsEnabled = val);
              _updateFirebaseSetting('emailAlerts', val);
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('System Data'),
          _buildActionTile(Icons.storage_rounded, 'Clear Cache', 'Images & Data', _clearRealCache),
          const SizedBox(height: 24),

          _buildSectionHeader('Account Actions'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
              onTap: _confirmLogout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF3674B5),
        activeTrackColor: const Color(0xFF3674B5).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String trailingText, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3674B5)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trailingText, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}