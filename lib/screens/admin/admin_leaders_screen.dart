import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/admin_leader_card.dart';

class AdminLeadersScreen extends StatefulWidget {
  const AdminLeadersScreen({super.key});

  @override
  State<AdminLeadersScreen> createState() => _AdminLeadersScreenState();
}

class _AdminLeadersScreenState extends State<AdminLeadersScreen> {
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
                child: _buildSearchBar()
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildLeadersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Club Leaders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _showAddLeaderSheet,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('New Leader', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B9FD8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Search by name or email...', prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLeadersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'club_leader').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No Leaders Found', style: TextStyle(color: Colors.grey)));

        var leaders = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toLowerCase();
          String email = (data['email'] ?? '').toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: leaders.length,
          itemBuilder: (context, index) {
            var data = leaders[index].data() as Map<String, dynamic>;
            String docId = leaders[index].id;
            return AdminLeaderCard(
              docId: docId,
              data: data,
              onEdit: () => _showEditLeaderSheet(docId, data),
              onDelete: () => _confirmDeleteLeader(docId, data['name'] ?? 'Unknown User'),
            );
          },
        );
      },
    );
  }

  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
    );
  }

  void _showAddLeaderSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? selectedClubId;
    String? selectedClubName;
    bool isLoading = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Add New Leader', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 16),
                    TextFormField(controller: nameCtrl, decoration: _customInputDecoration('Full Name'), validator: (val) => (val == null || val.isEmpty) ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: emailCtrl, decoration: _customInputDecoration('University Email'), validator: (val) => (val == null || !val.endsWith('@qu.edu.sa')) ? 'Invalid email' : null),
                    const SizedBox(height: 12),
                    FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('clubs').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          var clubs = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            initialValue: selectedClubId ?? 'none',
                            decoration: _customInputDecoration('Assign Club'),
                            items: [
                              const DropdownMenuItem(value: 'none', child: Text('Assign Later')),
                              ...clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.get('name'))))
                            ],
                            onChanged: (val) {
                              setSheetState(() {
                                selectedClubId = val;
                                selectedClubName = (val != 'none' && val != null) ? clubs.firstWhere((c) => c.id == val).get('name') : 'Unassigned';
                              });
                            },
                          );
                        }
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isLoading = true);
                            try {
                              DocumentReference userRef = await FirebaseFirestore.instance.collection('users').add({
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'clubId': (selectedClubId == 'none') ? null : selectedClubId,
                                'clubName': selectedClubName ?? 'Unassigned',
                                'role': 'club_leader',
                                'status': 'active',
                                'createdAt': Timestamp.now(),
                              });
                              if (selectedClubId != null && selectedClubId != 'none') {
                                await FirebaseFirestore.instance.collection('clubs').doc(selectedClubId).update({'leaderId': userRef.id, 'leaderName': nameCtrl.text.trim()});
                              }
                              if (context.mounted) Navigator.pop(ctx);
                            } catch (e) { setSheetState(() => isLoading = false); }
                          }
                        },
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Leader', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showEditLeaderSheet(String docId, Map<String, dynamic> currentData) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentData['name']);
    final emailCtrl = TextEditingController(text: currentData['email']);
    String? selectedClubId = currentData['clubId'];
    String? oldClubId = currentData['clubId'];
    String? selectedClubName = currentData['clubName'];
    bool isLoading = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Edit Leader Info', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
                    const SizedBox(height: 16),
                    TextFormField(controller: nameCtrl, decoration: _customInputDecoration('Full Name')),
                    const SizedBox(height: 12),
                    TextFormField(controller: emailCtrl, decoration: _customInputDecoration('University Email')),
                    const SizedBox(height: 12),
                    FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('clubs').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          var clubs = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            initialValue: (selectedClubId == null || !clubs.any((c) => c.id == selectedClubId)) ? 'none' : selectedClubId,
                            decoration: _customInputDecoration('Assign Club'),
                            items: [
                              const DropdownMenuItem(value: 'none', child: Text('Unassigned')),
                              ...clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.get('name'))))
                            ],
                            onChanged: (val) {
                              setSheetState(() {
                                selectedClubId = val == 'none' ? null : val;
                                selectedClubName = (val != 'none' && val != null) ? clubs.firstWhere((c) => c.id == val).get('name') : 'Unassigned';
                              });
                            },
                          );
                        }
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isLoading = true);
                            try {
                              if (oldClubId != null && oldClubId != selectedClubId) {
                                await FirebaseFirestore.instance.collection('clubs').doc(oldClubId).update({'leaderId': null, 'leaderName': 'Unassigned'});
                              }
                              await FirebaseFirestore.instance.collection('users').doc(docId).update({
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'clubId': selectedClubId,
                                'clubName': selectedClubName,
                              });
                              if (selectedClubId != null) {
                                await FirebaseFirestore.instance.collection('clubs').doc(selectedClubId).update({'leaderId': docId, 'leaderName': nameCtrl.text.trim()});
                              }
                              if (context.mounted) Navigator.pop(ctx);
                            } catch (e) { setSheetState(() => isLoading = false); }
                          }
                        },
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _confirmDeleteLeader(String docId, String leaderName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Leader?'),
        content: Text('This will also unassign them from their club.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              var clubs = await FirebaseFirestore.instance.collection('clubs').where('leaderId', isEqualTo: docId).get();
              for (var c in clubs.docs) { await c.reference.update({'leaderId': null, 'leaderName': 'Unassigned'}); }
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}