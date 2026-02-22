import 'package:cloud_firestore/cloud_firestore.dart';

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
      print('Error getting upcoming events: $e');
      return [];
    }
  }

  /// Get past events
  Future<List<Map<String, dynamic>>> getPastEvents({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting past events: $e');
      return [];
    }
  }

  /// Search events by title or category
  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      // Note: For production, use Algolia or similar for better search
      // This is a simple firestore query limitation workaround
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
      print('Error searching events: $e');
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
      print('Error getting events by category: $e');
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
      print('Error getting event: $e');
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
      print('Error getting clubs: $e');
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
      print('Error getting clubs by category: $e');
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
      print('Error searching clubs: $e');
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
      print('Error getting club: $e');
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
      print('Error getting user profile: $e');
      return null;
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
      print('Error updating interests: $e');
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
          .where('status', isEqualTo: 'registered')
          .get();

      // Get full event details for each registration
      List<Map<String, dynamic>> registrations = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> regData = doc.data() as Map<String, dynamic>;
        String eventId = regData['eventId'];
        
        // Get event details
        Map<String, dynamic>? eventData = await getEvent(eventId);
        
        if (eventData != null) {
          eventData['registrationId'] = doc.id;
          eventData['registeredAt'] = regData['registeredAt'];
          registrations.add(eventData);
        }
      }

      return registrations;
    } catch (e) {
      print('Error getting user registrations: $e');
      return [];
    }
  }

  /// Register for event
  Future<Map<String, dynamic>> registerForEvent(String userId, String eventId) async {
    try {
      // Check if already registered
      QuerySnapshot existing = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (existing.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Already registered for this event',
        };
      }

      // Check event capacity
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      
      int capacity = eventData['capacity'] ?? 0;
      int currentRegistrations = eventData['currentRegistrations'] ?? 0;

      if (currentRegistrations >= capacity) {
        return {
          'success': false,
          'message': 'Event is full',
        };
      }

      // Create registration
      await _firestore.collection('registrations').add({
        'userId': userId,
        'eventId': eventId,
        'status': 'registered',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      // Increment event registration count
      await _firestore.collection('events').doc(eventId).update({
        'currentRegistrations': FieldValue.increment(1),
      });

      return {
        'success': true,
        'message': 'Successfully registered for event!',
      };
    } catch (e) {
      print('Error registering for event: $e');
      return {
        'success': false,
        'message': 'Failed to register. Please try again.',
      };
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
        return {
          'success': false,
          'message': 'Registration not found',
        };
      }

      // Update registration status
      await _firestore.collection('registrations').doc(snapshot.docs.first.id).update({
        'status': 'cancelled',
      });

      // Decrement event registration count
      await _firestore.collection('events').doc(eventId).update({
        'currentRegistrations': FieldValue.increment(-1),
      });

      return {
        'success': true,
        'message': 'Registration cancelled successfully',
      };
    } catch (e) {
      print('Error cancelling registration: $e');
      return {
        'success': false,
        'message': 'Failed to cancel. Please try again.',
      };
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

      // Get full club details
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
      print('Error getting user clubs: $e');
      return [];
    }
  }

  /// Request to join club
  Future<Map<String, dynamic>> joinClub(String userId, String clubId) async {
    try {
      // Check if already a member or pending
      QuerySnapshot existing = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .get();

      if (existing.docs.isNotEmpty) {
        Map<String, dynamic> memberData = existing.docs.first.data() as Map<String, dynamic>;
        String status = memberData['status'];
        
        if (status == 'approved') {
          return {
            'success': false,
            'message': 'Already a member of this club',
          };
        } else if (status == 'pending') {
          return {
            'success': false,
            'message': 'Membership request is pending approval',
          };
        }
      }

      // Create membership request
      await _firestore.collection('memberships').add({
        'userId': userId,
        'clubId': clubId,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Membership request sent! Awaiting approval.',
      };
    } catch (e) {
      print('Error joining club: $e');
      return {
        'success': false,
        'message': 'Failed to join club. Please try again.',
      };
    }
  }
}