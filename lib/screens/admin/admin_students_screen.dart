import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 16),
            _buildTopStudentsBanner(),
            const SizedBox(height: 8),
            Expanded(child: _buildStudentsList()),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Students',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          // Total count badge
          FutureBuilder<AggregateQuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .count()
                .get(),
            builder: (context, snap) {
              final count = snap.hasData ? (snap.data!.count ?? 0) : 0;
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3674B5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count students',
                  style: const TextStyle(
                    color: Color(0xFF3674B5),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Top 3 Most Active Students Banner
  // ─────────────────────────────────────────
  Widget _buildTopStudentsBanner() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('registrations')
          .where('status', isEqualTo: 'attended')
          .get(),
      builder: (context, attendSnap) {
        if (!attendSnap.hasData) return const SizedBox.shrink();

        // Count attended events per student
        final Map<String, int> attendCount = {};
        for (var doc in attendSnap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final uid = data['userId'] ?? '';
          if (uid.isEmpty) continue;
          attendCount[uid] = (attendCount[uid] ?? 0) + 1;
        }

        if (attendCount.isEmpty) return const SizedBox.shrink();

        // Top 3
        final sorted = attendCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top3 = sorted.take(3).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3674B5).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Most Active Students',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(top3.length, (i) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(top3[i].key)
                        .get(),
                    builder: (context, userSnap) {
                      final name = userSnap.hasData && userSnap.data!.exists
                          ? (userSnap.data!['name'] ?? 'Student')
                          .toString()
                          .split(' ')
                          .first
                          : '...';
                      final medals = ['🥇', '🥈', '🥉'];
                      return Column(
                        children: [
                          Text(medals[i], style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${top3[i].value} events',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Students List
  // ─────────────────────────────────────────
  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3674B5)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No students found',
                style: TextStyle(color: Colors.grey)),
          );
        }

        final students = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (students.isEmpty) {
          return const Center(
            child:
            Text('No results found', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final doc = students[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildStudentCard(doc.id, data);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Student Card
  // ─────────────────────────────────────────
  Widget _buildStudentCard(String uid, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Unknown';
    final String email = data['email'] ?? '';
    final bool isActive = (data['status'] ?? 'active') != 'suspended';
    final String? profilePic =
    (data['profilePic'] ?? '').toString().isEmpty ? null : data['profilePic'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          )
        ],
        border: isActive
            ? null
            : Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: avatar + name + status toggle ──
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                const Color(0xFF3674B5).withValues(alpha: 0.1),
                backgroundImage:
                profilePic != null ? NetworkImage(profilePic) : null,
                child: profilePic == null
                    ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Color(0xFF3674B5),
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      email,
                      style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Status badge + toggle
              GestureDetector(
                onTap: () => _confirmToggleStatus(uid, isActive, name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Suspended',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Stats Row ──
          FutureBuilder<List<int>>(
            future: _fetchStudentStats(uid),
            builder: (context, snap) {
              final clubCount = snap.data?[0] ?? 0;
              final attendedCount = snap.data?[1] ?? 0;
              return Row(
                children: [
                  _statChip(
                    Icons.groups_rounded,
                    '$clubCount',
                    clubCount == 1 ? 'Club' : 'Clubs',
                    const Color(0xFF578FCA),
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    Icons.event_available_rounded,
                    '$attendedCount',
                    attendedCount == 1 ? 'Event' : 'Events',
                    const Color(0xFF2ECC71),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statChip(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Fetch: clubs joined + events attended
  // ─────────────────────────────────────────
  Future<List<int>> _fetchStudentStats(String uid) async {
    final db = FirebaseFirestore.instance;

    // Clubs: memberships where status = approved
    final membershipsSnap = await db
        .collection('memberships')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .count()
        .get();

    // Events attended
    final attendedSnap = await db
        .collection('registrations')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'attended')
        .count()
        .get();

    return [
      (membershipsSnap.count ?? 0).toInt(),
      (attendedSnap.count ?? 0).toInt(),
    ];
  }

  // ─────────────────────────────────────────
  // Toggle Status Dialog
  // ─────────────────────────────────────────
  void _confirmToggleStatus(String uid, bool isActive, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isActive ? Icons.block_rounded : Icons.check_circle_rounded,
              color: isActive ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(isActive ? 'Suspend Student?' : 'Activate Student?'),
          ],
        ),
        content: Text(
          isActive
              ? 'Are you sure you want to suspend $name? They will not be able to log in.'
              : 'Are you sure you want to reactivate $name?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'status': isActive ? 'suspended' : 'active'});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive
                          ? '$name has been suspended.'
                          : '$name has been reactivated.',
                    ),
                    backgroundColor: isActive ? Colors.red : Colors.green,
                  ),
                );
              }
            },
            child: Text(
              isActive ? 'Suspend' : 'Activate',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}