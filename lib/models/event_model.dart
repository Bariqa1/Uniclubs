import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String clubId;
  final DateTime date;
  final String location;
  final String category;
  final int capacity;
  final int currentRegistrations;
  final String? poster;
  final List<String> tags;
  final String status; // upcoming, ongoing, completed, cancelled
  final DateTime? registrationDeadline;
  final String? clubName;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.clubId,
    required this.date,
    required this.location,
    required this.category,
    required this.capacity,
    required this.currentRegistrations,
    this.poster,
    required this.tags,
    required this.status,
    this.registrationDeadline,
    this.clubName,
  });

  /// Create Event from Firestore document
  factory Event.fromFirestore(Map<String, dynamic> data) {
    return Event(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled Event',
      description: data['description'] ?? '',
      clubId: data['clubId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      category: data['category'] ?? 'general',
      capacity: data['capacity'] ?? 0,
      currentRegistrations: data['currentRegistrations'] ?? 0,
      poster: data['poster'],
      tags: List<String>.from(data['tags'] ?? []),
      status: data['status'] ?? 'upcoming',
      registrationDeadline: (data['registrationDeadline'] as Timestamp?)?.toDate(),
      clubName: data['clubName'] as String?,
    );
  }

  /// Create Event from backend API JSON response (dates are ISO strings)
  factory Event.fromApi(Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is Timestamp) return value.toDate();
      // Firestore admin SDK may send {"_seconds": ..., "_nanoseconds": ...}
      if (value is Map) {
        final seconds = value['_seconds'] ?? value['seconds'];
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000, isUtc: true).toLocal();
        }
      }
      return DateTime.now();
    }

    return Event(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled Event',
      description: data['description'] ?? '',
      clubId: data['clubId'] ?? '',
      date: parseDate(data['date']),
      location: data['location'] ?? '',
      category: data['category'] ?? 'general',
      capacity: data['capacity'] ?? 0,
      currentRegistrations: data['currentRegistrations'] ?? 0,
      poster: data['poster'],
      tags: List<String>.from(data['tags'] ?? []),
      status: data['status'] ?? 'upcoming',
      registrationDeadline: data['registrationDeadline'] != null
          ? parseDate(data['registrationDeadline'])
          : null,
      clubName: data['clubName'] as String?,
    );
  }

  /// Convert Event to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'clubId': clubId,
      'date': Timestamp.fromDate(date),
      'location': location,
      'category': category,
      'capacity': capacity,
      'currentRegistrations': currentRegistrations,
      'poster': poster,
      'tags': tags,
      'status': status,
      'registrationDeadline': registrationDeadline != null 
          ? Timestamp.fromDate(registrationDeadline!) 
          : null,
    };
  }

  /// Effective status derived from the event date (ignores stale stored value).
  /// Only respects stored 'cancelled' — everything else is computed.
  String get effectiveStatus {
    if (status == 'cancelled') return 'cancelled';
    final now = DateTime.now();
    if (date.isAfter(now)) return 'upcoming';
    return 'completed';
  }

  /// Check if event is full
  bool get isFull => currentRegistrations >= capacity;

  /// Check if registration is open
  bool get isRegistrationOpen {
    if (isFull) return false;
    if (registrationDeadline != null && DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }
    return effectiveStatus == 'upcoming';
  }

  /// Get fill percentage
  double get fillPercentage {
    if (capacity == 0) return 0;
    return (currentRegistrations / capacity * 100).clamp(0, 100);
  }

  /// Get formatted date string
  String get formattedDate {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}