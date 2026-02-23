import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';

class EventsDiscoveryScreen extends StatefulWidget {
  const EventsDiscoveryScreen({super.key});

  @override
  State<EventsDiscoveryScreen> createState() => _EventsDiscoveryScreenState();
}

class _EventsDiscoveryScreenState extends State<EventsDiscoveryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isSearching = false;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  List<Event> _upcomingEvents = [];
  List<Event> _pastEvents = [];
  List<Event> _displayedEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _applyFilters();
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Get upcoming and past events from Firestore
      List<Map<String, dynamic>> upcomingData = 
          await _firestoreService.getUpcomingEvents(limit: 50);
      List<Map<String, dynamic>> pastData = 
          await _firestoreService.getPastEvents(limit: 50);

      setState(() {
        _upcomingEvents = upcomingData.map((data) => Event.fromFirestore(data)).toList();
        _pastEvents = pastData.map((data) => Event.fromFirestore(data)).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Event> sourceEvents = _tabController.index == 0 ? _upcomingEvents : _pastEvents;
    
    setState(() {
      _displayedEvents = sourceEvents.where((event) {
        // Category filter
        bool matchesCategory = _selectedCategory == 'All' || 
                               event.category == _selectedCategory.toLowerCase();
        
        // Search filter
        bool matchesSearch = _searchController.text.isEmpty ||
                            event.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            event.category.toLowerCase().contains(_searchController.text.toLowerCase());
        
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
      List<Map<String, dynamic>> results = await _firestoreService.searchEvents(query);
      setState(() {
        _displayedEvents = results.map((data) => Event.fromFirestore(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
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
              _buildTabs(),
              Expanded(
                child: _buildEventList(),
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
              'Events',
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
                  hintText: 'Search events...',
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3674B5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showFilterSheet,
              icon: const Icon(Icons.tune, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF578FCA),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upcoming, size: 20),
                SizedBox(width: 8),
                Text('Upcoming'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text('Past'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3674B5)),
      );
    }

    if (_displayedEvents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _displayedEvents.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_displayedEvents[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(event.category),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    _getCategoryEmoji(event.category),
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(event),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1E3F9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category, size: 14, color: Color(0xFF3674B5)),
                      const SizedBox(width: 4),
                      Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3674B5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF578FCA)),
                    const SizedBox(width: 6),
                    Text(
                      '${event.formattedDate} • ${event.formattedTime}',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF578FCA)),
                    const SizedBox(width: 6),
                    Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1E3F9).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 16, color: Color(0xFF3674B5)),
                      const SizedBox(width: 6),
                      Text(
                        '${event.currentRegistrations}/${event.capacity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3674B5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'attending',
                        style: TextStyle(fontSize: 12, color: Color(0xFF3674B5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    bool isUpcoming = _tabController.index == 0;
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
              isUpcoming ? Icons.event_busy : Icons.history,
              size: 60,
              color: const Color(0xFF578FCA).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isUpcoming ? 'No Upcoming Events' : 'No Past Events',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUpcoming 
                ? 'Check back soon for new events!'
                : 'Your event history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF578FCA).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Filter Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('tech'),
                      _buildFilterChip('sports'),
                      _buildFilterChip('arts'),
                      _buildFilterChip('academic'),
                      _buildFilterChip('social'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedCategory = 'All');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF578FCA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF578FCA),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = label);
      },
      selectedColor: const Color(0xFF3674B5),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
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
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'tech': return '💻';
      case 'sports': return '⚽';
      case 'arts': return '🎨';
      case 'academic': return '📚';
      case 'social': return '🎉';
      default: return '📌';
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
      default:
        return [const Color(0xFF3674B5), const Color(0xFFA1E3F9)];
    }
  }

  Color _getStatusColor(Event event) {
    if (event.isFull) return Colors.red;
    if (event.isRegistrationOpen) return const Color(0xFF578FCA);
    return Colors.grey;
  }

  String _getStatusText(Event event) {
    if (event.isFull) return 'Full';
    if (event.isRegistrationOpen) return 'Open';
    return 'Closed';
  }
}