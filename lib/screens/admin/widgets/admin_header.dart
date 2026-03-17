import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_notifications_screen.dart';
import '../admin_profile_screen.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UniClubs',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5)
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome, Admin',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey[400]
              ),
            ),
          ],
        ),

        Row(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('targetRole', isEqualTo: 'admin')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasUnread = false;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  hasUnread = true;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminNotificationsScreen()),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                          Icons.notifications_none_rounded,
                          size: 28,
                          color: Color(0xFF3674B5)
                      ),
                      if (hasUnread)
                        Positioned(
                          top: 0,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(width: 16),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3674B5).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE8F4FD),
                  child: Icon(Icons.person, color: Color(0xFF3674B5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}