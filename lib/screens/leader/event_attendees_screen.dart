import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class EventAttendeesScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;

  const EventAttendeesScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
  });

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _registrants = [];
  bool _isLoading = true;
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _firestoreService.getEventRegistrants(widget.eventId);
    if (mounted) {
      setState(() {
        _registrants = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(Map<String, dynamic> registrant) async {
    final regId = registrant['registrationId'] as String;
    if (_toggling.contains(regId)) return;

    setState(() => _toggling.add(regId));

    final isAttended = registrant['status'] == 'attended';
    bool ok;
    
    if (isAttended) {
      ok = await _firestoreService.unmarkAttended(regId, widget.eventId);
    } else {
      ok = await _firestoreService.markAttended(regId, widget.eventId);
      if (ok) {
        NotificationService().createLocalNotification(
          userId: registrant['userId'],
          type: 'attendance_confirmed',
          title: 'Attendance Confirmed!',
          body: 'Your attendance at "${widget.eventTitle}" has been recorded.',
        );
      }
    }

    if (mounted) {
      setState(() {
        _toggling.remove(regId);
        if (ok) {
          final idx = _registrants.indexWhere((r) => r['registrationId'] == regId);
          if (idx != -1) {
            _registrants[idx] = {
              ..._registrants[idx],
              'status': isAttended ? 'registered' : 'attended',
              'attendedAt': isAttended ? null : Timestamp.now(),
            };
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendedCount = _registrants.where((r) => r['status'] == 'attended').length;
    final total = _registrants.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(attendedCount, total),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF3674B5))))
            else if (_registrants.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _registrants.length,
                    itemBuilder: (_, i) => _buildCard(_registrants[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int attended, int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1E3F9).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF3674B5), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF3674B5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Attendance',
                      style: TextStyle(fontSize: 13, color: const Color(0xFF578FCA).withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3674B5), Color(0xFF578FCA)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$attended / $total attended', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(total > 0 ? '${(attended / total * 100).round()}% rate' : 'No registrants',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.how_to_reg, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? attended / total : 0,
                minHeight: 8,
                backgroundColor: const Color(0xFFA1E3F9).withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3674B5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> registrant) {
    final name = registrant['userName'] as String? ?? 'Unknown';
    final email = registrant['userEmail'] as String? ?? '';
    final attended = registrant['status'] == 'attended';
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: attended ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.5) : null,
        boxShadow: [BoxShadow(color: const Color(0xFF578FCA).withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: attended ? [Colors.green.shade400, Colors.green.shade600] : [const Color(0xFF3674B5), const Color(0xFF578FCA)]),
            ),
            child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF3674B5))),
                if (email.isNotEmpty) Text(email, style: TextStyle(fontSize: 12, color: const Color(0xFF578FCA).withValues(alpha: 0.7))),
              ],
            ),
          ),
          if (_toggling.contains(registrant['registrationId']))
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3674B5)))
          else
            GestureDetector(
              onTap: () => _toggle(registrant),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: attended ? Colors.green : const Color(0xFFA1E3F9).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.check, color: attended ? Colors.white : const Color(0xFF578FCA).withValues(alpha: 0.4), size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(color: const Color(0xFFA1E3F9).withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.people_outline, size: 44, color: const Color(0xFF578FCA).withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            const Text('No registrants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3674B5))),
          ],
        ),
      ),
    );
  }
}
