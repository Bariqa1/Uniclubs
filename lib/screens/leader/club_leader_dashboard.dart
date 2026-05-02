import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_service.dart';

class ClubLeaderDashboard extends StatefulWidget {
  final String? activeClubId;
  final Function(String)? onClubSelected;
  final List<QueryDocumentSnapshot>? managedClubs;

  const ClubLeaderDashboard({
    super.key,
    required this.activeClubId,
    this.onClubSelected,
    this.managedClubs,
  });

  @override
  State<ClubLeaderDashboard> createState() => _ClubLeaderDashboardState();
}

class _ClubLeaderDashboardState extends State<ClubLeaderDashboard> {
  String? _selectedEventId;
  double? _prediction;
  bool _isPredicting = false;
  String? _lastPredictedId;

  void _sendLeadershipRequest(String clubId, String clubName, String leaderName) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final existing = await FirebaseFirestore.instance
        .collection('notifications')
        .where('senderId', isEqualTo: userId)
        .where('type', isEqualTo: 'club_request')
        .where('relatedId', isEqualTo: clubId)
        .get();

    if (!mounted) return;

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already requested this club!"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Leadership Request',
        'message': '$leaderName wants to lead $clubName',
        'type': 'club_request',
        'targetRole': 'admin',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'relatedId': clubId,
        'senderId': userId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error sending request"), backgroundColor: Colors.red),
      );
    }
  }

  void _showAvailableClubsSheet(String leaderName, String userId) {
    final notificationStream = FirebaseFirestore.instance.collection('notifications')
        .where('senderId', isEqualTo: userId)
        .where('type', isEqualTo: 'club_request')
        .snapshots();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFF3F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Available Clubs", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notificationStream,
                builder: (context, notifySnap) {
                  // معالجة الخطأ إذا كانت الصلاحيات مرفوضة (Permission Denied)
                  if (notifySnap.hasError) {
                    return Center(child: Text("Access Denied: Update Firestore Rules.", style: TextStyle(color: Colors.red[300], fontSize: 12)));
                  }

                  if (notifySnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
                  }

                  final requestedClubIds = notifySnap.data?.docs.map((d) => d['relatedId'] as String).toSet() ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final availableClubs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final lId = data['leaderId'];
                        final status = data['status'];
                        return (lId == null || lId == "" || lId == "Unassigned") && status != 'pending';
                      }).toList();

                      if (availableClubs.isEmpty) return const Center(child: Text("No clubs available."));

                      return ListView.builder(
                        itemCount: availableClubs.length,
                        itemBuilder: (context, index) {
                          final data = availableClubs[index].data() as Map<String, dynamic>;
                          final clubId = availableClubs[index].id;
                          final alreadyRequested = requestedClubIds.contains(clubId);

                          return _buildClubCard(
                            title: data['name'] ?? 'Club',
                            subtitle: data['category'] ?? 'General',
                            buttonText: alreadyRequested ? "Requested" : "Request",
                            icon: Icons.add_moderator_rounded,
                            isDisable: alreadyRequested,
                            onBtnPressed: alreadyRequested ? () {} : () => _sendLeadershipRequest(clubId, data['name'], leaderName),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClubSheet(BuildContext context, String leaderName, String userId) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String category = 'tech';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create a New Club', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 8),
                    const Text('This will be sent to the admin for approval.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Club Name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'tech', child: Text('Technology')),
                        DropdownMenuItem(value: 'sports', child: Text('Sports')),
                        DropdownMenuItem(value: 'arts', child: Text('Arts & Culture')),
                        DropdownMenuItem(value: 'academic', child: Text('Academic')),
                      ],
                      onChanged: (val) => setSheetState(() => category = val!),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isLoading = true);
                            try {
                              DocumentReference clubRef = await FirebaseFirestore.instance.collection('clubs').add({
                                'name': nameCtrl.text.trim(),
                                'leaderName': leaderName,
                                'leaderId': userId,
                                'category': category,
                                'status': 'pending',
                                'memberCount': 0,
                                'createdAt': FieldValue.serverTimestamp(),
                                'description': 'Welcome to our new club! Stay tuned for more updates.',
                                'logo': '',
                              });

                              await FirebaseFirestore.instance.collection('notifications').add({
                                'title': 'New Club Creation Request',
                                'message': '$leaderName wants to create a new club: "${nameCtrl.text.trim()}"',
                                'type': 'new_club_request',
                                'targetRole': 'admin',
                                'isRead': false,
                                'timestamp': FieldValue.serverTimestamp(),
                                'relatedId': clubRef.id,
                                'senderId': userId,
                              });

                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Club request sent to admin!'), backgroundColor: Colors.green)
                                  );
                                }
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
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
        final leaderName = userSnapshot.data?['name'] ?? 'Leader';

        if (widget.activeClubId == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(child: _buildSelectionList(leaderName, userId)),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('clubs').doc(widget.activeClubId!).snapshots(),
            builder: (context, clubSnapshot) {
              bool isClubActive = true;
              String currentStatus = 'active';

              if (clubSnapshot.hasData && clubSnapshot.data!.exists) {
                final clubData = clubSnapshot.data!.data() as Map<String, dynamic>?;
                currentStatus = clubData?['status']?.toString().toLowerCase() ?? 'active';
                isClubActive = currentStatus == 'active';
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
                          return _buildDashboardUI(allEvents, approvedCount, pendingCount, isClubActive, currentStatus, leaderName, userId);
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

  Widget _buildSelectionList(String leaderName, String userId) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("UniClubs Hub", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
              ElevatedButton.icon(
                onPressed: () => _showCreateClubSheet(context, leaderName, userId),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text("New Club", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )
            ],
          ),
          const SizedBox(height: 24),

          if (widget.managedClubs != null && widget.managedClubs!.isNotEmpty) ...[
            const Text("My Managed Clubs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ...widget.managedClubs!.map((club) {
              final data = club.data() as Map<String, dynamic>;
              return _buildClubCard(
                title: data['name'] ?? 'Club',
                subtitle: "Tap to manage this club",
                buttonText: "Switch",
                onBtnPressed: () => widget.onClubSelected!(club.id),
                icon: Icons.admin_panel_settings_rounded,
              );
            }),
            const Divider(height: 40),
          ],

          const Text("Available for Leadership", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notifications')
                  .where('senderId', isEqualTo: userId)
                  .where('type', isEqualTo: 'club_request')
                  .snapshots(),
              builder: (context, notifySnap) {
                if (notifySnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
                }

                final requestedClubIds = notifySnap.data?.docs.map((d) => d['relatedId'] as String).toSet() ?? {};

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final allClubs = snapshot.data!.docs;
                    final availableClubs = allClubs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final leaderId = data['leaderId'];
                      final status = data['status'];
                      return (leaderId == null || leaderId == "" || leaderId == "Unassigned") && status != 'pending';
                    }).toList();

                    if (availableClubs.isEmpty) return const Center(child: Text("No other clubs available to request."));

                    return ListView.builder(
                      itemCount: availableClubs.length,
                      itemBuilder: (context, index) {
                        final club = availableClubs[index];
                        final data = club.data() as Map<String, dynamic>;
                        final clubId = club.id;
                        final alreadyRequested = requestedClubIds.contains(clubId);

                        return _buildClubCard(
                          title: data['name'] ?? 'Club',
                          subtitle: data['category'] ?? 'General',
                          buttonText: alreadyRequested ? "Requested" : "Request",
                          onBtnPressed: alreadyRequested ? () {} : () => _sendLeadershipRequest(clubId, data['name'], leaderName),
                          isDisable: alreadyRequested,
                          icon: Icons.groups_rounded,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard({required String title, required String subtitle, required String buttonText, required VoidCallback onBtnPressed, required IconData icon, bool isDisable = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFFE8F4FD), child: Icon(icon, color: const Color(0xFF3674B5))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isDisable ? null : onBtnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisable ? Colors.grey[300] : const Color(0xFF3674B5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonText, style: TextStyle(color: isDisable ? Colors.grey[600] : Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardUI(List<DocumentSnapshot> allEvents, int members, int pending, bool isClubActive, String currentStatus, String leaderName, String userId) {
    final now = DateTime.now();
    Map<String, dynamic>? nextEventData;
    try {
      final nextDoc = allEvents.where((doc) => (doc['date'] as Timestamp).toDate().isAfter(now)).last;
      nextEventData = nextDoc.data() as Map<String, dynamic>?;
    } catch (_) {
      if (allEvents.isNotEmpty) nextEventData = allEvents.first.data() as Map<String, dynamic>?;
    }

    if (_selectedEventId == null && allEvents.isNotEmpty) {
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isClubActive)
            Container(
              width: double.infinity, margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: currentStatus == 'pending' ? const Color(0xFFFFFDE7) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: currentStatus == 'pending' ? const Color(0xFFFFF176).withValues(alpha: 0.4) : const Color(0xFFFFB74D).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(currentStatus == 'pending' ? Icons.hourglass_empty_rounded : Icons.lock_outline_rounded,
                      color: currentStatus == 'pending' ? const Color(0xFFF57F17) : const Color(0xFFE65100), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentStatus == 'pending' ? "Pending Approval" : "Club Suspended",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: currentStatus == 'pending' ? const Color(0xFFF57F17) : const Color(0xFFE65100))),
                        Text(currentStatus == 'pending' ? "Your club is currently under review." : "Your club is suspended.",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF795548))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Text("Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.2,
            children: [
              _buildStatCard("$members", "Total Members"),
              _buildStatCard("${allEvents.length}", "Total events"),
              _buildStatCard("$pending", "Pending Requests"),
              _buildUpcomingCard(nextEventData),
            ],
          ),

          const SizedBox(height: 32),
          const Text("Attendance Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
          const SizedBox(height: 12),
          _buildPredictionSection(allEvents, members),

          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3674B5).withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF3674B5), size: 20),
                    SizedBox(width: 8),
                    Text("Expand your leadership", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showCreateClubSheet(context, leaderName, userId),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3674B5), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Create New Club", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAvailableClubsSheet(leaderName, userId),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Request Management", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
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
        color: Colors.white, borderRadius: BorderRadius.circular(20),
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
                isExpanded: true, value: _selectedEventId,
                items: allEvents.map((event) {
                  final d = event.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(value: event.id, child: Text(d['title'] ?? 'Untitled', style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() {
                      _selectedEventId = id; _prediction = null; _lastPredictedId = null;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('registrations').where('eventId', isEqualTo: _selectedEventId).where('status', isEqualTo: 'attended').snapshots(),
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
                                  : Text(_prediction?.toStringAsFixed(0) ?? '--', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF3674B5))),
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
                                Text("$actualAttendanceCount", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
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