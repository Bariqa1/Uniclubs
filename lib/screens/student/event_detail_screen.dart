import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isRegistering = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final registrations = await _firestoreService.getUserRegistrations(user.uid);
      final isRegistered = registrations.any((r) => r['id'] == widget.event.id);
      if (mounted) setState(() => _isRegistered = isRegistered);
    } catch (_) {}
  }

  Future<void> _handleRegister() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isRegistering = true);

    final result = await _firestoreService.registerForEvent(user.uid, widget.event.id);

    if (!mounted) return;
    setState(() => _isRegistering = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? const Color(0xFF3674B5) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (result['success']) setState(() => _isRegistered = true);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(event),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(event),
                    const SizedBox(height: 20),
                    _buildInfoCards(event),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(event),
                    if (event.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildTagsSection(event),
                    ],
                    const SizedBox(height: 20),
                    _buildCapacityBar(event),
                    const SizedBox(height: 32),
                    _buildRegisterButton(event),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _getGradientColors(event.category).first,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getGradientColors(event.category),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  _getCategoryEmoji(event.category),
                  style: const TextStyle(fontSize: 80),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusText(event),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3674B5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFA1E3F9).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.category, size: 14, color: Color(0xFF3674B5)),
              const SizedBox(width: 6),
              Text(
                event.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3674B5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(Event event) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.calendar_today,
            label: 'Date',
            value: event.formattedDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time,
            label: 'Time',
            value: event.formattedTime,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFA1E3F9).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3674B5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF578FCA).withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(Event event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF578FCA)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.location,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF578FCA).withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF3674B5).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3674B5),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: event.tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3674B5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3674B5).withOpacity(0.2),
              ),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3674B5),
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCapacityBar(Event event) {
    final fill = event.fillPercentage / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF578FCA).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Capacity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5),
                ),
              ),
              Text(
                '${event.currentRegistrations} / ${event.capacity}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF578FCA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 10,
              backgroundColor: const Color(0xFFA1E3F9).withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                event.isFull ? Colors.red : const Color(0xFF3674B5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.isFull
                ? 'Event is full'
                : '${event.capacity - event.currentRegistrations} spots remaining',
            style: TextStyle(
              fontSize: 12,
              color: event.isFull
                  ? Colors.red
                  : const Color(0xFF578FCA).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(Event event) {
    final canRegister = event.isRegistrationOpen && !_isRegistered;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (canRegister && !_isRegistering) ? _handleRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRegistered
              ? Colors.green
              : event.isFull
                  ? Colors.grey
                  : const Color(0xFF3674B5),
          disabledBackgroundColor: _isRegistered ? Colors.green : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isRegistering
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isRegistered
                    ? 'Registered'
                    : event.isFull
                        ? 'Event Full'
                        : !event.isRegistrationOpen
                            ? 'Registration Closed'
                            : 'Register Now',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
