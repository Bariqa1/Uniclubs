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
  Set<String> _selectedCategories = {};

  List<Map<String, dynamic>> _allClubs = [];
  List<Map<String, dynamic>> _displayedClubs = [];

  static const _categories = [
    {'name': 'tech', 'icon': '💻'},
    {'name': 'sports', 'icon': '⚽'},
    {'name': 'arts', 'icon': '🎨'},
    {'name': 'academic', 'icon': '📚'},
    {'name': 'social', 'icon': '🎉'},
  ];

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
      final clubs = await _firestoreService.getClubs(limit: 100);
      setState(() {
        _allClubs = clubs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading clubs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _displayedClubs = _allClubs.where((club) {
        final isActive = club['status'] == 'active';

        final matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(club['category']);
        final matchesSearch = _searchController.text.isEmpty ||
            (club['name'] as String? ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        return isActive && matchesCategory && matchesSearch;
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
      final results = await _firestoreService.searchClubs(query);
      if (mounted) {
        setState(() {
          _displayedClubs = results.where((c) => c['status'] == 'active').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      _applyFilters();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCategoryDropdown(BuildContext buttonContext) {
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlay =
    Navigator.of(buttonContext).overlay!.context.findRenderObject()
    as RenderBox;
    final offset =
    button.localToGlobal(Offset(0, button.size.height + 4), ancestor: overlay);

    showMenu(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        overlay.size.width - offset.dx - button.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _MultiSelectMenu(
            categories: _categories,
            initialSelected: Set.from(_selectedCategories),
            onApply: (selected) {
              setState(() => _selectedCategories = selected);
              _applyFilters();
              Navigator.pop(buttonContext);
            },
          ),
        ),
      ],
    );
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
              _buildFilterRow(),
              Expanded(child: _buildClubsList()),
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
                    color: const Color(0xFF578FCA).withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF578FCA)),
                ),
                onChanged: _handleSearch,
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

  Widget _buildFilterRow() {
    final hasFilter = _selectedCategories.isNotEmpty;
    final label = hasFilter
        ? _selectedCategories
        .map((c) => c[0].toUpperCase() + c.substring(1))
        .join(', ')
        : 'All Categories';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => _showCategoryDropdown(ctx),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: hasFilter
                        ? const Color(0xFF3674B5).withValues(alpha: 0.08)
                        : Colors.white,
                    border: Border.all(
                      color: hasFilter
                          ? const Color(0xFF3674B5)
                          : const Color(0xFF578FCA).withValues(alpha: 0.25),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF578FCA).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: hasFilter
                            ? const Color(0xFF3674B5)
                            : const Color(0xFF578FCA),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasFilter
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: hasFilter
                                ? const Color(0xFF3674B5)
                                : const Color(0xFF578FCA),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: hasFilter
                            ? const Color(0xFF3674B5)
                            : const Color(0xFF578FCA),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _selectedCategories = {});
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF578FCA).withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF578FCA)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClubsList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    }
    if (_displayedClubs.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadClubs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _displayedClubs.length,
        itemBuilder: (context, index) => _buildClubCard(_displayedClubs[index]),
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
            color: const Color(0xFF578FCA).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ClubDetailScreen(club: Club.fromMap(club))),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: _getGradientColors(club['category'] ?? 'tech')),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club['name'] ?? 'Unnamed Club',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3674B5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1E3F9).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category,
                              size: 12, color: Color(0xFF3674B5)),
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
                    Row(
                      children: [
                        const Icon(Icons.people,
                            size: 16, color: Color(0xFF578FCA)),
                        const SizedBox(width: 6),
                        Text(
                          '${club['memberCount'] ?? 0} members',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF578FCA).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      club['description'] ?? 'No description available',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: const Color(0xFF578FCA).withValues(alpha: 0.5),
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
              color: const Color(0xFFA1E3F9).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_outlined,
                size: 60, color: const Color(0xFF578FCA).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Clubs Found',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5)),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style:
            TextStyle(fontSize: 14, color: const Color(0xFF578FCA).withValues(alpha: 0.7)),
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
      case 'tech': return [const Color(0xFF3674B5), const Color(0xFF578FCA)];
      case 'sports': return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
      case 'arts': return [const Color(0xFFA1E3F9), const Color(0xFF578FCA)];
      case 'academic': return [const Color(0xFF3674B5), const Color(0xFFA1E3F9)];
      default: return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
    }
  }
}

// Self-contained stateful widget for the dropdown content
class _MultiSelectMenu extends StatefulWidget {
  final List<Map<String, String>> categories;
  final Set<String> initialSelected;
  final void Function(Set<String>) onApply;

  const _MultiSelectMenu({
    required this.categories,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<_MultiSelectMenu> createState() => _MultiSelectMenuState();
}

class _MultiSelectMenuState extends State<_MultiSelectMenu> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3674B5),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ...widget.categories.map((cat) {
            final isSelected = _selected.contains(cat['name']);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selected.remove(cat['name']);
                  } else {
                    _selected.add(cat['name']!);
                  }
                });
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Text(cat['icon']!,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat['name']![0].toUpperCase() +
                            cat['name']!.substring(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF3674B5)
                              : const Color(0xFF578FCA),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                          key: ValueKey(true),
                          size: 20,
                          color: Color(0xFF3674B5))
                          : const Icon(Icons.circle_outlined,
                          key: ValueKey(false),
                          size: 20,
                          color: Color(0xFFCCDDEE)),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF578FCA)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(Set.from(_selected)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}