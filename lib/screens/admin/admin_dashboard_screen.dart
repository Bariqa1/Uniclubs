import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_clubs_screen.dart';
import 'admin_leaders_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_attendance_screen.dart';
import 'widgets/admin_header.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const AdminManagementScreen(),
    const AdminAttendanceScreen(),
    const AdminReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3674B5),
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_rounded), label: 'Management'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_rounded), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_rounded), label: 'Reports'),
        ],
      ),
    );
  }
}

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Management', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFF3674B5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF3674B5),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Clubs'),
              Tab(text: 'Leaders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminClubsScreen(userRole: 'admin'),
            AdminLeadersScreen(),
          ],
        ),
      ),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalClubs = 0;
  int _totalStudents = 0;
  int _activeEvents = 0;
  int _eventsHeld = 0;
  bool _isLoadingStats = true;

  List<Map<String, dynamic>> _aiInsights = [];
  bool _isLoadingInsights = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadAIInsights();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final now = Timestamp.now();
      final clubsSnap = await db.collection('clubs').count().get();
      final studentsSnap = await db.collection('users').where('role', isEqualTo: 'student').count().get();
      final activeEventsSnap = await db.collection('events').where('date', isGreaterThanOrEqualTo: now).count().get();
      final eventsHeldSnap = await db.collection('events').where('date', isLessThan: now).count().get();

      if (mounted) {
        setState(() {
          _totalClubs = (clubsSnap.count ?? 0).toInt();
          _totalStudents = (studentsSnap.count ?? 0).toInt();
          _activeEvents = (activeEventsSnap.count ?? 0).toInt();
          _eventsHeld = (eventsHeldSnap.count ?? 0).toInt();
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadAIInsights() async {
    try {
      final db = FirebaseFirestore.instance;
      final clubsSnap = await db.collection('clubs').get();
      final eventsSnap = await db.collection('events').get();
      final feedbackSnap = await db.collection('feedback').get();

      Map<String, String> clubNames = {for (var d in clubsSnap.docs) d.id: d.data()['name'] ?? 'Club'};
      Map<String, String> eventToClub = {for (var d in eventsSnap.docs) d.id: d.data()['clubId'] ?? ''};
      Map<String, Map<String, dynamic>> clubStats = {};

      for (var doc in eventsSnap.docs) {
        final data = doc.data();
        final clubId = data['clubId'] ?? 'Unknown';
        if (clubId == 'Unknown') continue;

        final actual = (data['actualAttendance'] as num? ?? 0).toDouble();
        final predicted = (data['predictedAttendance'] as num? ?? 1).toDouble();

        clubStats.putIfAbsent(clubId, () => {'attendanceSum': 0.0, 'eventsCount': 0, 'positiveFeedback': 0, 'totalFeedback': 0});
        clubStats[clubId]!['attendanceSum'] += (actual / (predicted > 0 ? predicted : 1));
        clubStats[clubId]!['eventsCount'] += 1;
      }

      for (var doc in feedbackSnap.docs) {
        final data = doc.data();
        final eventId = data['eventId'] ?? '';
        final clubId = eventToClub[eventId] ?? 'Unknown';
        if (clubId == 'Unknown') continue;

        final sentiment = (data['sentimentLabel'] ?? 'neutral').toString().toLowerCase();
        clubStats.putIfAbsent(clubId, () => {'attendanceSum': 0.0, 'eventsCount': 0, 'positiveFeedback': 0, 'totalFeedback': 0});

        clubStats[clubId]!['totalFeedback'] += 1;
        if (sentiment.contains('positive')) clubStats[clubId]!['positiveFeedback'] += 1;
      }

      List<Map<String, dynamic>> finalInsights = [];
      clubStats.forEach((id, stats) {
        if (id == 'Unknown') return;

        double avgAttendance = stats['eventsCount'] > 0 ? (stats['attendanceSum'] / stats['eventsCount']) : 0.0;
        double satisfaction = stats['totalFeedback'] > 0 ? (stats['positiveFeedback'] / stats['totalFeedback']) : 0.0;

        double healthScore = (satisfaction * 0.6) + (avgAttendance.clamp(0.0, 1.0) * 0.4);

        String aiStatus = healthScore >= 0.8 ? 'Excellent' : (healthScore >= 0.5 ? 'Stable' : 'Needs Review');
        Color statusColor = healthScore >= 0.8 ? Colors.green : (healthScore >= 0.5 ? Colors.orange : Colors.red);

        finalInsights.add({
          'id': id, // MODIFICATION 1: Storing the club ID
          'name': clubNames[id] ?? 'Club',
          'healthScore': healthScore,
          'satisfaction': satisfaction,
          'status': aiStatus,
          'color': statusColor,
        });
      });

      finalInsights.sort((a, b) => b['healthScore'].compareTo(a['healthScore']));

      if (mounted) {
        setState(() {
          _aiInsights = finalInsights.take(5).toList();
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF4F8FB)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminHeader(),
              const SizedBox(height: 24),
              _isLoadingStats ? const Center(child: CircularProgressIndicator()) : _buildStatsGrid(),
              const SizedBox(height: 24),
              const Text('Pending Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              _buildUnifiedPendingRequestsStream(),
              const SizedBox(height: 24),
              const Text('AI Insights & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              _buildAIInsightsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5,
      children: [
        _statCard('$_totalClubs', 'Total Clubs', Icons.dashboard_customize_rounded),
        _statCard('$_totalStudents', 'Total Students', Icons.groups_rounded),
        _statCard('$_activeEvents', 'Active Events', Icons.event_available_rounded),
        _statCard('$_eventsHeld', 'Events Held', Icons.event_note_rounded),
      ],
    );
  }

  Widget _statCard(String value, String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFF81B8E8), size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
    );
  }

  Widget _buildUnifiedPendingRequestsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').where('targetRole', isEqualTo: 'admin').where('type', whereIn: ['club_request', 'new_club_request']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final requests = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, i) {
            var data = requests[i].data() as Map<String, dynamic>;
            return _actionCard(requests[i].id, data);
          },
        );
      },
    );
  }

  Widget _actionCard(String notificationId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'] ?? 'Request', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text(data['message'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey))])),
        Row(children: [IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _handleQuickAction(notificationId, data, true)), IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _handleQuickAction(notificationId, data, false))])
      ]),
    );
  }

  Widget _buildAIInsightsCard() {
    if (_isLoadingInsights) return const Center(child: CircularProgressIndicator());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Club Health Score (AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          if (_aiInsights.isEmpty)
            const Text("No sufficient data yet.", style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ..._aiInsights.map((club) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClubFeedbackScreen(
                                clubName: club['name'],
                                clubId: club['id'], // MODIFICATION 2: Passing the clubId to the next screen
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              club['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                      Text(club['status'], style: TextStyle(color: club['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: club['healthScore'],
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(club['color']),
                      minHeight: 6,
                    ),
                  )
                ],
              ),
            )),
        ],
      ),
    );
  }

  Future<void> _handleQuickAction(String notificationId, Map<String, dynamic> data, bool isApproved) async {
    final String senderId = data['senderId'] ?? '';
    final String clubId = data['relatedId'] ?? '';
    final String type = data['type'] ?? '';

    try {
      if (isApproved) {
        var clubDoc = await FirebaseFirestore.instance.collection('clubs').doc(clubId).get();
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();

        if (clubDoc.exists && userDoc.exists) {
          String clubName = clubDoc.data()?['name'] ?? 'Club';
          String leaderName = userDoc.data()?['name'] ?? 'Leader';

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
        if (type == 'new_club_request') {
          await FirebaseFirestore.instance.collection('clubs').doc(clubId).delete();
        }
        await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isApproved ? "Approved!" : "Rejected"), backgroundColor: isApproved ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}

// ==========================================
// MODIFICATION 3: The Smart Club Feedback Screen
// ==========================================
class ClubFeedbackScreen extends StatefulWidget {
  final String clubName;
  final String clubId;

  const ClubFeedbackScreen({super.key, required this.clubName, required this.clubId});

  @override
  State<ClubFeedbackScreen> createState() => _ClubFeedbackScreenState();
}

class _ClubFeedbackScreenState extends State<ClubFeedbackScreen> {

  // This function acts as the "Bridge". It gets the events for the club, then gets the feedback for those events.
  Future<List<Map<String, dynamic>>> _fetchFeedbackReliably() async {
    final db = FirebaseFirestore.instance;
    try {
      // Step 1: Get all events belonging to this specific club using the passed clubId
      final eventsSnap = await db.collection('events').where('clubId', isEqualTo: widget.clubId).get();
      if (eventsSnap.docs.isEmpty) return [];

      final Set<String> eventIds = eventsSnap.docs.map((doc) => doc.id).toSet();

      // Step 2: Get all feedback and filter where eventId is in our list
      final feedbackSnap = await db.collection('feedback').get();
      final matchedFeedback = feedbackSnap.docs.where((doc) {
        final data = doc.data();
        final fEventId = data['eventId'] ?? '';
        return eventIds.contains(fEventId);
      }).map((doc) => doc.data()).toList();

      return matchedFeedback;
    } catch (e) {
      debugPrint("Error fetching feedback: $e");
      return [];
    }
  }

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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFeedbackReliably(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              return _buildFeedbackCard(data);
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
              data['comment'] ?? data['text'] ?? '', // Supporting both 'text' and 'comment' fields
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)
          ),
          const Divider(height: 24, color: Color(0xFFF4F8FB)),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Event: ${data['eventTitle'] ?? data['eventName'] ?? 'Unknown'}',
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