import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import 'events_discovery_screen.dart';
import 'clubs_discovery_screen.dart';
import 'profile_screen.dart';
import 'event_detail_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EventsDiscoveryScreen(),
    const ClubsDiscoveryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF578FCA).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.event_rounded,
                  label: 'Events',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.groups_rounded,
                  label: 'Clubs',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF578FCA),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF578FCA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HOME SCREEN - Firebase Connected
// ============================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Event> _recommendedEvents = [];
  List<Event> _upcomingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Fetch upcoming events from Firestore
      List<Map<String, dynamic>> eventsData = 
          await _firestoreService.getUpcomingEvents(limit: 10);

      // Convert to Event objects
      List<Event> events = eventsData.map((data) => Event.fromFirestore(data)).toList();

      setState(() {
        _recommendedEvents = []; // AI recommendations not yet implemented
        _upcomingEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3674B5)),
              )
            : RefreshIndicator(
                onRefresh: _loadEvents,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppBar(),
                      const SizedBox(height: 20),
                      _buildRecommendationsSection(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildUpcomingEventsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover new events and clubs',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF578FCA).withOpacity(0.7),
                ),
              ),
            ],
          ),
          Container(
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
            child: IconButton(
              onPressed: () {
                // TODO: Navigate to notifications screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications coming soon!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF3674B5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _recommendedEvents.isEmpty
              ? const Center(
                  child: Text(
                    'No recommendations yet',
                    style: TextStyle(color: Color(0xFF578FCA)),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _recommendedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildRecommendedEventCard(_recommendedEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecommendedEventCard(Event event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header with Gradient
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(event.category),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                // "For You" Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'For You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.event_note_rounded,
                    size: 40,
                    color: Colors.white.withOpacity(0.3),
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
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1E3F9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date & Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF578FCA)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.formattedDate} • ${event.formattedTime}',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF578FCA).withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.search,
              label: 'Browse Clubs',
              color: const Color(0xFF3674B5),
              onTap: () {
                // Switch to Clubs tab (index 2)
                final dashboardState = context.findAncestorStateOfType<_StudentDashboardState>();
                dashboardState?.setState(() {
                  dashboardState._currentIndex = 2;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.event_note,
              label: 'My Events',
              color: const Color(0xFF578FCA),
              onTap: () {
                // TODO: Navigate to My Events screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('My Events screen coming soon!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _upcomingEvents.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No upcoming events',
                  style: TextStyle(color: Color(0xFF578FCA)),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _upcomingEvents.take(3).length,
                itemBuilder: (context, index) {
                  return _buildUpcomingEventCard(_upcomingEvents[index]);
                },
              ),
      ],
    );
  }

  Widget _buildUpcomingEventCard(Event event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Event Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(event.category),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _getCategoryEmoji(event.category),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF578FCA)),
                    const SizedBox(width: 4),
                    Text(
                      event.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF578FCA).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Color(0xFF578FCA)),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF578FCA).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
      default: return '📌';
    }
  }
}