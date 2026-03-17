import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_pending_requests_screen.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  Future<void> _markAllAsRead() async {
    try {
      var unreadDocs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRole', isEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
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
        title: const Text('Notifications',
            style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF3674B5)),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('targetRole', isEqualTo: 'admin')
            .orderBy('timestamp', descending: true) // عشان الأجدد يظهر فوق
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No notifications yet", style: TextStyle(color: Colors.grey))
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String docId = doc.id;
              final bool isUnread = data['isRead'] == false;

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteNotification(docId),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                ),
                child: InkWell(
                  onTap: () async {
                    if (isUnread) {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(docId)
                          .update({'isRead': true});
                    }

                    String? type = data['type'];

                    if (context.mounted) {
                      if (type == 'club_request' || type == 'new_club_request') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminPendingRequestsScreen()),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildIconByType(data['type']),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  data['title'] ?? 'Notification',
                                  style: TextStyle(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                      color: const Color(0xFF1E3A8A)
                                  )
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  data['message'] ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12)
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIconByType(String? type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'club_request':
        icon = Icons.person_add_alt_1_rounded;
        color = const Color(0xFF3674B5);
        break;
      case 'new_club_request':
        icon = Icons.add_business_rounded;
        color = Colors.orange;
        break;
      case 'edit_request':
        icon = Icons.edit_note_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = const Color(0xFF3674B5);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}