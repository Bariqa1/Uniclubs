import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // Mark all as read when screen opens
    NotificationService().markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildNotificationsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF578FCA).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF3674B5)),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_userId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3674B5)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildNotificationCard(docs[i].id, data);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(String id, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final String type = data['type'] ?? 'general';
    final String title = data['title'] ?? '';
    final String body = data['body'] ?? '';

    String formattedTime = '';
    final createdAt = data['createdAt'];
    if (createdAt != null) {
      try {
        final dt = (createdAt as dynamic).toDate();
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inMinutes < 60) {
          formattedTime = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          formattedTime = '${diff.inHours}h ago';
        } else {
          formattedTime = DateFormat('MMM d').format(dt);
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => NotificationService().markAsRead(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(16),
          border: isRead
              ? null
              : Border.all(color: const Color(0xFF578FCA).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF578FCA).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _getTypeColor(type).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getTypeEmoji(type),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.bold,
                            color: const Color(0xFF3674B5),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3674B5),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (formattedTime.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFA1E3F9).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 60,
              color: const Color(0xFF578FCA).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF578FCA).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'registration_confirmation': return Colors.green;
      case 'event_cancelled': return Colors.red;
      case 'event_reminder': return Colors.orange;
      case 'feedback_reminder': return Colors.purple;
      case 'membership_approved': return Colors.teal;
      case 'new_club_event': return const Color(0xFF3674B5);
      case 'welcome': return Colors.pink;
      default: return const Color(0xFF578FCA);
    }
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'registration_confirmation': return '✅';
      case 'event_cancelled': return '❌';
      case 'event_reminder': return '⏰';
      case 'feedback_reminder': return '⭐';
      case 'membership_approved': return '🎉';
      case 'new_club_event': return '📢';
      case 'welcome': return '👋';
      default: return '🔔';
    }
  }
}
