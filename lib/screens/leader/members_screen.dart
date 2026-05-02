import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class MembersScreen extends StatefulWidget {
  final QueryDocumentSnapshot clubDoc;

  const MembersScreen({super.key, required this.clubDoc});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingPending = true;
  bool _isLoadingMembers = true;

  String get clubId => widget.clubDoc.id;
  String get clubName => (widget.clubDoc.data() as Map<String, dynamic>)['name'] ?? 'Club';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingRequests();
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingPending = true);
    final requests = await _firestoreService.getPendingRequests(clubId);
    if (mounted) {
      setState(() {
        _pendingRequests = requests;
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final members = await _firestoreService.getClubMembers(clubId);
    if (mounted) {
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _handleApprove(Map<String, dynamic> request) async {
    final result = await _firestoreService.approveMembership(request['membershipId'], clubId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message']),
      backgroundColor: result['success'] ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

    if (result['success']) {
      setState(() => _pendingRequests.remove(request));
      _loadMembers();

      NotificationService().createLocalNotification(
        userId: request['userId'],
        type: 'membership_approved',
        title: 'Membership Approved!',
        body: 'Your request to join "$clubName" has been approved. Welcome aboard!',
      );
    }
  }

  Future<void> _handleReject(Map<String, dynamic> request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Request', style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
        content: Text('Reject ${request['userName']}\'s membership request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _firestoreService.rejectMembership(request['membershipId']);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message']),
      backgroundColor: result['success'] ? Colors.orange : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

    if (result['success']) setState(() => _pendingRequests.remove(request));
  }

  Future<void> _handleRemoveMember(Map<String, dynamic> member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member', style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
        content: Text('Remove ${member['userName']} from $clubName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _firestoreService.removeMember(member['membershipId'], clubId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message']),
      backgroundColor: result['success'] ? Colors.orange : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

    if (result['success']) setState(() => _members.remove(member));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      // 🚀 نفس ستايل الـ AppBar في صفحة EventPage بالضبط
      appBar: AppBar(
        title: const Text("Members Management", style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3674B5)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3674B5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3674B5),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Requests"),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: "Members (${_members.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildMembersTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    }

    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Pending Requests',
        subtitle: 'New join requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (_, i) => _buildRequestCard(_pendingRequests[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final name = request['userName'] ?? 'Unknown';
    final email = request['userEmail'] ?? '';
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
              ),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF3674B5))),
                if (email.isNotEmpty)
                  Text(email,
                      style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF578FCA).withValues(alpha: 0.7))),
              ],
            ),
          ),
          Row(
            children: [
              // Reject
              IconButton(
                onPressed: () => _handleReject(request),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                ),
              ),
              // Approve
              IconButton(
                onPressed: () => _handleApprove(request),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_isLoadingMembers) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    }

    if (_members.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_outlined,
        title: 'No Members Yet',
        subtitle: 'Approve requests to add members',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (_, i) => _buildMemberCard(_members[i]),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member['userName'] ?? 'Unknown';
    final email = member['userEmail'] ?? '';
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF578FCA), Color(0xFFA1E3F9)],
              ),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF3674B5))),
                if (email.isNotEmpty)
                  Text(email,
                      style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF578FCA).withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Member',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') _handleRemoveMember(member);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Color(0xFF578FCA)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFA1E3F9).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: const Color(0xFF578FCA).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5))),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF578FCA).withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}