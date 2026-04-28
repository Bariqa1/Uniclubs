import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_service.dart';

class ClubLeaderDashboard extends StatefulWidget {
  final String? activeClubId;
  const ClubLeaderDashboard({super.key, required this.activeClubId});

  @override
  State<ClubLeaderDashboard> createState() => _ClubLeaderDashboardState();
}

class _ClubLeaderDashboardState extends State<ClubLeaderDashboard> {
  String? _selectedEventId; 
  double? _prediction;
  bool _isPredicting = false;
  String? _lastPredictedId;

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error logging out"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchPrediction(DocumentSnapshot event, int memberCount) async {
    if (_isPredicting || _lastPredictedId == event.id) return;

    setState(() {
      _isPredicting = true;
      _lastPredictedId = event.id;
    });

    final data = event.data() as Map<String, dynamic>;
    final tags = (data['tags'] as List? ?? []);
    final capacity = (data['capacity'] as num? ?? 50).toInt();
    final category = data['category'] ?? 'general';

    final categoryMap = {
      'arts':     {'category_Arts': 1},
      'academic': {'category_Education': 1},
      'sports':   {'category_Sports': 1},
      'tech':     {'category_Technology': 1},
      'social':   {'category_Community': 1},
    };

    final features = <String, dynamic>{
      "capacity": capacity,
      "tags_count": tags.length,
      "interested_users_count": memberCount,
      "past_avg_attendance": (capacity * 0.6).roundToDouble(),
      "interest_ratio": memberCount > 0 ? (capacity / memberCount).clamp(0.0, 1.0) : 0.5,
      "category_Arts": 0, "category_Business": 0, "category_Community": 0, "category_Education": 0,
      "category_Health": 0, "category_Medical": 0, "category_Science": 0, "category_Sports": 0,
      "category_Technology": 0, ...?categoryMap[category],
    };

    try {
      final result = await AiService.predictAttendance(features);
      if (mounted) {
        setState(() {
          _prediction = result;
          _isPredicting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPredicting = false;
          _prediction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (widget.activeClubId == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F7FB),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                ),
              ],
            ),
            body: const SafeArea(child: Center(child: Text("No club assigned to manage."))),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('clubs').doc(widget.activeClubId!).snapshots(),
          builder: (context, clubSnapshot) {
            bool isClubActive = true;
            if (clubSnapshot.hasData && clubSnapshot.data!.exists) {
              final clubData = clubSnapshot.data!.data() as Map<String, dynamic>?;
              isClubActive = (clubData?['isActive'] ?? true) && 
                             (clubData?['status']?.toString().toLowerCase() == 'active');
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('clubId', isEqualTo: widget.activeClubId)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, eventsSnapshot) {
                if (!eventsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final allEvents = eventsSnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('memberships')
                      .where('clubId', isEqualTo: widget.activeClubId)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, membersSnapshot) {
                    final approvedCount = membersSnapshot.data?.docs.length ?? 0;
                    
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('memberships')
                          .where('clubId', isEqualTo: widget.activeClubId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, pendingSnapshot) {
                        final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
                        return _buildDashboardUI(allEvents, approvedCount, pendingCount, isClubActive);
                      },
                    );
                  },
                );
              },
            );
          }
        );
      },
    );
  }

  Widget _buildDashboardUI(List<DocumentSnapshot> allEvents, int members, int pending, bool isClubActive) {
    if (_selectedEventId == null && allEvents.isNotEmpty) {
      final now = DateTime.now();
      try {
        _selectedEventId = allEvents.where((doc) => (doc['date'] as Timestamp).toDate().isAfter(now)).last.id;
      } catch (_) {
        _selectedEventId = allEvents.first.id;
      }
    }

    DocumentSnapshot? selectedDoc;
    if (_selectedEventId != null) {
      try {
        selectedDoc = allEvents.firstWhere((e) => e.id == _selectedEventId);
      } catch (_) {
        if (allEvents.isNotEmpty) {
          selectedDoc = allEvents.first;
          _selectedEventId = selectedDoc.id;
        }
      }
    }

    if (selectedDoc != null && _lastPredictedId != selectedDoc.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPrediction(selectedDoc!, members);
      });
    }

    final upcomingData = selectedDoc?.data() as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isClubActive)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFE65100), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Club Suspended",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFE65100))),
                        SizedBox(height: 2),
                        Text("Your club is suspended. Contact admin to restore access.",
                          style: TextStyle(fontSize: 11, color: Color(0xFF795548))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout, color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.2,
            children: [
              _buildStatCard("$members", "Total Members"),
              _buildStatCard("${allEvents.length}", "Total events"),
              _buildStatCard("$pending", "Pending Requests"),
              _buildUpcomingCard(upcomingData),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Attendance Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
          const SizedBox(height: 12),
          _buildPredictionSection(allEvents, members),
        ],
      ),
    );
  }

  Widget _buildPredictionSection(List<DocumentSnapshot> allEvents, int memberCount) {
    if (allEvents.isEmpty || _selectedEventId == null) {
      return Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
        child: const Center(child: Text("No events available.", style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFF3F7FB), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedEventId,
                items: allEvents.map((event) {
                  final d = event.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(value: event.id, child: Text(d['title'] ?? 'Untitled', style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() {
                      _selectedEventId = id;
                      _prediction = null; 
                      _lastPredictedId = null; 
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('registrations')
                .where('eventId', isEqualTo: _selectedEventId)
                .where('status', isEqualTo: 'attended')
                .snapshots(),
            builder: (context, snap) {
              final actualAttendanceCount = snap.data?.docs.length ?? 0;
              
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('events').doc(_selectedEventId!).snapshots(),
                builder: (context, eventSnap) {
                  final eventData = eventSnap.data?.data() as Map<String, dynamic>?;
                  final isUpcoming = (eventData?['date'] as Timestamp?)?.toDate().isAfter(DateTime.now()) ?? true;

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Prediction", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _isPredicting
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3674B5)))
                                : Text(_prediction?.toStringAsFixed(0) ?? '--',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF3674B5))),
                            const Text("Members", style: TextStyle(color: Color(0xFF7BA1C7), fontSize: 10)),
                          ],
                        ),
                      ),
                      if (!isUpcoming) ...[
                        Container(height: 50, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Actual", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("$actualAttendanceCount",
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                              const Text("Members", style: TextStyle(color: Color(0xFF7BA1C7), fontSize: 10)),
                            ],
                          ),
                        ),
                      ]
                    ],
                  );
                }
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(event?['title'] ?? "No Event", textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
          const SizedBox(height: 6),
          const Text("Next Event", style: TextStyle(fontSize: 11, color: Color(0xFF7BA1C7), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
