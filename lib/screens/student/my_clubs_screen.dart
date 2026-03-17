import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/club_model.dart';
import 'club_detail_screen.dart';

class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});

  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _clubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyClubs();
  }

  Future<void> _loadMyClubs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final clubs = await _firestoreService.getUserClubs(user.uid);
      setState(() {
        _clubs = clubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF578FCA).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF3674B5)),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'My Clubs',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3674B5)),
      );
    }

    if (_clubs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMyClubs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _clubs.length,
        itemBuilder: (context, index) => _buildClubCard(_clubs[index]),
      ),
    );
  }

  Widget _buildClubCard(Map<String, dynamic> club) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubDetailScreen(club: Club.fromMap(club)),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF578FCA).withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradientColors(club['category'] ?? 'general'),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getCategoryEmoji(club['category'] ?? 'general'),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club['name'] ?? 'Unnamed Club',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (club['category'] ?? 'general').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF578FCA).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Color(0xFF578FCA)),
                      const SizedBox(width: 4),
                      Text(
                        '${club['memberCount'] ?? 0} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF578FCA).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Member',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFA1E3F9).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 60,
              color: const Color(0xFF578FCA).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Clubs Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join clubs from the Clubs tab',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF578FCA).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String category) {
    switch (category) {
      case 'tech':
        return [const Color(0xFF3674B5), const Color(0xFF578FCA)];
      case 'sports':
        return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
      case 'arts':
        return [const Color(0xFFA1E3F9), const Color(0xFF578FCA)];
      case 'academic':
        return [const Color(0xFF3674B5), const Color(0xFFA1E3F9)];
      default:
        return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'tech': return '💻';
      case 'sports': return '⚽';
      case 'arts': return '🎨';
      case 'academic': return '📚';
      case 'social': return '🎉';
      default: return '🎯';
    }
  }
}