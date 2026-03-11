import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_attendees_screen.dart';
class EventPage extends StatefulWidget {
  final String clubId;
  const EventPage({super.key, required this.clubId});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        title: const Text("Club Events", style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3674B5)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3674B5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3674B5),
          tabs: const [Tab(text: "Upcoming"), Tab(text: "Past")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventStream(isUpcoming: true),
          _buildEventStream(isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildEventStream({required bool isUpcoming}) {
    final now = Timestamp.now();

    // This query filters by the club and the time
    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('clubId', isEqualTo: widget.clubId);

    if (isUpcoming) {
      query = query.where('date', isGreaterThanOrEqualTo: now).orderBy('date', descending: false);
    } else {
      query = query.where('date', isLessThan: now).orderBy('date', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(isUpcoming ? "No upcoming events" : "No past events"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildEventCard(data, docs[index]);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data, DocumentSnapshot doc) {
    final eventDate = (data['date'] as Timestamp?)?.toDate();
    final isPast = eventDate != null && eventDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: isPast
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventAttendeesScreen(
                    eventId: doc.id,
                    eventTitle: data['title'] ?? 'Event',
                    eventDate: eventDate,
                  ),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(data['title'] ?? 'Event Title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3674B5))),
                ),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3674B5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.how_to_reg, size: 13, color: Color(0xFF3674B5)),
                        SizedBox(width: 4),
                        Text('Attendance', style: TextStyle(fontSize: 11, color: Color(0xFF3674B5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(data['date'] != null
                    ? (data['date'] as Timestamp).toDate().toString().split(' ')[0]
                    : 'TBD'),
                const SizedBox(width: 15),
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(data['location'] ?? 'TBD'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}