import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // EVENTS
  // ============================================

  /// Get upcoming events
  Future<List<Map<String, dynamic>>> getUpcomingEvents({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'upcoming')
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting upcoming events: $e');
      return [];
    }
  }

  /// Get past events
  Future<List<Map<String, dynamic>>> getPastEvents({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('date', isLessThan: Timestamp.now())
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      })
          .where((data) => data['status'] != 'cancelled')
          .toList();
    } catch (e) {
      debugPrint('Error getting past events: $e');
      return [];
    }
  }

  /// Search events by title or category
  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'upcoming')
          .get();

      return snapshot.docs
          .where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String title = data['title']?.toLowerCase() ?? '';
        String category = data['category']?.toLowerCase() ?? '';
        String searchQuery = query.toLowerCase();
        return title.contains(searchQuery) || category.contains(searchQuery);
      })
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      })
          .toList();
    } catch (e) {
      debugPrint('Error searching events: $e');
      return [];
    }
  }

  /// Get events by category
  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'upcoming')
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting events by category: $e');
      return [];
    }
  }

  /// Get event by ID
  Future<Map<String, dynamic>?> getEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('events').doc(eventId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    }
  }

  // ============================================
  // CLUBS
  // ============================================

  /// Get all active clubs
  Future<List<Map<String, dynamic>>> getClubs({int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('clubs')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting clubs: $e');
      return [];
    }
  }

  /// Get clubs by category
  Future<List<Map<String, dynamic>>> getClubsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('clubs')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting clubs by category: $e');
      return [];
    }
  }

  /// Search clubs by name
  Future<List<Map<String, dynamic>>> searchClubs(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('clubs')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = data['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      })
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      })
          .toList();
    } catch (e) {
      debugPrint('Error searching clubs: $e');
      return [];
    }
  }

  /// Get club by ID
  Future<Map<String, dynamic>?> getClub(String clubId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('clubs').doc(clubId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting club: $e');
      return null;
    }
  }

  // ============================================
  // USER DATA
  // ============================================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile fields
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  /// Update user interests
  Future<bool> updateUserInterests(String userId, List<String> interests) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'interests': interests,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating interests: $e');
      return false;
    }
  }

  // ============================================
  // REGISTRATIONS
  // ============================================

  /// Get user's event registrations
  Future<List<Map<String, dynamic>>> getUserRegistrations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> registrations = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> regData = doc.data() as Map<String, dynamic>;
        final regStatus = regData['status'] as String? ?? 'registered';
        if (regStatus == 'cancelled') continue;

        String eventId = regData['eventId'];
        Map<String, dynamic>? eventData = await getEvent(eventId);

        if (eventData != null) {
          eventData['registrationId'] = doc.id;
          eventData['registrationStatus'] = regStatus;
          eventData['registeredAt'] = regData['registeredAt'];
          registrations.add(eventData);
        }
      }

      return registrations;
    } catch (e) {
      debugPrint('Error getting user registrations: $e');
      return [];
    }
  }

  /// Register for event
  Future<Map<String, dynamic>> registerForEvent(String userId, String eventId) async {
    try {
      QuerySnapshot existing = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'registered')
          .get();

      if (existing.docs.isNotEmpty) {
        return {'success': false, 'message': 'Already registered for this event'};
      }

      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;

      if (eventData['status'] == 'cancelled') {
        return {'success': false, 'message': 'This event has been cancelled'};
      }

      final eventDate = (eventData['date'] as Timestamp?)?.toDate();
      if (eventDate != null && !eventDate.isAfter(DateTime.now())) {
        return {'success': false, 'message': 'This event has already passed'};
      }

      final deadline = (eventData['registrationDeadline'] as Timestamp?)?.toDate();
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        return {'success': false, 'message': 'Registration deadline has passed'};
      }

      int capacity = eventData['capacity'] ?? 0;
      int currentRegistrations = eventData['currentRegistrations'] ?? 0;

      if (currentRegistrations >= capacity) {
        return {'success': false, 'message': 'Event is full'};
      }

      await _firestore.collection('registrations').add({
        'userId': userId,
        'eventId': eventId,
        'status': 'registered',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('events').doc(eventId).update({
        'currentRegistrations': FieldValue.increment(1),
      });

      return {'success': true, 'message': 'Successfully registered for event!'};
    } catch (e) {
      debugPrint('Error registering for event: $e');
      return {'success': false, 'message': 'Failed to register. Please try again.'};
    }
  }

  /// Get all registrants for an event
  Future<List<Map<String, dynamic>>> getEventRegistrants(String eventId) async {
    try {
      final snap = await _firestore
          .collection('registrations')
          .where('eventId', isEqualTo: eventId)
          .get();

      final List<Map<String, dynamic>> result = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'registered';
        if (status == 'cancelled') continue;
        final userData = await getUserProfile(data['userId'] ?? '');
        result.add({
          'registrationId': doc.id,
          'userId': data['userId'] ?? '',
          'userName': userData?['name'] ?? 'Unknown',
          'userEmail': userData?['email'] ?? '',
          'status': status,
          'registeredAt': data['registeredAt'],
          'attendedAt': data['attendedAt'],
          'eventId': data['eventId'], // Added eventId here
        });
      }
      return result;
    } catch (e) {
      debugPrint('Error getting event registrants: $e');
      return [];
    }
  }

  /// Mark a registration as attended
  Future<bool> markAttended(String registrationId, String eventId) async {
    try {
      final batch = _firestore.batch();
      
      // Update registration status
      batch.update(_firestore.collection('registrations').doc(registrationId), {
        'status': 'attended',
        'attendedAt': FieldValue.serverTimestamp(),
      });

      // Increment actual attendance in events collection
      batch.update(_firestore.collection('events').doc(eventId), {
        'actualAttendance': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking attended: $e');
      return false;
    }
  }

  /// Unmark attendance
  Future<bool> unmarkAttended(String registrationId, String eventId) async {
    try {
      final batch = _firestore.batch();

      // Update registration status back to registered
      batch.update(_firestore.collection('registrations').doc(registrationId), {
        'status': 'registered',
        'attendedAt': FieldValue.delete(),
      });

      // Decrement actual attendance in events collection
      batch.update(_firestore.collection('events').doc(eventId), {
        'actualAttendance': FieldValue.increment(-1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error unmarking attended: $e');
      return false;
    }
  }

  /// Cancel event registration
  Future<Map<String, dynamic>> cancelRegistration(String userId, String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'registered')
          .get();

      if (snapshot.docs.isEmpty) {
        return {'success': false, 'message': 'Registration not found'};
      }

      await _firestore.collection('registrations').doc(snapshot.docs.first.id).update({
        'status': 'cancelled',
      });

      await _firestore.collection('events').doc(eventId).update({
        'currentRegistrations': FieldValue.increment(-1),
      });

      return {'success': true, 'message': 'Registration cancelled successfully'};
    } catch (e) {
      debugPrint('Error cancelling registration: $e');
      return {'success': false, 'message': 'Failed to cancel. Please try again.'};
    }
  }

  // ============================================
  // FEEDBACK
  // ============================================

  /// Count how many feedback docs this user has submitted
  Future<int> getFeedbackCount(String userId) async {
    try {
      final snap = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('Error getting feedback count: $e');
      return 0;
    }
  }

  /// Get user's submitted feedback with event details
  Future<List<Map<String, dynamic>>> getUserFeedback(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> feedbackList = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['feedbackId'] = doc.id;

        if (data.containsKey('eventTitle') && data['eventTitle'] != null) {
        } else {
          String eventId = data['eventId'] ?? '';
          if (eventId.isNotEmpty) {
            Map<String, dynamic>? eventData = await getEvent(eventId);
            data['eventTitle'] = eventData?['title'] ?? 'Unknown Event';
          } else {
            data['eventTitle'] = 'Unknown Event';
          }
        }

        feedbackList.add(data);
      }

      return feedbackList;
    } catch (e) {
      debugPrint('Error getting user feedback: $e');
      return [];
    }
  }

  /// Get feedback for a specific event
  Future<List<Map<String, dynamic>>> getEventFeedback(String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('feedback')
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['feedbackId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting event feedback: $e');
      return [];
    }
  }

  /// Submit feedback for an attended event
  Future<bool> submitFeedback({
    required String userId,
    required String eventId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'eventId': eventId,
        'rating': rating,
        'comment': comment.trim(),
        'sentimentLabel': null,
        'sentimentScore': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  /// Check if user has already submitted feedback for an event
  Future<bool> hasSubmittedFeedback(String userId, String eventId) async {
    try {
      final snap = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // MEMBERSHIPS
  // ============================================

  /// Get user's club memberships
  Future<List<Map<String, dynamic>>> getUserClubs(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      List<Map<String, dynamic>> clubs = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        String clubId = memberData['clubId'];

        Map<String, dynamic>? clubData = await getClub(clubId);

        if (clubData != null) {
          clubData['membershipId'] = doc.id;
          clubData['joinedAt'] = memberData['approvedAt'];
          clubs.add(clubData);
        }
      }

      return clubs;
    } catch (e) {
      debugPrint('Error getting user clubs: $e');
      return [];
    }
  }

  /// Get membership status for a user in a club
  Future<String> getMembershipStatus(String userId, String clubId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return 'none';
      return (snap.docs.first.data() as Map<String, dynamic>)['status'] ?? 'none';
    } catch (e) {
      return 'none';
    }
  }

  /// Leave an approved club or cancel a pending request
  Future<Map<String, dynamic>> leaveClub(String userId, String clubId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return {'success': false, 'message': 'Membership not found'};

      final doc = snap.docs.first;
      final status = (doc.data() as Map<String, dynamic>)['status'];

      await doc.reference.delete();

      if (status == 'approved') {
        await _firestore.collection('clubs').doc(clubId).update({
          'memberCount': FieldValue.increment(-1),
        });
        return {'success': true, 'message': 'You have left the club'};
      }

      return {'success': true, 'message': 'Membership request cancelled'};
    } catch (e) {
      debugPrint('Error leaving club: $e');
      return {'success': false, 'message': 'Failed. Please try again.'};
    }
  }

  /// Get pending membership requests for a club
  Future<List<Map<String, dynamic>>> getPendingRequests(String clubId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection('memberships')
          .where('clubId', isEqualTo: clubId)
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];
      for (var doc in snap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['membershipId'] = doc.id;
        Map<String, dynamic>? userData = await getUserProfile(data['userId']);
        data['userName'] = userData?['name'] ?? 'Unknown User';
        data['userEmail'] = userData?['email'] ?? '';
        requests.add(data);
      }
      return requests;
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get approved members of a club
  Future<List<Map<String, dynamic>>> getClubMembers(String clubId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection('memberships')
          .where('clubId', isEqualTo: clubId)
          .where('status', isEqualTo: 'approved')
          .get();

      List<Map<String, dynamic>> members = [];
      for (var doc in snap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['membershipId'] = doc.id;
        Map<String, dynamic>? userData = await getUserProfile(data['userId']);
        data['userName'] = userData?['name'] ?? 'Unknown User';
        data['userEmail'] = userData?['email'] ?? '';
        members.add(data);
      }
      return members;
    } catch (e) {
      debugPrint('Error getting club members: $e');
      return [];
    }
  }

  /// Approve a membership request
  Future<Map<String, dynamic>> approveMembership(String membershipId, String clubId) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('clubs').doc(clubId).update({
        'memberCount': FieldValue.increment(1),
      });
      return {'success': true, 'message': 'Member approved!'};
    } catch (e) {
      debugPrint('Error approving membership: $e');
      return {'success': false, 'message': 'Failed to approve.'};
    }
  }

  /// Reject a membership request
  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).update({
        'status': 'rejected',
      });
      return {'success': true, 'message': 'Request rejected'};
    } catch (e) {
      debugPrint('Error rejecting membership: $e');
      return {'success': false, 'message': 'Failed to reject.'};
    }
  }

  /// Remove an approved member from a club
  Future<Map<String, dynamic>> removeMember(String membershipId, String clubId) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).delete();
      await _firestore.collection('clubs').doc(clubId).update({
        'memberCount': FieldValue.increment(-1),
      });
      return {'success': true, 'message': 'Member removed'};
    } catch (e) {
      debugPrint('Error removing member: $e');
      return {'success': false, 'message': 'Failed to remove member.'};
    }
  }

  /// Request to join club
  Future<Map<String, dynamic>> joinClub(String userId, String clubId) async {
    try {
      QuerySnapshot existing = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .get();

      if (existing.docs.isNotEmpty) {
        Map<String, dynamic> memberData = existing.docs.first.data() as Map<String, dynamic>;
        String status = memberData['status'];

        if (status == 'approved') {
          return {'success': false, 'message': 'Already a member of this club'};
        } else if (status == 'pending') {
          return {'success': false, 'message': 'Membership request is pending approval'};
        }
      }

      await _firestore.collection('memberships').add({
        'userId': userId,
        'clubId': clubId,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Membership request sent! Awaiting approval.'};
    } catch (e) {
      debugPrint('Error joining club: $e');
      return {'success': false, 'message': 'Failed to join club. Please try again.'};
    }
  }
}
