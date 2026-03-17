import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final String _supportEmail = "support@uniclubs.edu.sa";

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How to add a new Club?',
      'answer': 'Go to the "Clubs Oversight" tab, click on "New Club", fill in the details, and assign a leader. If the leader is not in the system yet, use the "Quick Add Leader" option.'
    },
    {
      'question': 'How does the AI sentiment work?',
      'answer': 'Our AI analyzes student feedback and comments on events to determine overall satisfaction. It categorizes responses into Positive, Neutral, or Negative.'
    },
    {
      'question': 'Exporting PDF reports',
      'answer': 'Detailed reports for club attendance and events can be exported from the Statistics dashboard. Look for the "Download Report" icon at the top right.'
    },
  ];

  int? _expandedIndex;

  // 🚀 دالة نسخ الإيميل (بدون مكتبات خارجية)
  void _copyEmailToClipboard() {
    Clipboard.setData(ClipboardData(text: _supportEmail)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text("Email copied: $_supportEmail"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

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
        title: const Text('Help & Support', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Contact Support Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3674B5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF3674B5).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5)
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text('Need Technical Help?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Click below to copy our IT support email.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _copyEmailToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Support Email', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3674B5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Common Questions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
              ),
            ),

            // FAQ Items
            ...List.generate(_faqs.length, (index) => _buildFaqItem(index)),

            const SizedBox(height: 40),
            Text('UniClubs App Version 1.0.0',
                style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final bool isExpanded = _expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(_faqs[index]['question']!,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A), fontSize: 14)
            ),
            trailing: Icon(
                isExpanded ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                color: const Color(0xFF3674B5)
            ),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                _faqs[index]['answer']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}