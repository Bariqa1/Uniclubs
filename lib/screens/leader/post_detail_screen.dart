import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailScreen extends StatelessWidget {
  final DocumentSnapshot post;
  PostDetailScreen({super.key, required this.post});

  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(data['content'] ?? "", style: const TextStyle(fontSize: 18))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('comments')
                  .where('postId', isEqualTo: post.id).orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No comments yet."));

                return ListView(
                  children: snapshot.data!.docs.map((doc) => ListTile(title: Text(doc['text']))).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: "Add comment..."))),
              IconButton(icon: const Icon(Icons.send), onPressed: () async {
                await FirebaseFirestore.instance.collection('comments').add({
                  'postId': post.id,
                  'text': _commentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                _commentController.clear();
              })
            ]),
          )
        ],
      ),
    );
  }
}