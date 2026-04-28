import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminClubCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> club;
  final VoidCallback onViewDetails;
  final VoidCallback onToggleStatus;

  const AdminClubCard({
    super.key,
    required this.docId,
    required this.club,
    required this.onViewDetails,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    String name = club['name'] ?? 'Unnamed Club';
    String status = club['status'] ?? 'active';
    String category = club['category'] ?? 'general';
    final String? leaderId = club['leaderId'] as String?;
    final String? storedLeaderName = club['leaderName'] as String?;

    bool isActive = status.toLowerCase() == 'active';
    bool isPending = status.toLowerCase() == 'pending';
    bool isSuspended = status.toLowerCase() == 'suspended';

    Color badgeColor = isActive ? const Color(0xFF2ECC71) : isPending ? const Color(0xFFF39C12) : const Color(0xFFE74C3C);
    String badgeText = isActive ? 'Active' : isPending ? 'Pending Review' : 'Suspended';

    // Resolve leader name: use stored value if valid, otherwise look up from users collection
    final bool needsLookup = (storedLeaderName == null ||
        storedLeaderName.isEmpty ||
        storedLeaderName == 'Unassigned') &&
        leaderId != null &&
        leaderId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 55, height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(16),
                    image: club['imageUrl'] != null ? DecorationImage(image: NetworkImage(club['imageUrl']), fit: BoxFit.cover) : null,
                  ),
                  child: club['imageUrl'] == null ? Center(child: Text(_getCategoryEmoji(category), style: const TextStyle(fontSize: 26))) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), height: 1.3))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                            child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      needsLookup
                          ? FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(leaderId).get(),
                              builder: (_, snap) {
                                final resolvedName = snap.hasData && snap.data!.exists
                                    ? (snap.data!.data() as Map<String, dynamic>)['name'] as String? ?? 'Unknown'
                                    : (snap.connectionState == ConnectionState.waiting ? 'Loading...' : 'Unassigned');
                                return Text('Leader: $resolvedName',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF5B9FD8), fontWeight: FontWeight.w500));
                              },
                            )
                          : Text('Leader: ${storedLeaderName ?? 'Unassigned'}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF5B9FD8), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details', style: TextStyle(color: Color(0xFF5B9FD8), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: onToggleStatus,
                  child: Text(
                    isSuspended ? 'Activate' : 'Suspend',
                    style: TextStyle(color: isSuspended ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'tech': return '💻';
      case 'sports': return '⚽';
      case 'arts': return '🎨';
      case 'academic': return '📚';
      case 'social': return '🎉';
      default: return '🎯';
    }
  }
}
