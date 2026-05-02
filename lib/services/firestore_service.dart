import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // EVENTS
  // ============================================

  Future<Set<String>> _getActiveClubIds() async {
    final snapshot = await _firestore
        .collection('clubs')
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Future<List<Map<String, dynamic>>> getUpcomingEvents({int limit = 20}) async {
    try {
      final activeClubIds = await _getActiveClubIds();

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
      }).where((data) => activeClubIds.contains(data['clubId'])).toList();
    } catch (e) {
      debugPrint('Error getting upcoming events: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPastEvents({int limit = 20}) async {
    try {
      final activeClubIds = await _getActiveClubIds();

      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('date', isLessThan: Timestamp.now())
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).where((data) =>
          data['status'] != 'cancelled' &&
          activeClubIds.contains(data['clubId'])).toList();
    } catch (e) {
      debugPrint('Error getting past events: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      final activeClubIds = await _getActiveClubIds();

      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'upcoming')
          .get();

      return snapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String title = data['title']?.toLowerCase() ?? '';
        String category = data['category']?.toLowerCase() ?? '';
        return (title.contains(query.toLowerCase()) || category.contains(query.toLowerCase()))
            && activeClubIds.contains(data['clubId']);
      }).map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

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
      return null;
    }
  }

  // ============================================
  // CLUBS
  // ============================================

  Future<List<Map<String, dynamic>>> getClubs({int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('clubs')
          .where('status', isEqualTo: 'active')
          .limit(limit)
          .get();
      final results = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchClubs(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('clubs')
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase());
      }).map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

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
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserClubs(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      List<Map<String, dynamic>> clubs = [];
      for (var doc in snapshot.docs) {
        final clubId = (doc.data() as Map<String, dynamic>)['clubId'];
        final clubData = await getClub(clubId);
        if (clubData != null) {
          clubs.add(clubData);
        }
      }
      return clubs;
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // REGISTRATIONS & ATTENDANCE
  // ============================================

  Future<List<Map<String, dynamic>>> getUserRegistrations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .get();

      // Deduplicate: keep the latest non-cancelled registration per event
      final Map<String, Map<String, dynamic>> latestByEvent = {};
      for (var doc in snapshot.docs) {
        final regData = doc.data() as Map<String, dynamic>;
        if (regData['status'] == 'cancelled') continue;
        final eventId = regData['eventId'] as String? ?? '';
        if (eventId.isEmpty) continue;

        final existing = latestByEvent[eventId];
        if (existing == null) {
          latestByEvent[eventId] = {...regData, 'docId': doc.id};
        } else {
          // Prefer 'attended' over 'registered'; otherwise keep whichever is later
          final existingStatus = existing['status'] ?? '';
          final newStatus = regData['status'] ?? '';
          if (newStatus == 'attended' && existingStatus != 'attended') {
            latestByEvent[eventId] = {...regData, 'docId': doc.id};
          }
        }
      }

      List<Map<String, dynamic>> results = [];
      for (final entry in latestByEvent.entries) {
        final regData = entry.value;
        final eventData = await getEvent(entry.key);
        if (eventData != null) {
          results.add({
            ...eventData,
            'registrationId': regData['docId'],
            'registrationStatus': regData['status'] ?? 'registered',
            'registeredAt': regData['registeredAt'],
          });
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventRegistrants(String eventId) async {
    try {
      final snap = await _firestore
          .collection('registrations')
          .where('eventId', isEqualTo: eventId)
          .get();

      List<Map<String, dynamic>> registrants = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;
        final userProfile = await getUserProfile(data['userId']);
        registrants.add({
          ...data,
          'registrationId': doc.id,
          'userName': userProfile?['name'] ?? 'Unknown User',
          'userEmail': userProfile?['email'] ?? '',
        });
      }
      return registrants;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> registerForEvent(String userId, String eventId) async {
    try {
      DocumentReference eventRef = _firestore.collection('events').doc(eventId);
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot eventDoc = await transaction.get(eventRef);
        int current = (eventDoc.data() as Map<String, dynamic>)['currentRegistrations'] ?? 0;
        int capacity = (eventDoc.data() as Map<String, dynamic>)['capacity'] ?? 0;

        if (current >= capacity) return {'success': false, 'message': 'Event is full'};

        transaction.set(_firestore.collection('registrations').doc(), {
          'userId': userId,
          'eventId': eventId,
          'status': 'registered',
          'registeredAt': FieldValue.serverTimestamp(),
        });
        transaction.update(eventRef, {'currentRegistrations': FieldValue.increment(1)});
        return {'success': true, 'message': 'Registered successfully!'};
      });
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelRegistration(String userId, String eventId) async {
    try {
      QuerySnapshot snap = await _firestore.collection('registrations')
          .where('userId', isEqualTo: userId).where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'registered').limit(1).get();
      if (snap.docs.isEmpty) return {'success': false, 'message': 'No registration found'};
      await snap.docs.first.reference.update({'status': 'cancelled'});
      await _firestore.collection('events').doc(eventId).update({'currentRegistrations': FieldValue.increment(-1)});
      return {'success': true, 'message': 'Cancelled successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<bool> markAttended(String registrationId, String eventId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('registrations').doc(registrationId), {'status': 'attended', 'attendedAt': FieldValue.serverTimestamp()});
      batch.update(_firestore.collection('events').doc(eventId), {'actualAttendance': FieldValue.increment(1)});
      await batch.commit();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> unmarkAttended(String registrationId, String eventId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('registrations').doc(registrationId), {'status': 'registered', 'attendedAt': FieldValue.delete()});
      batch.update(_firestore.collection('events').doc(eventId), {'actualAttendance': FieldValue.increment(-1)});
      await batch.commit();
      return true;
    } catch (e) { return false; }
  }

  // ============================================
  // FEEDBACK & SENTIMENT
  // ============================================

  Future<int> getFeedbackCount(String userId) async {
    final snap = await _firestore.collection('feedback').where('userId', isEqualTo: userId).count().get();
    return snap.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getUserFeedback(String userId) async {
    final snap = await _firestore.collection('feedback').where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => {...doc.data(), 'feedbackId': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getEventFeedback(String eventId) async {
    final snap = await _firestore.collection('feedback').where('eventId', isEqualTo: eventId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => {...doc.data(), 'feedbackId': doc.id}).toList();
  }

  Future<bool> hasSubmittedFeedback(String userId, String eventId) async {
    final snap = await _firestore.collection('feedback').where('userId', isEqualTo: userId).where('eventId', isEqualTo: eventId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getFeedbackForEvent(String userId, String eventId) async {
    final snap = await _firestore.collection('feedback').where('userId', isEqualTo: userId).where('eventId', isEqualTo: eventId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return {...snap.docs.first.data(), 'feedbackId': snap.docs.first.id};
  }

  Future<bool> submitFeedback({required String userId, required String eventId, required int rating, required String comment}) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'eventId': eventId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'sentimentLabel': null
      });
      return true;
    } catch (e) { return false; }
  }

  // ============================================
  // MEMBERSHIPS
  // ============================================

  Future<String> getMembershipStatus(String userId, String clubId) async {
    final snap = await _firestore.collection('memberships').where('userId', isEqualTo: userId).where('clubId', isEqualTo: clubId).limit(1).get();
    return snap.docs.isEmpty ? 'none' : (snap.docs.first.data()['status'] ?? 'none');
  }

  Future<List<Map<String, dynamic>>> getPendingRequests(String clubId) async {
    try {
      final snap = await _firestore.collection('memberships').where('clubId', isEqualTo: clubId).where('status', isEqualTo: 'pending').get();
      List<Map<String, dynamic>> requests = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final user = await getUserProfile(data['userId']);
        requests.add({
          ...data,
          'membershipId': doc.id,
          'userName': user?['name'] ?? 'Unknown User',
          'userEmail': user?['email'] ?? '',
        });
      }
      return requests;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getClubMembers(String clubId) async {
    try {
      final snap = await _firestore.collection('memberships').where('clubId', isEqualTo: clubId).where('status', isEqualTo: 'approved').get();
      List<Map<String, dynamic>> members = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final user = await getUserProfile(data['userId']);
        members.add({
          ...data,
          'membershipId': doc.id,
          'userName': user?['name'] ?? 'Unknown User',
          'userEmail': user?['email'] ?? '',
        });
      }
      return members;
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> approveMembership(String membershipId, String clubId) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).update({'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()});
      await _firestore.collection('clubs').doc(clubId).update({'memberCount': FieldValue.increment(1)});
      return {'success': true};
    } catch (e) { return {'success': false}; }
  }

  Future<Map<String, dynamic>> rejectMembership(String membershipId) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).update({'status': 'rejected'});
      return {'success': true};
    } catch (e) { return {'success': false}; }
  }

  Future<Map<String, dynamic>> removeMember(String membershipId, String clubId) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).delete();
      await _firestore.collection('clubs').doc(clubId).update({'memberCount': FieldValue.increment(-1)});
      return {'success': true};
    } catch (e) { return {'success': false}; }
  }

  Future<Map<String, dynamic>> joinClub(String userId, String clubId) async {
    try {
      await _firestore.collection('memberships').add({'userId': userId, 'clubId': clubId, 'status': 'pending', 'requestedAt': FieldValue.serverTimestamp()});
      return {'success': true, 'message': 'Request sent!'};
    } catch (e) { return {'success': false, 'message': 'Error.'}; }
  }

  Future<Map<String, dynamic>> leaveClub(String userId, String clubId) async {
    try {
      final snap = await _firestore.collection('memberships').where('userId', isEqualTo: userId).where('clubId', isEqualTo: clubId).limit(1).get();
      if (snap.docs.isEmpty) return {'success': false};
      final data = snap.docs.first.data();
      if (data['status'] == 'approved') {
        await _firestore.collection('clubs').doc(clubId).update({'memberCount': FieldValue.increment(-1)});
      }
      await snap.docs.first.reference.delete();
      return {'success': true};
    } catch (e) { return {'success': false}; }
  }

  // ============================================
  // PROFILE & USERS
  // ============================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
      }
      return null;
    } catch (e) { return null; }
  }

  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) { return false; }
  }
}