import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'club_leader_dashboard.dart';
import 'club_profile_page.dart';
import 'event_page.dart';

class ClubLeaderMainShell extends StatefulWidget {
  const ClubLeaderMainShell({super.key});

  @override
  State<ClubLeaderMainShell> createState() => _ClubLeaderMainShellState();
}

class _ClubLeaderMainShellState extends State<ClubLeaderMainShell> {
  int _selectedIndex = 0;
  // Get UID once
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Listening for the club assigned to this leader
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .where('leaderId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(body: Center(child: Text("No club found for this leader")));
        }

        // This is the specific club document for this leader
        final clubDoc = snapshot.data!.docs.first;

        // UPDATED: Pass clubDoc to the Profile Page
        final List<Widget> _pages = [
          ClubLeaderDashboard(clubDoc: clubDoc),
          EventPage(clubId: clubDoc.id),
          ClubProfilePage(clubDoc: clubDoc), // <-- Pass the data here!
        ];

        return Scaffold(
          body: IndexedStack(
              index: _selectedIndex,
              children: _pages
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: const Color(0xFF4A80C0),
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Stats'),
              BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Events'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_rounded), label: 'Club Profile'),
            ],
          ),
        );
      },
    );
  }
}