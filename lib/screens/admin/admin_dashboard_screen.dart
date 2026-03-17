import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_clubs_screen.dart';
import 'admin_leaders_screen.dart';
import 'admin_reports_screen.dart';
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
    const AdminClubsScreen(userRole: 'admin'),
    const AdminLeadersScreen(),
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
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Clubs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Leaders'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_rounded), label: 'Reports'),
        ],
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

  double _positivePct = 0;
  double _neutralPct = 0;
  double _negativePct = 0;
  bool _isLoadingSentiment = true;

  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadSentimentData();
    _loadAttendanceData();
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
          _totalClubs = clubsSnap.count ?? 0;
          _totalStudents = studentsSnap.count ?? 0;
          _activeEvents = activeEventsSnap.count ?? 0;
          _eventsHeld = eventsHeldSnap.count ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadSentimentData() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('feedback').get();
      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _isLoadingSentiment = false);
        return;
      }

      int pos = 0, neu = 0, neg = 0;

      // حلقة واحدة فقط للمرور على البيانات
      for (var doc in snap.docs) {
        String sentiment = doc.data()['sentimentLabel'] ?? 'neutral';
        if (sentiment.toLowerCase() == 'positive') {
          pos++;
        } else if (sentiment.toLowerCase() == 'negative') {
          neg++;
        } else {
          neu++;
        }
      }

      int total = pos + neu + neg;
      if (mounted && total > 0) {
        setState(() {
          _positivePct = (pos / total) * 100;
          _neutralPct = (neu / total) * 100;
          _negativePct = (neg / total) * 100;
          _isLoadingSentiment = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingSentiment = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSentiment = false);
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('events').where('actualAttendance', isGreaterThan: 0).limit(3).get();
      List<Map<String, dynamic>> temp = [];
      for (var doc in snap.docs) {
        var data = doc.data();
        temp.add({
          'title': data['title'] ?? 'Event',
          'predicted': (data['predictedAttendance'] ?? 0).toDouble(),
          'actual': (data['actualAttendance'] ?? 0).toDouble(),
        });
      }
      if (mounted) {
        setState(() {
          _attendanceData = temp;
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
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
              _isLoadingStats ? const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))) : _buildStatsGrid(),
              const SizedBox(height: 24),
              const Text('AI Insights & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              _buildSentimentCard(),
              const SizedBox(height: 16),
              _buildAttendancePredictionCard(),
              const SizedBox(height: 24),
              const Text('Pending Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              _buildUnifiedPendingRequestsStream(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF81B8E8), size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSentimentCard() {
    if (_isLoadingSentiment) return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    if (_positivePct == 0 && _neutralPct == 0 && _negativePct == 0) {
      return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text("No feedback data available yet.", style: TextStyle(color: Colors.grey))));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Event Sentiment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('See Details', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: [
                  if (_positivePct > 0) PieChartSectionData(value: _positivePct, color: const Color(0xFF2ECC71), title: '', radius: 25),
                  if (_neutralPct > 0) PieChartSectionData(value: _neutralPct, color: const Color(0xFFBDC3C7), title: '', radius: 25),
                  if (_negativePct > 0) PieChartSectionData(value: _negativePct, color: const Color(0xFFE74C3C), title: '', radius: 25),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sentimentLegend(const Color(0xFF2ECC71), 'Positive\n${_positivePct.toInt()}%'),
              _sentimentLegend(const Color(0xFFBDC3C7), 'Neutral\n${_neutralPct.toInt()}%'),
              _sentimentLegend(const Color(0xFFE74C3C), 'Negative\n${_negativePct.toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sentimentLegend(Color color, String text) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), const SizedBox(width: 6), Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.3))]);
  }

  Widget _buildAttendancePredictionCard() {
    if (_isLoadingAttendance) return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    if (_attendanceData.isEmpty) {
      return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text("No attendance data to predict yet.", style: TextStyle(color: Colors.grey))));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Prediction Accuracy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 150,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= _attendanceData.length) return const SizedBox.shrink();
                        String title = _attendanceData[index]['title'].toString();
                        List<String> words = title.split(' ');
                        String shortTitle = words.length > 1 ? '${words[0]}\n${words[1]}' : words[0];
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(shortTitle, style: TextStyle(fontSize: 9, color: Colors.grey[600]), textAlign: TextAlign.center));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 50, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[500])))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1, dashArray: [4, 4])),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_attendanceData.length, (index) {
                  return _makeBarData(index, _attendanceData[index]['predicted'], _attendanceData[index]['actual']);
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _sentimentLegend(const Color(0xFFA1E3F9), 'Predicted'),
              const SizedBox(width: 20),
              _sentimentLegend(const Color(0xFF2C3E50), 'Actual'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double predicted, double actual) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: predicted, color: const Color(0xFFA1E3F9), width: 14, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: actual, color: const Color(0xFF2C3E50), width: 14, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildUnifiedPendingRequestsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRole', isEqualTo: 'admin')
          .where('type', whereIn: ['club_request', 'new_club_request'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('No pending actions', style: TextStyle(color: Colors.grey))),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            var doc = requests[index];
            var data = doc.data() as Map<String, dynamic>;
            return _actionCard(data['title'] ?? 'Request', data['message'] ?? '', () => _handleQuickAction(doc.id, data, true), () => _handleQuickAction(doc.id, data, false));
          },
        );
      },
    );
  }

  Widget _actionCard(String title, String subtitle, VoidCallback onApprove, VoidCallback onReject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), height: 1.4)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(onTap: onApprove, child: _actionButton(Icons.check, Colors.green)),
              const SizedBox(width: 8),
              InkWell(onTap: onReject, child: _actionButton(Icons.close, Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 16));
  }
}