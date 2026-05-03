import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/admin_club_card.dart';
// import 'club_overview_page.dart';
import '../leader/club_profile_page.dart';
import 'admin_pending_requests_screen.dart';

class AdminClubsScreen extends StatefulWidget {
  final String userRole;

  const AdminClubsScreen({super.key, required this.userRole});

  @override
  State<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends State<AdminClubsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _deleteClubWithConfirmation(String docId, String clubName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Club"),
          ],
        ),
        content: Text("Are you sure you want to delete '$clubName'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('clubs').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Club deleted successfully!"), backgroundColor: Colors.green),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3674B5)));
            }

            final List<QueryDocumentSnapshot> docs =
            snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildPendingRequestsBanner(),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildCategoryFilter(),
                        const SizedBox(height: 24),
                        _buildClubsList(docs),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
              'Clubs Oversight',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          if (widget.userRole == 'admin')
            ElevatedButton.icon(
              onPressed: _showAddClubSheet,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('New Club',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B9FD8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRole', isEqualTo: 'admin')
          .where('type', whereIn: ['club_request', 'new_club_request'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        int count = snapshot.data!.docs.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPendingRequestsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF3674B5), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$count Pending Actions',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF3674B5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Search clubs...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        List<String> dynamicCategories = ['All'];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            dynamicCategories.add(doc['name'].toString());
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...dynamicCategories.map((cat) {
                bool isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat[0].toUpperCase() + cat.substring(1)),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedCategoryFilter = cat),
                    selectedColor: const Color(0xFF5B9FD8),
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)),
                  ),
                );
              }),
              if (widget.userRole == 'admin')
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add Category'),
                  onPressed: _showAddCategoryDialog,
                  backgroundColor: Colors.white,
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildClubsList(List<QueryDocumentSnapshot> docs) {
    var filteredClubs = docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;

      String name = (data['name'] ?? '').toLowerCase();
      String category = (data['category'] ?? '').toLowerCase();

      bool matchesSearch = name.contains(_searchQuery);
      bool matchesFilter = _selectedCategoryFilter == 'All' ||
          category == _selectedCategoryFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredClubs.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No clubs found matching your criteria.',
                  style: TextStyle(color: Colors.grey))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredClubs.length,
      itemBuilder: (context, index) {
        var clubData = filteredClubs[index].data() as Map<String, dynamic>;
        String docId = filteredClubs[index].id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Dismissible(
            key: Key(docId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await _deleteClubWithConfirmation(docId, clubData['name'] ?? 'Club');
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            ),
            child: AdminClubCard(
              docId: docId,
              club: clubData,
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClubProfilePage(
                      clubDoc: filteredClubs[index],
                      userRole: widget.userRole,
                    ),
                  ),
                );
              },
              onToggleStatus: () => _confirmToggleStatus(
                  docId,
                  clubData['status'] ?? 'active',
                  clubData['name'] ?? 'Club'),
            ),
          ),
        );
      },
    );
  }

  void _confirmToggleStatus(
      String docId, String currentStatus, String clubName) {
    bool isSuspending = currentStatus.toLowerCase() != 'suspended';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSuspending ? 'Suspend Club?' : 'Activate Club?'),
        content: Text(
            'Are you sure you want to ${isSuspending ? 'suspend' : 'activate'} $clubName?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: isSuspending ? Colors.red : Colors.green),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('clubs')
                  .doc(docId)
                  .update({
                'status': isSuspending ? 'suspended' : 'active'
              });
              Navigator.pop(ctx);
            },
            child: Text(isSuspending ? 'Suspend' : 'Activate',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Media, Health...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String value = controller.text.trim().toLowerCase();
              if (value.isNotEmpty) {
                await FirebaseFirestore.instance.collection('categories').add({
                  'name': value,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add To System'),
          )
        ],
      ),
    );
  }

  void _showAddClubSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String category = 'tech';
    String? selectedLeaderId;
    String? selectedLeaderName;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            double sheetWidth = MediaQuery.of(context).size.width - 48;

            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Club', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
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

                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'club_leader').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          var leaders = snapshot.data!.docs;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              DropdownMenu<String>(
                                width: sheetWidth,
                                initialSelection: 'none',
                                label: const Text('Assign Leader'),
                                menuStyle: MenuStyle(
                                  backgroundColor: WidgetStateProperty.all(Colors.white),
                                  surfaceTintColor: WidgetStateProperty.all(Colors.white),
                                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                ),
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                                ),
                                onSelected: (val) {
                                  setSheetState(() {
                                    selectedLeaderId = val;
                                    selectedLeaderName = (val != null && val != 'none')
                                        ? leaders.firstWhere((l) => l.id == val).get('name')
                                        : 'Unassigned';
                                  });
                                },
                                dropdownMenuEntries: [
                                  const DropdownMenuEntry(value: 'none', label: 'Assign Later'),
                                  ...leaders.map((l) => DropdownMenuEntry(value: l.id, label: l.get('name') ?? 'Unknown')),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showQuickAddLeaderDialog();
                                },
                                icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF5B9FD8)),
                                label: const Text('New Leader?', style: TextStyle(fontSize: 12, color: Color(0xFF5B9FD8), fontWeight: FontWeight.bold)),
                              )
                            ],
                          );
                        }
                    ),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                      builder: (context, snapshot) {
                        List<DropdownMenuEntry<String>> categoryEntries = [];
                        if (snapshot.hasData) {
                          categoryEntries = snapshot.data!.docs.map((doc) {
                            String name = doc['name'].toString();
                            return DropdownMenuEntry(
                              value: name.toLowerCase(),
                              label: name[0].toUpperCase() + name.substring(1),
                            );
                          }).toList();
                        }

                        if (categoryEntries.isEmpty) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        if (!categoryEntries.any((e) => e.value == category)) {
                          category = categoryEntries.first.value;
                        }

                        return DropdownMenu<String>(
                          width: sheetWidth,
                          initialSelection: category,
                          label: const Text('Category'),
                          menuStyle: MenuStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.white),
                            surfaceTintColor: WidgetStateProperty.all(Colors.white),
                            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          ),
                          onSelected: (val) => setSheetState(() => category = val!),
                          dropdownMenuEntries: categoryEntries,
                        );
                      }
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isLoading = true);
                            try {
                              var existCheck = await FirebaseFirestore.instance.collection('clubs').where('name', isEqualTo: nameCtrl.text.trim()).get();
                              if (existCheck.docs.isNotEmpty) {
                                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Club name already exists!'), backgroundColor: Colors.red));
                                setSheetState(() => isLoading = false);
                                return;
                              }

                              DocumentReference clubRef = await FirebaseFirestore.instance.collection('clubs').add({
                                'name': nameCtrl.text.trim(),
                                'leaderName': selectedLeaderName ?? 'Unassigned',
                                'leaderId': (selectedLeaderId == 'none' || selectedLeaderId == null) ? null : selectedLeaderId,
                                'category': category,
                                'status': 'active',
                                'memberCount': 0,
                                'createdAt': FieldValue.serverTimestamp(),
                                'description': 'Welcome to our new club! Stay tuned for more updates.',
                                'logo': '',
                              });

                              if (selectedLeaderId != null && selectedLeaderId != 'none') {
                                await FirebaseFirestore.instance.collection('users').doc(selectedLeaderId).update({
                                  'clubId': clubRef.id,
                                  'clubName': nameCtrl.text.trim(),
                                });
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              debugPrint("Error: $e");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Club', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showQuickAddLeaderDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isAdding = false;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Quick Add Leader', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.bold)),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: InputDecoration(labelText: 'University Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                        validator: (val) => (val == null || !val.endsWith('@qu.edu.sa')) ? 'Invalid email' : null,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: isAdding ? null : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isAdding = true);
                        try {
                          String email = emailCtrl.text.trim().toLowerCase();

                          // Check if user already exists
                          var userQuery = await FirebaseFirestore.instance.collection('users')
                              .where('email', isEqualTo: email)
                              .limit(1).get();

                          if (userQuery.docs.isNotEmpty) {
                            var existingUser = userQuery.docs.first;
                            var userData = existingUser.data();
                            String role = userData['role'] ?? 'student';
                            String currentName = userData['name'] ?? 'User';

                            if (role == 'club_leader') {
                              setDialogState(() => isAdding = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $currentName is already a Leader.'), backgroundColor: Colors.orange),
                                );
                              }
                              return;
                            } else if (role == 'student') {
                              setDialogState(() => isAdding = false);
                              if (context.mounted) {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Upgrade Student?'),
                                    content: Text('$currentName is currently a student. Do you want to upgrade them to Club Leader?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm Upgrade')),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  setDialogState(() => isAdding = true);
                                  await existingUser.reference.update({'role': 'club_leader'});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student upgraded to Leader!'), backgroundColor: Colors.green));
                                    Navigator.pop(ctx);
                                  }
                                }
                              }
                              return;
                            }
                          }

                          // New User Logic
                          FirebaseApp? tempApp;
                          try {
                            tempApp = await Firebase.initializeApp(
                              name: 'tempInvitation_${DateTime.now().millisecondsSinceEpoch}',
                              options: Firebase.app().options,
                            );

                            UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp)
                                .createUserWithEmailAndPassword(
                              email: email,
                              password: 'TempPassword123!',
                            );

                            String newUid = userCred.user!.uid;
                            await FirebaseAuth.instanceFor(app: tempApp).sendPasswordResetEmail(email: email);

                            await FirebaseFirestore.instance.collection('users').doc(newUid).set({
                              'uid': newUid,
                              'name': nameCtrl.text.trim(),
                              'email': email,
                              'clubName': 'Unassigned',
                              'role': 'club_leader',
                              'status': 'active',
                              'createdAt': FieldValue.serverTimestamp(),
                              'profilePic': '',
                            });

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Leader added and invitation sent!'), backgroundColor: Colors.green),
                              );
                            }
                          } finally {
                            await tempApp?.delete();
                          }
                        } catch(e) {
                          setDialogState(() => isAdding = false);
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: isAdding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              );
            }
        )
    );
  }
}
