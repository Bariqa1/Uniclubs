import 'package:flutter/material.dart';
import 'admin_settings_screen.dart';
import 'admin_security_screen.dart';
import 'admin_support_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF3674B5),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'System Admin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 4),
            Text(
              'admin@qu.edu.sa',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            _buildOptionTile(
                icon: Icons.settings_outlined,
                title: 'System Settings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen()))
            ),
            _buildOptionTile(
                icon: Icons.security_outlined,
                title: 'Security & Access',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSecurityScreen()))
            ),
            _buildOptionTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSupportScreen()))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFFE8F4FD), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF3674B5), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}