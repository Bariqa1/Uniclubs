import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../leader/club_profile_page.dart';

class ClubOverviewPage extends StatelessWidget {
  final DocumentSnapshot clubDoc;
  final String userRole;

  const ClubOverviewPage({super.key, required this.clubDoc, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clubs').doc(clubDoc.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Club not found")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        String name = data['name'] ?? 'Club';
        String leader = data['leaderName'] ?? 'Unassigned';
        String category = data['category'] ?? 'Unknown';
        String status = data['status'] ?? 'active';
        int members = data['memberCount'] ?? 0;
        String bio = data['bio'] ?? 'This club participates in university activities, events, and student engagement programs. You can view posts, announcements, and club updates in the feed section.';

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              "Club Details",
              style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
            actions: [
              if (userRole == 'admin')
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF3674B5), size: 28),
                  onPressed: () => _showAdminEditDialog(context, name, category, bio),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B9FD8).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded, size: 38, color: Color(0xFF3674B5)),
                      ),
                      const SizedBox(height: 14),
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 6),
                      Text(category.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem(Icons.person, leader),
                          _infoItem(Icons.people, "$members Members"),
                          _infoItem(Icons.verified, status.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 10),
                      Text(bio, style: const TextStyle(color: Colors.grey, height: 1.5)),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.dynamic_feed, color: Colors.white),
                    label: const Text("Open Club Feed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ClubProfilePage(clubDoc: clubDoc, userRole: userRole)));
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3674B5)),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
      ],
    );
  }

  void _showAdminEditDialog(BuildContext context, String currentName, String currentCategory, String currentBio) {
    final nameCtrl = TextEditingController(text: currentName);
    final categoryCtrl = TextEditingController(text: currentCategory);
    final bioCtrl = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Club Info', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Club Name')),
              const SizedBox(height: 10),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 10),
              TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Overview / Bio')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clubs').doc(clubDoc.id).update({
                'name': nameCtrl.text.trim(),
                'category': categoryCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}