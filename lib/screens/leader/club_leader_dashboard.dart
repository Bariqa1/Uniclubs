import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClubLeaderDashboard extends StatelessWidget {
  final QueryDocumentSnapshot clubDoc;

  const ClubLeaderDashboard({super.key, required this.clubDoc});

  /// Fetches data using only 'get' and 'count' operations.
  /// No 'set', 'add', or 'update' methods are used.
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final String clubId = clubDoc.id;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Use Future.wait to execute multiple READ queries at once
      final results = await Future.wait([
        // Query 1: Read total members count
        FirebaseFirestore.instance.collection('members').where('clubId', isEqualTo: clubId).count().get(),
        // Query 2: Read active events count
        FirebaseFirestore.instance.collection('events').where('clubId', isEqualTo: clubId).count().get(),
        // Query 3: Read pending join requests count
        FirebaseFirestore.instance.collection('join_requests').where('clubId', isEqualTo: clubId).where('status', isEqualTo: 'pending').count().get(),
        // Query 4: Read only the most recent event document
        FirebaseFirestore.instance.collection('events').where('clubId', isEqualTo: clubId).limit(1).get(),
        // Query 5: Read current user's profile for the name
        if (userId != null) FirebaseFirestore.instance.collection('users').doc(userId).get() else Future.value(null),
      ]);

      final userSnap = results[4] as DocumentSnapshot?;

      return {
        'members': (results[0] as AggregateQuerySnapshot).count ?? 0,
        'events': (results[1] as AggregateQuerySnapshot).count ?? 0,
        'pending': (results[2] as AggregateQuerySnapshot).count ?? 0,
        'upcomingEvent': (results[3] as QuerySnapshot).docs.firstOrNull?.data(),
        'leaderName': userSnap?.exists == true ? (userSnap!.data() as Map<String, dynamic>)['name'] ?? "Leader" : "Leader",
      };
    } catch (e) {
      debugPrint("Firebase Read Error: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB), // Light background to match screenshot
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchDashboardData(),
          builder: (context, snapshot) {
            // Error handling if read permissions are denied
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Data Load Error: ${snapshot.error}", textAlign: TextAlign.center),
              ));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
            }

            final data = snapshot.data!;
            final upcoming = data['upcomingEvent'] as Map<String, dynamic>?;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("UniClubs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
                  Text("Welcome, ${data['leaderName']}", style: const TextStyle(fontSize: 18, color: Color(0xFF7BA1C7))),
                  const SizedBox(height: 30),

                  // The 4 Squares from your design
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard("${data['members']}", "Total Members"),
                      _buildStatCard("${data['events']}", "Active events"),
                      _buildStatCard("${data['pending']}", "Pending Requests"),
                      _buildUpcomingCard(upcoming),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Text("Attendance Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
                  const SizedBox(height: 12),

                  // Placeholder for your graph/overview
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: const Center(child: Text("Overview Data Loading...", style: TextStyle(color: Colors.grey, fontSize: 12))),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF3674B5), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic>? event) {
    String title = event?['title'] ?? "No Event";
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
          const SizedBox(height: 6),
          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF3674B5)),
          const Text("Upcoming Event", style: TextStyle(fontSize: 11, color: Color(0xFF7BA1C7), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}