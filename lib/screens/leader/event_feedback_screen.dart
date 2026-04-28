import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';

class EventFeedbackScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventFeedbackScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventFeedbackScreen> createState() => _EventFeedbackScreenState();
}

class _EventFeedbackScreenState extends State<EventFeedbackScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() => _isLoading = true);
    try {
      final feedback = await _firestoreService.getEventFeedback(widget.eventId);
      if (mounted) {
        setState(() {
          _feedbackList = feedback;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, int> _calculateSentimentStats() {
    int positive = 0;
    int negative = 0;
    int neutral = 0;

    for (var f in _feedbackList) {
      String label = (f['sentimentLabel'] ?? 'Neutral').toString().toLowerCase();
      if (label.contains('positive')) {
        positive++;
      } else if (label.contains('negative')) {
        negative++;
      } else {
        neutral++;
      }
    }
    return {'Positive': positive, 'Negative': negative, 'Neutral': neutral};
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateSentimentStats();
    final total = _feedbackList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        title: const Text("Feedback Analysis", style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3674B5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)))
          : Column(
        children: [
          _buildSummaryHeader(stats, total),
          Expanded(
            child: _feedbackList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _feedbackList.length,
              itemBuilder: (context, index) => _buildFeedbackCard(_feedbackList[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Map<String, int> stats, int total) {
    if (total == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.eventTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 4),
          Text("Based on $total responses", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Positive", stats['Positive']!, total, Colors.green),
              _buildStatItem("Neutral", stats['Neutral']!, total, Colors.orange),
              _buildStatItem("Negative", stats['Negative']!, total, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, int total, Color color) {
    double percentage = total > 0 ? (count / total) : 0;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: percentage,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Text("${(percentage * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    String label = (feedback['sentimentLabel'] ?? 'Neutral').toString();
    Color sentimentColor = _getSentimentColor(label);
    IconData sentimentIcon = _getSentimentIcon(label);
    
    String text = feedback['text'] ?? feedback['comment'] ?? 'No comment';
    DateTime? date = (feedback['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: sentimentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(sentimentIcon, size: 16, color: sentimentColor),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(color: sentimentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              if (date != null)
                Text(DateFormat('MMM d').format(date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No feedback yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getSentimentColor(String label) {
    label = label.toLowerCase();
    if (label.contains('positive')) return Colors.green;
    if (label.contains('negative')) return Colors.red;
    return Colors.orange;
  }

  IconData _getSentimentIcon(String label) {
    label = label.toLowerCase();
    if (label.contains('positive')) return Icons.sentiment_satisfied_alt;
    if (label.contains('negative')) return Icons.sentiment_very_dissatisfied;
    return Icons.sentiment_neutral;
  }
}
