import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import 'event_detail_screen.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _registrations = [];
  // eventId → submitted feedback data (null = not submitted)
  final Map<String, Map<String, dynamic>?> _feedbackData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final registrations = await _firestoreService.getUserRegistrations(user.uid);

      // For attended past events, fetch submitted feedback if any
      final Map<String, Map<String, dynamic>?> feedbackMap = {};
      for (final reg in registrations) {
        if (reg['registrationStatus'] == 'attended') {
          final eventId = reg['id'] as String? ?? '';
          if (eventId.isNotEmpty) {
            feedbackMap[eventId] =
                await _firestoreService.getFeedbackForEvent(user.uid, eventId);
          }
        }
      }

      setState(() {
        _registrations = registrations;
        _feedbackData.addAll(feedbackMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showFeedbackSheet(String eventId, String eventTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FeedbackSheet(
        eventId: eventId,
        eventTitle: eventTitle,
        firestoreService: _firestoreService,
        onSubmitted: (int rating, String comment) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          final data = await _firestoreService.getFeedbackForEvent(user.uid, eventId);
          setState(() => _feedbackData[eventId] = data ?? {'rating': rating, 'comment': comment});
        },
      ),
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
                    color: const Color(0xFF578FCA).withOpacity(0.1),
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
            'My Registrations & Feedback',
            style: TextStyle(
              fontSize: 22,
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
          child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    }
    if (_registrations.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadRegistrations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _registrations.length,
        itemBuilder: (context, index) =>
            _buildRegistrationCard(_registrations[index]),
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> eventData) {
    final date = eventData['date'];
    String formattedDate = 'Date TBD';
    bool isPast = false;
    if (date != null) {
      try {
        final dt = (date as Timestamp).toDate();
        formattedDate = DateFormat('EEE, MMM d • h:mm a').format(dt);
        isPast = dt.isBefore(DateTime.now());
      } catch (_) {}
    }

    final category = eventData['category'] as String? ?? 'general';
    final regStatus = eventData['registrationStatus'] as String? ?? 'registered';
    final isAttended = regStatus == 'attended';
    final eventId = eventData['id'] as String? ?? '';
    final submittedFeedback = _feedbackData[eventId];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: Event.fromFirestore(eventData)),
        ),
      ),
      child: Container(
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
            // Colored header strip
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _getGradientColors(category)),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: _getGradientColors(category)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_getCategoryEmoji(category),
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventData['title'] ?? 'Unnamed Event',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3674B5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 13, color: Color(0xFF578FCA)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      const Color(0xFF578FCA).withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (eventData['location'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 13, color: Color(0xFF578FCA)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  eventData['location'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF578FCA)
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(regStatus, isPast),
                ],
              ),
            ),

            // Feedback section — only for attended past events
            if (isAttended && isPast)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: submittedFeedback != null
                    ? _buildSubmittedFeedback(submittedFeedback)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showFeedbackSheet(
                            eventId,
                            eventData['title'] ?? 'Event',
                          ),
                          icon: const Icon(Icons.star_rounded,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'Leave Feedback',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3674B5),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedFeedback(Map<String, dynamic> feedback) {
    final rating = (feedback['rating'] as num?)?.toInt() ?? 0;
    final comment = feedback['comment'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDEECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded,
                  size: 15, color: Color(0xFF3674B5)),
              const SizedBox(width: 6),
              const Text(
                'Your Feedback',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    (i + 1) <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: (i + 1) <= rating
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFCCDDEE),
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF3674B5).withOpacity(0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String regStatus, bool isPast) {
    Color color;
    String label;
    IconData icon;
    switch (regStatus) {
      case 'attended':
        color = Colors.green;
        label = 'Attended';
        icon = Icons.check_circle_rounded;
        break;
      case 'registered':
        if (isPast) {
          color = Colors.grey;
          label = 'Past';
          icon = Icons.history_rounded;
        } else {
          color = const Color(0xFF3674B5);
          label = 'Upcoming';
          icon = Icons.event_rounded;
        }
        break;
      default:
        color = const Color(0xFF578FCA);
        label = regStatus;
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
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
            child: Icon(Icons.event_note_outlined,
                size: 60, color: const Color(0xFF578FCA).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Registrations Yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5)),
          ),
          const SizedBox(height: 8),
          Text(
            'Register for events from the Events tab',
            style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF578FCA).withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String category) {
    switch (category) {
      case 'tech': return [const Color(0xFF3674B5), const Color(0xFF578FCA)];
      case 'sports': return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
      case 'arts': return [const Color(0xFFA1E3F9), const Color(0xFF578FCA)];
      case 'academic': return [const Color(0xFF3674B5), const Color(0xFFA1E3F9)];
      case 'social': return [const Color(0xFFA1E3F9), const Color(0xFF3674B5)];
      default: return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
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

// ─── Feedback bottom sheet ───────────────────────────────────────────────────

class _FeedbackSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final FirestoreService firestoreService;
  final void Function(int rating, String comment) onSubmitted;

  const _FeedbackSheet({
    required this.eventId,
    required this.eventTitle,
    required this.firestoreService,
    required this.onSubmitted,
  });

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final ok = await widget.firestoreService.submitFeedback(
      userId: userId,
      eventId: widget.eventId,
      rating: _rating,
      comment: _commentController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      widget.onSubmitted(_rating, _commentController.text);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your feedback!'),
          backgroundColor: Color(0xFF3674B5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push sheet up when keyboard appears
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Leave Feedback',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3674B5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.eventTitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF578FCA).withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

                // Star rating
                const Text(
                  'How was the event?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3674B5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 42,
                          color: star <= _rating
                              ? const Color(0xFFFFC107)
                              : const Color(0xFFCCDDEE),
                        ),
                      ),
                    );
                  }),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _ratingLabel(_rating),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF578FCA),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Comment
                const Text(
                  'Any comments? (optional)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3674B5),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts about this event...',
                    hintStyle: TextStyle(
                        color: const Color(0xFF578FCA).withOpacity(0.5),
                        fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF0F9FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Submit Feedback',
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
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Great';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}
