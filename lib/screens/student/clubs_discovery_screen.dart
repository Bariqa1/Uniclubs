import 'package:flutter/material.dart';

class ClubsDiscoveryScreen extends StatefulWidget {
  const ClubsDiscoveryScreen({super.key});

  @override
  State<ClubsDiscoveryScreen> createState() => _ClubsDiscoveryScreenState();
}

class _ClubsDiscoveryScreenState extends State<ClubsDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F4FD),
              Color(0xFFF0F9FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Search
              _buildAppBar(),

              // Category Filters
              _buildCategoryFilters(),

              // Clubs List
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
                fontFamily: 'SF Arabic',
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
                style: const TextStyle(
                  fontFamily: 'SF Arabic',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search clubs...',
                  hintStyle: TextStyle(
                    fontFamily: 'SF Arabic',
                    color: const Color(0xFF578FCA).withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF578FCA),
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implement real-time search
                  setState(() {});
                },
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
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
    final categories = ['All', 'Tech', 'Sports', 'Arts', 'Academic', 'Social'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFF3674B5),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontFamily: 'SF Arabic',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF578FCA),
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3674B5)
                    : const Color(0xFF578FCA).withOpacity(0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClubsList() {
    final clubs = _getSampleClubs();

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement pull to refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clubs.length,
        itemBuilder: (context, index) {
          final club = clubs[index];
          return _buildClubCard(club);
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
                  colors: club['gradient'] as List<Color>,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  club['emoji'] as String,
                  style: const TextStyle(fontSize: 32),
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
                    club['name'] as String,
                    style: const TextStyle(
                      fontFamily: 'SF Arabic',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1E3F9).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      club['category'] as String,
                      style: const TextStyle(
                        fontFamily: 'SF Arabic',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3674B5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Member Count
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Color(0xFF578FCA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${club['members']} members',
                        style: TextStyle(
                          fontFamily: 'SF Arabic',
                          fontSize: 13,
                          color: const Color(0xFF578FCA).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    club['description'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Arabic',
                      fontSize: 12,
                      color: const Color(0xFF578FCA).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: const Color(0xFF578FCA).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleClubs() {
    return [
      {
        'name': 'AI & Robotics Club',
        'category': 'Tech',
        'members': 145,
        'description': 'Exploring artificial intelligence and robotics innovations',
        'emoji': '🤖',
        'gradient': [const Color(0xFF3674B5), const Color(0xFF578FCA)],
      },
      {
        'name': 'Code Club',
        'category': 'Tech',
        'members': 120,
        'description': 'Learn coding, build projects, and participate in hackathons',
        'emoji': '💻',
        'gradient': [const Color(0xFF578FCA), const Color(0xFFA1E3F9)],
      },
      {
        'name': 'Football Team',
        'category': 'Sports',
        'members': 80,
        'description': 'University football team - training and tournaments',
        'emoji': '⚽',
        'gradient': [const Color(0xFFA1E3F9), const Color(0xFF578FCA)],
      },
      {
        'name': 'Design Society',
        'category': 'Arts',
        'members': 95,
        'description': 'UI/UX design, graphic design, and creative workshops',
        'emoji': '🎨',
        'gradient': [const Color(0xFF3674B5), const Color(0xFFA1E3F9)],
      },
      {
        'name': 'Business Club',
        'category': 'Academic',
        'members': 110,
        'description': 'Entrepreneurship, case studies, and business competitions',
        'emoji': '📈',
        'gradient': [const Color(0xFF578FCA), const Color(0xFF3674B5)],
      },
      {
        'name': 'Photography Club',
        'category': 'Arts',
        'members': 65,
        'description': 'Learn photography techniques and explore creative shots',
        'emoji': '📷',
        'gradient': [const Color(0xFFA1E3F9), const Color(0xFF3674B5)],
      },
    ];
  }
}