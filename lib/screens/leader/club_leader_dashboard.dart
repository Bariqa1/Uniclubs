import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class ClubLeaderDashboard extends StatefulWidget {
  final String? activeClubId;
  const ClubLeaderDashboard({super.key, required this.activeClubId});

  @override
  State<ClubLeaderDashboard> createState() => _ClubLeaderDashboardState();
}

class _ClubLeaderDashboardState extends State<ClubLeaderDashboard> {
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error logging out"), backgroundColor: Colors.red),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchDashboardData(String clubId, String userId) async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('memberships').where('clubId', isEqualTo: clubId).where('status', isEqualTo: 'approved').count().get(),
        FirebaseFirestore.instance.collection('events').where('clubId', isEqualTo: clubId).count().get(),
        FirebaseFirestore.instance.collection('memberships').where('clubId', isEqualTo: clubId).where('status', isEqualTo: 'pending').count().get(),
        FirebaseFirestore.instance.collection('events').where('clubId', isEqualTo: clubId).where('date', isGreaterThan: Timestamp.now()).orderBy('date').limit(1).get(),
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
      ]);

      final userSnap = results[4] as DocumentSnapshot;

      return {
        'members': (results[0] as AggregateQuerySnapshot).count ?? 0,
        'events': (results[1] as AggregateQuerySnapshot).count ?? 0,
        'pending': (results[2] as AggregateQuerySnapshot).count ?? 0,
        'upcomingEvent': (results[3] as QuerySnapshot).docs.firstOrNull?.data(),
        'leaderName': userSnap.exists ? (userSnap.data() as Map<String, dynamic>)['name'] ?? "Leader" : "Leader",
      };
    } catch (e) {
      rethrow;
    }
  }

  void _sendLeadershipRequest(String clubId, String clubName, String leaderName) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
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
                                'isActive': true,
                                'logo': '',
                                'socialLinks': {
                                  'instagram': '',
                                  'twitter': ''
                                },
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

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Club request sent to admin!'), backgroundColor: Colors.green)
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F7FB),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFFF3F7FB), body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))));
        }

        final leaderName = userSnapshot.data?['name'] ?? 'Leader';

        // 🚀 إذا الـ ID اللي وصلنا فاضي، نعرض شاشة اكتشاف الأندية
        if (widget.activeClubId == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F7FB),
            body: SafeArea(child: _buildSelectionList(leaderName, userId)),
          );
        }

        // 🚀 إذا وصلنا ID، نعرض إحصائيات هذا النادي تحديداً
        return Scaffold(
          backgroundColor: const Color(0xFFF3F7FB),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _fetchDashboardData(widget.activeClubId!, userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));

              final data = snapshot.data!;
              return _buildDashboardUI(data);
            },
          ),
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
              const Text("UniClubs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select a club to lead:", style: TextStyle(fontSize: 14, color: Colors.grey)),
              TextButton.icon(
                onPressed: () => _showCreateClubSheet(context, leaderName, userId),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF3674B5)),
                label: const Text("Create New", style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                if (availableClubs.isEmpty) {
                  return const Center(child: Text("No available clubs at the moment.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: availableClubs.length,
                  itemBuilder: (context, index) {
                    final club = availableClubs[index];
                    final data = club.data() as Map<String, dynamic>;
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
                          const CircleAvatar(backgroundColor: Color(0xFFE8F4FD), child: Icon(Icons.groups, color: Color(0xFF3674B5))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'Club', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                Text(data['category'] ?? 'General', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _sendLeadershipRequest(club.id, data['name'], leaderName),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text("Request", style: TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
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

  Widget _buildDashboardUI(Map<String, dynamic> data) {
    final upcoming = data['upcomingEvent'] as Map<String, dynamic>?;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
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
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
            child: const Center(child: Text("Overview Data Loading...", style: TextStyle(color: Colors.grey, fontSize: 12))),
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
    String title = event?['title'] ?? "No Event";
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
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