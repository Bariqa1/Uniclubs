import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPendingRequestsScreen extends StatelessWidget {
  const AdminPendingRequestsScreen({super.key});

  Future<void> _handleRequest(BuildContext context, String notificationId, String senderId, String clubId, bool isApproved, String requestType) async {
    try {
      if (isApproved) {
        var clubDoc = await FirebaseFirestore.instance.collection('clubs').doc(clubId).get();
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();

        if (clubDoc.exists && userDoc.exists) {
          String clubName = clubDoc.data()?['name'] ?? 'Unknown Club';
          String leaderName = userDoc.data()?['name'] ?? 'Unknown Leader';

          await FirebaseFirestore.instance.collection('clubs').doc(clubId).update({
            'leaderId': senderId,
            'leaderName': leaderName,
            'status': 'active',
          });

          await FirebaseFirestore.instance.collection('users').doc(senderId).update({
            'clubId': clubId,
            'clubName': clubName,
          });

          var otherRequests = await FirebaseFirestore.instance
              .collection('notifications')
              .where('relatedId', isEqualTo: clubId)
              .get();

          for (var doc in otherRequests.docs) {
            await doc.reference.delete();
          }
        }
      } else {
        if (requestType == 'new_club_request') {
          await FirebaseFirestore.instance.collection('clubs').doc(clubId).delete();
        }
        await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? "Request Approved Successfully!" : "Request Rejected"),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error processing request"), backgroundColor: Colors.red),
        );
      }
    }
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
        title: const Text('Pending Requests', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('targetRole', isEqualTo: 'admin')
            .where('type', whereIn: ['club_request', 'new_club_request'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final data = req.data() as Map<String, dynamic>;
              final senderId = data['senderId'] ?? '';
              final clubId = data['relatedId'] ?? '';
              final type = data['type'] ?? 'club_request';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: type == 'new_club_request' ? Colors.orange.withValues(alpha: 0.1) : const Color(0xFFE8F4FD),
                          child: Icon(
                              type == 'new_club_request' ? Icons.add_business_rounded : Icons.person_add_alt_1_rounded,
                              color: type == 'new_club_request' ? Colors.orange : const Color(0xFF3674B5)
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? 'Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                              const SizedBox(height: 4),
                              Text(data['message'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleRequest(context, req.id, senderId, clubId, false, type),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Decline", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleRequest(context, req.id, senderId, clubId, true, type),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3674B5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("All caught up!", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text("No pending leadership requests.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}