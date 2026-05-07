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

        final String rawStatus = clubData['status']?.toString().toLowerCase() ?? 'active';
        final bool isClubActive = rawStatus == 'active';

        return Scaffold(
          backgroundColor: const Color(0xFFE8F4FD),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A), size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        const Spacer(),
                        if (widget.userRole == "admin")
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF3674B5), size: 28),
                            onPressed: () => _showAdminEditDialog(context, clubData),
                          ),
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
                  ),
                ),
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
                            onPressed: () => _showCreatePostDialog(context, isClubActive, rawStatus),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text("Post"),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF3674B5)),
                          )
                              : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: rawStatus == 'pending' ? const Color(0xFFFFFDE7) : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: rawStatus == 'pending' ? const Color(0xFFFFF176).withValues(alpha: 0.4) : const Color(0xFFFFB74D).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(rawStatus == 'pending' ? Icons.hourglass_empty_rounded : Icons.lock_outline_rounded,
                                    size: 14,
                                    color: rawStatus == 'pending' ? const Color(0xFFF57F17) : const Color(0xFFE65100)),
                                const SizedBox(width: 4),
                                Text(rawStatus == 'pending' ? "Pending" : "Suspended",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: rawStatus == 'pending' ? const Color(0xFFF57F17) : const Color(0xFFE65100),
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

    final String rawStatus = data['status']?.toString().toLowerCase() ?? 'active';
    String statusText = 'Active';
    if (rawStatus == 'pending') {
      statusText = 'Pending';
    } else if (rawStatus == 'suspended') {
      statusText = 'Suspended';
    }

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
          Text(data['bio'] ?? "Welcome to our club! This club participates in university activities, events, and student engagement programs.", style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Members'),
              if (isAdminOrLeader) _buildLeaderInfo(data),
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
      if (value.toLowerCase() == 'active') {
        statusColor = Colors.green;
      } else if (value.toLowerCase() == 'pending') {
        statusColor = const Color(0xFFF57F17);
      } else if (value.toLowerCase() == 'suspended') {
        statusColor = const Color(0xFFE65100);
      }
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

  Widget _buildLeaderInfo(Map<String, dynamic> data) {
    final String? storedName = data['leaderName'] as String?;
    final String? leaderId = data['leaderId'] as String?;
    final bool needsLookup = (storedName == null || storedName.isEmpty || storedName == 'Unassigned')
        && leaderId != null && leaderId.isNotEmpty;

    if (!needsLookup) {
      return _buildAdminInfo(storedName ?? 'Unassigned', 'Leader');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(leaderId).get(),
      builder: (_, snap) {
        final name = snap.hasData && snap.data!.exists
            ? (snap.data!.data() as Map<String, dynamic>)['name'] as String? ?? 'Unknown'
            : (snap.connectionState == ConnectionState.waiting ? '...' : 'Unassigned');
        return _buildAdminInfo(name, 'Leader');
      },
    );
  }

  Widget _buildProfessionalPostCard(DocumentSnapshot post, bool isAdminOrLeader) {
    final data = post.data() as Map<String, dynamic>;
    final List media = data['media'] ?? [];
    final clubData = widget.clubDoc.data() as Map<String, dynamic>;
    final clubName = clubData['name'] ?? 'Club';
    final clubLogo = clubData['photoUrl'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: clubLogo != null && clubLogo.trim().isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(clubLogo, fit: BoxFit.cover),
                    )
                        : const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    clubName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (media.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, media[0] as String),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      media[0] as String,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(data['title'] ?? 'Update',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 6),
              Text(data['content'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, bool isClubActive, String rawStatus) {
    if (!isClubActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(rawStatus == 'pending' ? "Action forbidden: Club is currently under review." : "Action forbidden: Club is currently suspended."),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('New Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF90A4AE)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _dialogField(titleCtrl, 'Title', 'e.g. Club Meeting Recap', maxLines: 1),
                const SizedBox(height: 12),
                _dialogField(contentCtrl, 'Description', 'What would you like to share?', maxLines: 3),
                const SizedBox(height: 12),
                _dialogField(imageUrlCtrl, 'Image URL (optional)', 'https://...', maxLines: 1),
                const SizedBox(height: 8),

                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: imageUrlCtrl,
                  builder: (_, val, __) {
                    final url = val.text.trim();
                    if (url.isEmpty) return const SizedBox.shrink();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3F3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Could not load image — check the URL',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      final imageUrl = imageUrlCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }
                      setDialog(() => isSubmitting = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('posts')
                            .add({
                          'clubId': widget.clubDoc.id,
                          'title': title,
                          'content': content,
                          'media': imageUrl.isNotEmpty ? [imageUrl] : [],
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      } catch (e) {
                        setDialog(() => isSubmitting = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Publish Post',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF0F9FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDEECF8))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF578FCA), width: 1.5)),
      ),
    );
  }

  // إضافة: دالة تعديل الأدمن التي تم سحبها من الصفحة الملغاة
  void _showAdminEditDialog(BuildContext context, Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(text: currentData['name'] ?? '');
    final categoryCtrl = TextEditingController(text: currentData['category'] ?? '');
    final bioCtrl = TextEditingController(text: currentData['bio'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Club Info', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clubs').doc(widget.clubDoc.id).update({
                'name': nameCtrl.text.trim(),
                'category': categoryCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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