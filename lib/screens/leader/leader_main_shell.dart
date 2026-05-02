import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'club_leader_dashboard.dart';
import 'club_profile_page.dart';
import 'event_page.dart';
import 'members_screen.dart';
import '../auth/login_screen.dart';

class ClubLeaderMainShell extends StatefulWidget {
  const ClubLeaderMainShell({super.key});

  @override
  State<ClubLeaderMainShell> createState() => _ClubLeaderMainShellState();
}

class _ClubLeaderMainShellState extends State<ClubLeaderMainShell> {
  int _selectedIndex = 0;
  String? _selectedClubId;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .where('leaderId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))));
        }

        final myClubs = snapshot.data?.docs ?? [];

        // If the leader has no clubs assigned yet
        if (myClubs.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  tooltip: "Logout",
                ),
              ],
            ),
            body: const ClubLeaderDashboard(activeClubId: null),
          );
        }

        if (_selectedClubId == null) {
          if (myClubs.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedClubId = myClubs.first.id);
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))));
          } else {
            return _buildClubSelectionScreen(myClubs);
          }
        }

        final activeClubDoc = myClubs.cast<QueryDocumentSnapshot?>().firstWhere(
              (doc) => doc?.id == _selectedClubId,
          orElse: () => null,
        );

        if (activeClubDoc == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedClubId = null);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))));
        }

        final List<Widget> pages = [
          ClubLeaderDashboard(activeClubId: _selectedClubId),
          EventPage(clubId: _selectedClubId!),
          MembersScreen(clubDoc: activeClubDoc),
          ClubProfilePage(clubDoc: activeClubDoc, userRole: 'leader'),
        ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFE8F4FD),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Active Club:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(activeClubDoc['name'] ?? 'Club', style: const TextStyle(color: Color(0xFF3674B5), fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              if (myClubs.length > 1)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedClubId = null),
                  icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF3674B5), size: 18),
                  label: const Text("Switch", style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: const Color(0xFF3674B5),
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Stats'),
              BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Events'),
              BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Members'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_rounded), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClubSelectionScreen(List<QueryDocumentSnapshot> clubs) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Select Club to Manage", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: clubs.length,
        itemBuilder: (context, index) {
          final data = clubs[index].data() as Map<String, dynamic>;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedClubId = clubs[index].id;
              _selectedIndex = 0;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFFE8F4FD), shape: BoxShape.circle),
                    child: const Icon(Icons.star_rounded, color: Color(0xFF3674B5), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Club Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text((data['category'] ?? 'General').toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF3674B5)),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}