import 'package:flutter/material.dart';

class AdminLeaderCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminLeaderCard({
    super.key,
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    List<String> words = name.trim().split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    String name = data['name'] ?? 'Unknown Name';
    String email = data['email'] ?? 'No Email';
    String clubName = data['clubName'] ?? 'No Club Assigned';
    String status = data['status'] ?? 'active';

    bool isActive = status.toLowerCase() == 'active';
    Color badgeColor = isActive ? const Color(0xFF2ECC71) : const Color(0xFFF39C12);
    String badgeText = isActive ? 'Active' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF5B9FD8),
            child: Text(_getInitials(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(clubName, style: const TextStyle(fontSize: 13, color: Color(0xFF5B9FD8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF5B9FD8), size: 20), onPressed: onEdit, padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C), size: 20), onPressed: onDelete, padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}