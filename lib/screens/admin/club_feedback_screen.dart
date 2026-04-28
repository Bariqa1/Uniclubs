import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClubFeedbackScreen extends StatefulWidget {
  final String clubName;

  const ClubFeedbackScreen({super.key, required this.clubName});

  @override
  State<ClubFeedbackScreen> createState() => _ClubFeedbackScreenState();
}

class _ClubFeedbackScreenState extends State<ClubFeedbackScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text('${widget.clubName} Feedback',
            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Get all events and all feedback to perform a "Join" locally
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, eventSnapshot) {
          if (!eventSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Step 1: Find all event IDs that belong to this club
          final clubEventIds = eventSnapshot.data!.docs
              .where((doc) => (doc['clubName'] ?? '') == widget.clubName)
              .map((doc) => doc.id)
              .toSet();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
            builder: (context, feedbackSnapshot) {
              if (!feedbackSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Step 2: Filter feedback based on the event IDs we found or the title
              final docs = feedbackSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fEventId = data['eventId'] ?? '';
                final fEventTitle = (data['eventTitle'] ?? '').toString().toLowerCase();

                // Match by ID bridge OR text fallback
                return clubEventIds.contains(fEventId) ||
                    fEventTitle.contains(widget.clubName.toLowerCase());
              }).toList();

              if (docs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildFeedbackCard(data);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> data) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['userName'] ?? 'Student',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
              _sentimentBadge(data['sentimentLabel'] ?? 'Neutral'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              data['comment'] ?? data['text'] ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)
          ),
          const Divider(height: 24, color: Color(0xFFF4F8FB)),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Event: ${data['eventTitle'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sentimentBadge(String label) {
    Color color = Colors.orange;
    if (label.toLowerCase().contains('positive')) color = Colors.green;
    if (label.toLowerCase().contains('negative')) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text("No feedback yet for ${widget.clubName}", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}