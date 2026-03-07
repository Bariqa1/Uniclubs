import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';

class ClubProfilePage extends StatelessWidget {
  final QueryDocumentSnapshot clubDoc;

  const ClubProfilePage({super.key, required this.clubDoc});

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubData = clubDoc.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Club Profile",
          style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildClubHeader(clubData),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFF4A80C0),
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 15),
                child: const Text("Posts",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('clubId', isEqualTo: clubDoc.id)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()));
                }
                final posts = snapshot.data!.docs;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildPostCard(context, posts[index]),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A80C0),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreatePostDialog(context),
      ),
    );
  }

  Widget _buildClubHeader(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          CircleAvatar(
              radius: 35,
              backgroundImage: data['photoUrl'] != null
                  ? NetworkImage(data['photoUrl'])
                  : null),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['name'] ?? 'Club Name',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3674B5))),
                    FutureBuilder<AggregateQuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('memberships')
                          .where('clubId', isEqualTo: clubDoc.id)
                          .count()
                          .get(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Text("...",
                              style: TextStyle(color: Color(0xFF4A80C0)));
                        }
                        return Text("${snap.hasData ? snap.data!.count : 0} members",
                            style: const TextStyle(
                                color: Color(0xFF4A80C0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600));
                      },
                    ),
                  ],
                ),
                Text(data['bio'] ?? '...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7BA1C7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final List media = data['media'] ?? [];

    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? "Update",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
            if (media.isNotEmpty)
              SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: media.length,
                    itemBuilder: (context, i) => Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                              image: NetworkImage(media[i]), fit: BoxFit.cover)),
                    ),
                  )),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.favorite_border, size: 16),
              Text(" ${data['likes'] ?? 0}"),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline, size: 16),
              Text(" ${data['comments'] ?? 0}"),
            ])
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final textController = TextEditingController();
    final mediaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: textController,
                decoration: const InputDecoration(hintText: "Description")),
            TextField(
                controller: mediaController,
                decoration: const InputDecoration(
                    hintText: "Image URL (comma separated)")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              List<String> mediaArray = mediaController.text
                  .split(',')
                  .where((e) => e.trim().isNotEmpty)
                  .map((e) => e.trim())
                  .toList();
              await FirebaseFirestore.instance.collection('posts').add({
                'clubId': clubDoc.id,
                'title': 'New Update',
                'content': textController.text,
                'media': mediaArray,
                'likes': 0,
                'comments': 0,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Post"),
          )
        ],
      ),
    );
  }
}