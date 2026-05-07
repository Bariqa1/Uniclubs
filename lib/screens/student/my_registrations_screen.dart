import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/sentiment_service.dart';
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
        onSubmitted: (String comment) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          final data = await _firestoreService.getFeedbackForEvent(user.uid, eventId);
          setState(() => _feedbackData[eventId] = data ?? {'comment': comment});
        },
      ),
    );
  }

  // ── Categorise registrations ─────────────────────────────────────────────

  bool _isPast(Map<String, dynamic> e) {
    final date = e['date'];
    if (date == null) return false;
    try {
      return (date as Timestamp).toDate().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  List<Map<String, dynamic>> get _needsFeedback => _registrations.where((e) {
        final attended = (e['registrationStatus'] as String?) == 'attended';
        final eventId = e['id'] as String? ?? '';
        return attended && _isPast(e) && _feedbackData[eventId] == null;
      }).toList();

  List<Map<String, dynamic>> get _upcoming => _registrations.where((e) {
        return !_isPast(e);
      }).toList()
        ..sort((a, b) {
          final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          return aDate.compareTo(bDate);
        });

  List<Map<String, dynamic>> get _past {
    final needsFeedbackIds = _needsFeedback.map((e) => e['id']).toSet();
    return _registrations.where((e) {
      return _isPast(e) && !needsFeedbackIds.contains(e['id']);
    }).toList()
      ..sort((a, b) {
        final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bDate.compareTo(aDate); // newest first
      });
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
          const Expanded(
            child: Text(
              'My Events & Feedback',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
    }
    if (_registrations.isEmpty) return _buildEmptyState();

    final nf = _needsFeedback;
    final up = _upcoming;
    final pa = _past;

    // Build a flat item list: section headers + cards
    final List<Widget> items = [];

    if (nf.isNotEmpty) {
      items.add(_buildSectionHeader(
        'Leave Feedback',
        Icons.rate_review_rounded,
        const Color(0xFF3674B5),
        subtitle: 'You attended these — share your thoughts!',
      ));
      for (final e in nf) items.add(_buildRegistrationCard(e));
    }

    if (up.isNotEmpty) {
      items.add(_buildSectionHeader(
        'Upcoming',
        Icons.event_rounded,
        const Color(0xFF578FCA),
        subtitle: '${up.length} event${up.length > 1 ? 's' : ''} registered',
      ));
      for (final e in up) items.add(_buildRegistrationCard(e));
    }

    if (pa.isNotEmpty) {
      items.add(_buildSectionHeader(
        'Past',
        Icons.history_rounded,
        Colors.grey,
        subtitle: '${pa.length} event${pa.length > 1 ? 's' : ''}',
      ));
      for (final e in pa) items.add(_buildRegistrationCard(e));
    }

    return RefreshIndicator(
      onRefresh: _loadRegistrations,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: items,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
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
    final isUnattended = regStatus == 'registered' && isPast;
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
        margin: const EdgeInsets.only(bottom: 14),
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
            // Colored top strip
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _getGradientColors(category)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _getGradientColors(category)),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(_getCategoryEmoji(category),
                          style: const TextStyle(fontSize: 22)),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3674B5),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        if ((eventData['clubName'] as String? ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.groups_rounded,
                                    size: 12, color: Color(0xFF578FCA)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    eventData['clubName'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF578FCA),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: Color(0xFF578FCA)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF578FCA).withOpacity(0.8)),
                              ),
                            ),
                          ],
                        ),
                        if (eventData['location'] != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: Color(0xFF578FCA)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  eventData['location'],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF578FCA).withOpacity(0.8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(regStatus, isPast),
                ],
              ),
            ),

            // Feedback area — attended past events only
            if (isAttended && isPast)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: submittedFeedback != null
                    ? _buildSubmittedFeedback(submittedFeedback)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showFeedbackSheet(eventId, eventData['title'] ?? 'Event'),
                          icon: const Icon(Icons.rate_review_rounded,
                              size: 16, color: Colors.white),
                          label: const Text('Leave Feedback',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3674B5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
              ),

            // Unattended note
            if (isUnattended)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                      SizedBox(width: 6),
                      Text(
                        'Not marked as attended by the club leader',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedFeedback(Map<String, dynamic> feedback) {
    final comment = feedback['comment'] as String? ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDEECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review_rounded, size: 14, color: Color(0xFF3674B5)),
              SizedBox(width: 6),
              Text('Your Feedback',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5))),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: const Color(0xFF3674B5).withOpacity(0.75)),
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

    if (regStatus == 'attended') {
      color = Colors.green;
      label = 'Attended';
      icon = Icons.check_circle_rounded;
    } else if (regStatus == 'registered' && isPast) {
      color = Colors.red;
      label = 'Unattended';
      icon = Icons.cancel_rounded;
    } else {
      color = const Color(0xFF3674B5);
      label = 'Upcoming';
      icon = Icons.event_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
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
          const Text('No Events Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5))),
          const SizedBox(height: 8),
          Text('Register for events from the Events tab',
              style: TextStyle(
                  fontSize: 14, color: const Color(0xFF578FCA).withOpacity(0.7))),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String category) {
    switch (category) {
      case 'tech':     return [const Color(0xFF3674B5), const Color(0xFF578FCA)];
      case 'sports':   return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
      case 'arts':     return [const Color(0xFFA1E3F9), const Color(0xFF578FCA)];
      case 'academic': return [const Color(0xFF3674B5), const Color(0xFFA1E3F9)];
      case 'social':   return [const Color(0xFFA1E3F9), const Color(0xFF3674B5)];
      default:         return [const Color(0xFF578FCA), const Color(0xFFA1E3F9)];
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'tech':     return '💻';
      case 'sports':   return '⚽';
      case 'arts':     return '🎨';
      case 'academic': return '📚';
      case 'social':   return '🎉';
      default:         return '🎯';
    }
  }
}

// ─── Feedback bottom sheet ────────────────────────────────────────────────────

class _FeedbackSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final FirestoreService firestoreService;
  final void Function(String comment) onSubmitted;

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
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final ok = await widget.firestoreService.submitFeedback(
      userId: userId,
      eventId: widget.eventId,
      comment: _commentController.text,
    );

    if (ok) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('feedback')
            .where('userId', isEqualTo: userId)
            .where('eventId', isEqualTo: widget.eventId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final feedbackId = querySnapshot.docs.first.id;
          SentimentService().analyzeFeedback(feedbackId, _commentController.text);
        }
      } catch (e) {
        debugPrint("Error fetching feedback ID for sentiment analysis: $e");
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      widget.onSubmitted(_commentController.text);
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
                const Text('Leave Feedback',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3674B5))),
                const SizedBox(height: 4),
                Text(widget.eventTitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF578FCA).withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 24),
                const Text('Your comments',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3674B5))),
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
                        : const Text('Submit Feedback',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
