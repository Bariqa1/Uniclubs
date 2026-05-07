import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(
              color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3674B5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3674B5),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Past Events'),
            Tab(text: 'Upcoming Events'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryStats(),
          _buildCategoryFilter(),
          _buildSearchField(),
          _buildLegend(),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPastEventsList(),
                _buildUpcomingEventsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Summary Stats
  // ─────────────────────────────────────────
  Widget _buildSummaryStats() {
    return StreamBuilder<QuerySnapshot>(
      stream:
      FirebaseFirestore.instance.collection('feedback').snapshots(),
      builder: (context, snapshot) {
        double globalSatisfaction = 0.0;
        int totalFeedback = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          totalFeedback = snapshot.data!.docs.length;
          double totalScore = 0.0;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalScore += (data['sentimentScore'] ?? 0.5);
          }
          globalSatisfaction = (totalScore / totalFeedback) * 100;
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF3674B5), Color(0xFF578FCA)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF3674B5).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('Total Feedback', '$totalFeedback',
                    Icons.comment_rounded),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3)),
                _summaryItem(
                    'Global Satisfaction',
                    '${globalSatisfaction.toInt()}%',
                    Icons.sentiment_very_satisfied_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Metrics Legend
  // ─────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDEECF8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendItem('High Success', '80%+ showed up', Colors.green),
            _legendDivider(),
            _legendItem('Good', '50–80% showed up', Colors.orange),
            _legendDivider(),
            _legendItem('Low Attendance', 'Under 50% showed up', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, String desc, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 2),
        Text(desc,
            style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE))),
      ],
    );
  }

  Widget _legendDivider() =>
      Container(width: 1, height: 28, color: const Color(0xFFDEECF8));

  // ─────────────────────────────────────────
  // Category Filter
  // ─────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        List<String> dynamicCategories = ['All'];
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            dynamicCategories.add(doc['name'].toString());
          }
        }

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dynamicCategories.length,
            itemBuilder: (context, index) {
              String cat = dynamicCategories[index];
              bool isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat[0].toUpperCase() + cat.substring(1)),
                  selected: isSelected,
                  onSelected: (val) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: const Color(0xFF3674B5),
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Search Field
  // ─────────────────────────────────────────
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) =>
            setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon:
          const Icon(Icons.search, color: Color(0xFF3674B5)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Past Events List
  // ─────────────────────────────────────────
  Widget _buildPastEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('date', isLessThan: Timestamp.now())
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final category =
          (data['category'] ?? '').toString().toLowerCase();
          bool matchesSearch = title.contains(_searchQuery);
          bool matchesCategory = _selectedCategory == 'All' ||
              category == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCategory;
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(
              'No past events found', Icons.event_busy_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildPastEventCard(docs[index].id, data);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Upcoming Events List
  // ─────────────────────────────────────────
  Widget _buildUpcomingEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final category =
          (data['category'] ?? '').toString().toLowerCase();
          bool matchesSearch = title.contains(_searchQuery);
          bool matchesCategory = _selectedCategory == 'All' ||
              category == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCategory;
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(
              'No upcoming events found', Icons.event_available_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildUpcomingEventCard(data);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Past Event Card — Predicted + Actual + Diff + Club Name
  // ─────────────────────────────────────────
  Widget _buildPastEventCard(String eventId, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .where('eventId', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snap) {
        final allDocs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
        final registered = allDocs.length;
        final actual = allDocs
            .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'attended')
            .length;
        final predicted = (data['predictedAttendance'] ?? 0).toInt();
        final rate = registered > 0 ? (actual / registered) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Event',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('clubs')
                                    .doc(data['clubId'] ?? '')
                                    .get(),
                                builder: (context, clubSnap) {
                                  String displayClubName = 'General Club';
                                  if (clubSnap.hasData && clubSnap.data!.exists) {
                                    displayClubName = clubSnap.data!['name'] ?? 'General Club';
                                  }
                                  return Text(
                                    displayClubName,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(rate),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _detailStat('Predicted', '$predicted', const Color(0xFF578FCA)),
                  _detailStat('Actual', '$actual', const Color(0xFF2ECC71)),
                  _detailStat('Diff', '${actual - predicted}', (actual - predicted) >= 0 ? Colors.green : Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Attendance Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const Spacer(),
                  Text('${(rate * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(rate > 0.8 ? Colors.green : (rate > 0.5 ? Colors.orange : Colors.red)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Upcoming Event Card — Predicted + Club Name
  // ─────────────────────────────────────────
  Widget _buildUpcomingEventCard(Map<String, dynamic> data) {
    final predicted = (data['predictedAttendance'] ?? 0).toInt();
    final registered = (data['currentRegistrations'] ?? 0).toInt();
    final capacity = (data['capacity'] ?? 0).toInt();
    final Timestamp? ts = data['date'] as Timestamp?;
    final String dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : 'TBD';

    final regRate = capacity > 0 ? (registered / capacity) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
        border: Border.all(color: const Color(0xFF3674B5).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Event',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('clubs')
                                .doc(data['clubId'] ?? '')
                                .get(),
                            builder: (context, clubSnap) {
                              String displayClubName = 'General Club';
                              if (clubSnap.hasData && clubSnap.data!.exists) {
                                displayClubName = clubSnap.data!['name'] ?? 'General Club';
                              }
                              return Text(
                                displayClubName,
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3674B5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dateStr,
                  style: const TextStyle(color: Color(0xFF3674B5), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _detailStat('Predicted', '$predicted', const Color(0xFF578FCA)),
              _detailStat('Registered', '$registered', const Color(0xFF2ECC71)),
              _detailStat('Capacity', '$capacity', Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Registration Fill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const Spacer(),
              Text('${(regRate * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: regRate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(regRate > 0.8 ? Colors.green : (regRate > 0.5 ? Colors.orange : Colors.red)),
            ),
          ),
          if (predicted > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF578FCA)),
                const SizedBox(width: 6),
                Text(
                  'AI predicts ~$predicted attendees for this event',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF578FCA), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────
  Widget _buildStatusBadge(double rate) {
    String text = rate > 0.8
        ? "High Success"
        : (rate > 0.5 ? "Good" : "Low Attendance");
    Color color = rate > 0.8
        ? Colors.green
        : (rate > 0.5 ? Colors.orange : Colors.red);
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
