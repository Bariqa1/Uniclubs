import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/club_model.dart';
import 'club_detail_screen.dart';

class ClubsDiscoveryScreen extends StatefulWidget {
  const ClubsDiscoveryScreen({super.key});

  @override
  State<ClubsDiscoveryScreen> createState() => _ClubsDiscoveryScreenState();
}

class _ClubsDiscoveryScreenState extends State<ClubsDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isSearching = false;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  List<Map<String, dynamic>> _allClubs = [];
  List<Map<String, dynamic>> _displayedClubs = [];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> clubs = await _firestoreService.getClubs(limit: 100);
      
      setState(() {
        _allClubs = clubs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clubs: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _displayedClubs = _allClubs.where((club) {
        // Category filter
        bool matchesCategory = _selectedCategory == 'All' || 
                               club['category'] == _selectedCategory.toLowerCase();
        
        // Search filter
        bool matchesSearch = _searchController.text.isEmpty ||
                            club['name'].toLowerCase().contains(_searchController.text.toLowerCase());
        
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      _applyFilters();
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> results = await _firestoreService.searchClubs(query);
      setState(() {
        _displayedClubs = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching: $e');
      _applyFilters();
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
              _buildAppBar(),
              _buildCategoryFilters(),
              Expanded(
                child: _buildClubsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (!_isSearching)
            const Text(
              'Clubs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5),
              ),
            ),
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search clubs...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF578FCA).withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF578FCA)),
                ),
                onChanged: (value) => _handleSearch(value),
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _applyFilters();
                }
              });
            },
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF3674B5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      {'name': 'All', 'icon': '🎯'},
      {'name': 'tech', 'icon': '💻'},
      {'name': 'sports', 'icon': '⚽'},
      {'name': 'arts', 'icon': '🎨'},
      {'name': 'academic', 'icon': '📚'},
      {'name': 'social', 'icon': '🎉'},
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name']!;
                _applyFilters();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? const Color(0xFF3674B5).withOpacity(0.3)
                        : const Color(0xFF578FCA).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    category['icon']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF578FCA),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClubsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3674B5)),
      );
    }

    if (_displayedClubs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadClubs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _displayedClubs.length,
        itemBuilder: (context, index) {
          return _buildClubCard(_displayedClubs[index]);
        },
      ),
    );
  }

  Widget _buildClubCard(Map<String, dynamic> club) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClubDetailScreen(club: Club.fromMap(club)),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Club Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientColors(club['category'] ?? 'tech'),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(club['category'] ?? 'tech'),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Club Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Name
                    Text(
                      club['name'] ?? 'Unnamed Club',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3674B5),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1E3F9).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category, size: 12, color: Color(0xFF3674B5)),
                          const SizedBox(width: 4),
                          Text(
                            (club['category'] ?? 'general').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3674B5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Member Count
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Color(0xFF578FCA)),
                        const SizedBox(width: 6),
                        Text(
                          '${club['memberCount'] ?? 0} members',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF578FCA).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      club['description'] ?? 'No description available',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: const Color(0xFF578FCA).withOpacity(0.5),
              ),
            ],
          ),
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
              color: const Color(0xFFA1E3F9).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 60,
              color: const Color(0xFF578FCA).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Clubs Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF578FCA).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
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
}