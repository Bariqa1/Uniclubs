import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';

class ClubProfilePage extends StatefulWidget {
  final DocumentSnapshot clubDoc;
  final String userRole;

  const ClubProfilePage({super.key, required this.clubDoc, required this.userRole});

  @override
  State<ClubProfilePage> createState() => _ClubProfilePageState();
}

class _ClubProfilePageState extends State<ClubProfilePage> {
  final TextEditingController _newPostController = TextEditingController();
  final TextEditingController _newMediaController = TextEditingController();

  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminOrLeader = widget.userRole == "admin" || widget.userRole == "leader";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clubs').doc(widget.clubDoc.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final clubData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        final bool isClubActive = (clubData['isActive'] ?? true) &&
                                 (clubData['status']?.toString().toLowerCase() == 'active');

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    clubData['name'] ?? 'Club Profile',
                    style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              if (widget.userRole == "leader")
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF3674B5), size: 24),
                  onPressed: () => _showLeaderEditRequestDialog(context, clubData),
                ),
              if (widget.userRole == "leader")
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  onPressed: _handleLogout,
                ),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildEnhancedHeader(clubData)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text("Latest Updates",
                              style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        if (isAdminOrLeader)
                          isClubActive
                              ? TextButton.icon(
                                  onPressed: () => _showCreatePostDialog(context, isClubActive),
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  label: const Text("Post"),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF3674B5)),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFE65100)),
                                      SizedBox(width: 4),
                                      Text("Suspended",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFE65100),
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('clubId', isEqualTo: widget.clubDoc.id)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    }
                    final posts = postSnapshot.data?.docs ?? [];
                    if (posts.isEmpty) {
                      return const SliverToBoxAdapter(
                          child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(50),
                                child: Text('No posts published yet', style: TextStyle(color: Colors.grey)),
                              )));
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildProfessionalPostCard(posts[index], isAdminOrLeader),
                        childCount: posts.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(Map<String, dynamic> data) {
    final isAdminOrLeader = widget.userRole == "admin" || widget.userRole == "leader";

    final String photoUrl = data['photoUrl'] ?? '';
    final bool hasValidImage = photoUrl.trim().isNotEmpty;
    
    // تحديد الحالة للعرض
    bool isActive = (data['isActive'] ?? true) && (data['status']?.toString().toLowerCase() == 'active');
    String statusText = isActive ? 'Active' : 'Suspended';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFF0F7FF),
                backgroundImage: hasValidImage ? NetworkImage(photoUrl) : null,
                child: !hasValidImage ? const Icon(Icons.groups_rounded, size: 40, color: Color(0xFF3674B5)) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'Club Name',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E3A8A)),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    _buildCategoryTag(data['category'] ?? 'General'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(data['bio'] ?? "Welcome to our club!", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Members'),
              if (isAdminOrLeader) _buildAdminInfo(data['leaderName'] ?? 'Unassigned', 'Leader'),
              _buildAdminInfo(statusText, 'Status', isStatus: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
      child: Text(text.toUpperCase(), style: const TextStyle(color: Color(0xFF0369A1), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatItem(String label) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance.collection('memberships').where('clubId', isEqualTo: widget.clubDoc.id).where('status', isEqualTo: 'approved').count().get(),
      builder: (context, snap) {
        String value = snap.hasData ? snap.data!.count.toString() : '0';
        return Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        );
      },
    );
  }

  Widget _buildAdminInfo(String value, String label, {bool isStatus = false}) {
    Color statusColor = const Color(0xFF1E3A8A);
    if (isStatus) {
      if (value.toLowerCase() == 'active') statusColor = Colors.green;
      if (value.toLowerCase() == 'suspended') statusColor = Colors.orange;
    }

    return Column(
      children: [
        Text(value, style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: statusColor
        ), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _buildProfessionalPostCard(DocumentSnapshot post, bool isAdminOrLeader) {
    final data = post.data() as Map<String, dynamic>;
    final List media = data['media'] ?? [];

    final String mediaUrl = media.isNotEmpty ? media[0].toString().trim() : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mediaUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    mediaUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
              if (mediaUrl.isNotEmpty) const SizedBox(height: 12),
              Text(data['title'] ?? "Update", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 8),
              Text(data['content'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, bool isClubActive) {
    if (!isClubActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action forbidden: Club is currently suspended."), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _newPostController, decoration: const InputDecoration(hintText: "Description")),
            TextField(controller: _newMediaController, decoration: const InputDecoration(hintText: "Media URL")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              List<String> mediaArray = _newMediaController.text.split(',').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList();
              await FirebaseFirestore.instance.collection('posts').add({
                'clubId': widget.clubDoc.id,
                'title': 'New Update',
                'content': _newPostController.text,
                'media': mediaArray,
                'timestamp': FieldValue.serverTimestamp(),
              });
              _newPostController.clear();
              _newMediaController.clear();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  void _showLeaderEditRequestDialog(BuildContext context, Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(text: currentData['name']);
    final categoryCtrl = TextEditingController(text: currentData['category']);
    final bioCtrl = TextEditingController(text: currentData['bio']);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Request Info Change', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('These changes will be sent to the admin for approval.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Club Name')),
                    const SizedBox(height: 10),
                    TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
                    const SizedBox(height: 10),
                    TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Overview / Bio')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isSubmitting ? null : () async {
                    setStateDialog(() => isSubmitting = true);
                    await FirebaseFirestore.instance.collection('club_edit_requests').add({
                      'clubId': widget.clubDoc.id,
                      'originalName': currentData['name'],
                      'requestedName': nameCtrl.text.trim(),
                      'requestedCategory': categoryCtrl.text.trim(),
                      'requestedBio': bioCtrl.text.trim(),
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to Admin!'), backgroundColor: Colors.green));
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Request', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      ),
    );
  }
}
