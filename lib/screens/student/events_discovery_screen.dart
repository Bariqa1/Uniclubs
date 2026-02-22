import 'package:flutter/material.dart';

class EventsDiscoveryScreen extends StatefulWidget {
  const EventsDiscoveryScreen({super.key});

  @override
  State<EventsDiscoveryScreen> createState() => _EventsDiscoveryScreenState();
}

class _EventsDiscoveryScreenState extends State<EventsDiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

              // Tabs
              _buildTabs(),

              // Event List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(isUpcoming: true),
                    _buildEventList(isUpcoming: false),
                  ],
                ),
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
      child: Column(
        children: [
          // Title and Filter Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_isSearching)
                const Text(
                  'Events',
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
                      hintText: 'Search events...',
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
              Row(
                children: [
                  // Search Button
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
                  // Filter Button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3674B5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _showFilterSheet,
                      icon: const Icon(
                        Icons.tune,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
        labelStyle: const TextStyle(
          fontFamily: 'SF Arabic',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SF Arabic',
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
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

  Widget _buildEventList({required bool isUpcoming}) {
    // Sample event data
    final events = _getSampleEvents(isUpcoming);

    if (events.isEmpty) {
      return _buildEmptyState(isUpcoming);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement pull to refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
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
          // Event Header with Gradient
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: event['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                // Event Icon/Emoji
                Center(
                  child: Text(
                    event['emoji'] as String,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
                // Registration Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event['status']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event['status'] as String,
                      style: const TextStyle(
                        fontFamily: 'SF Arabic',
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
                // Event Title
                Text(
                  event['title'] as String,
                  style: const TextStyle(
                    fontFamily: 'SF Arabic',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                ),
                const SizedBox(height: 8),

                // Club Name Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1E3F9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.groups,
                        size: 14,
                        color: Color(0xFF3674B5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event['club'] as String,
                        style: const TextStyle(
                          fontFamily: 'SF Arabic',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3674B5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date & Time
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF578FCA),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${event['date']} • ${event['time']}',
                      style: TextStyle(
                        fontFamily: 'SF Arabic',
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF578FCA),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['location'] as String,
                      style: TextStyle(
                        fontFamily: 'SF Arabic',
                        fontSize: 13,
                        color: const Color(0xFF578FCA).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Attendee Count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1E3F9).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: Color(0xFF3674B5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${event['attendees']}/${event['capacity']}',
                            style: const TextStyle(
                              fontFamily: 'SF Arabic',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3674B5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'attending',
                            style: TextStyle(
                              fontFamily: 'SF Arabic',
                              fontSize: 12,
                              color: Color(0xFF3674B5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
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
              fontFamily: 'SF Arabic',
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
              fontFamily: 'SF Arabic',
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle
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

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Events',
                  style: TextStyle(
                    fontFamily: 'SF Arabic',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontFamily: 'SF Arabic',
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
                      _buildFilterChip('All', true),
                      _buildFilterChip('Tech', false),
                      _buildFilterChip('Sports', false),
                      _buildFilterChip('Arts', false),
                      _buildFilterChip('Academic', false),
                      _buildFilterChip('Social', false),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date Range Filter
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontFamily: 'SF Arabic',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1E3F9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF578FCA).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range,
                          color: Color(0xFF578FCA),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Select date range',
                          style: TextStyle(
                            fontFamily: 'SF Arabic',
                            fontSize: 14,
                            color: Color(0xFF578FCA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Club Filter
                  const Text(
                    'Club',
                    style: TextStyle(
                      fontFamily: 'SF Arabic',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1E3F9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF578FCA).withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Clubs',
                          style: TextStyle(
                            fontFamily: 'SF Arabic',
                            fontSize: 14,
                            color: Color(0xFF578FCA),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF578FCA),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
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
                      'Clear Filters',
                      style: TextStyle(
                        fontFamily: 'SF Arabic',
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
                      'Apply Filters',
                      style: TextStyle(
                        fontFamily: 'SF Arabic',
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement filter logic
        setState(() {});
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFF578FCA);
      case 'Registered':
        return Colors.green;
      case 'Full':
        return Colors.red;
      default:
        return const Color(0xFF578FCA);
    }
  }

  List<Map<String, dynamic>> _getSampleEvents(bool isUpcoming) {
    if (isUpcoming) {
      return [
        {
          'title': 'AI Workshop 2024',
          'club': 'Tech Club',
          'date': 'Feb 20, 2026',
          'time': '10:00 AM',
          'location': 'Lab 101',
          'attendees': 45,
          'capacity': 50,
          'status': 'Open',
          'emoji': '🤖',
          'gradient': [const Color(0xFF3674B5), const Color(0xFF578FCA)],
        },
        {
          'title': 'Mobile Dev Bootcamp',
          'club': 'Code Club',
          'date': 'Feb 22, 2026',
          'time': '2:00 PM',
          'location': 'Room 205',
          'attendees': 30,
          'capacity': 40,
          'status': 'Registered',
          'emoji': '📱',
          'gradient': [const Color(0xFF578FCA), const Color(0xFFA1E3F9)],
        },
        {
          'title': 'Data Science Talk',
          'club': 'AI Society',
          'date': 'Feb 25, 2026',
          'time': '4:00 PM',
          'location': 'Auditorium',
          'attendees': 100,
          'capacity': 100,
          'status': 'Full',
          'emoji': '📊',
          'gradient': [const Color(0xFFA1E3F9), const Color(0xFF578FCA)],
        },
        {
          'title': 'Hackathon 2024',
          'club': 'Tech Club',
          'date': 'Mar 1, 2026',
          'time': '9:00 AM',
          'location': 'CS Building',
          'attendees': 60,
          'capacity': 80,
          'status': 'Open',
          'emoji': '💻',
          'gradient': [const Color(0xFF3674B5), const Color(0xFFA1E3F9)],
        },
      ];
    } else {
      return [
        {
          'title': 'Web Dev Workshop',
          'club': 'Code Club',
          'date': 'Jan 15, 2026',
          'time': '3:00 PM',
          'location': 'Lab 102',
          'attendees': 35,
          'capacity': 40,
          'status': 'Registered',
          'emoji': '🌐',
          'gradient': [const Color(0xFF578FCA), const Color(0xFFA1E3F9)],
        },
      ];
    }
  }
}