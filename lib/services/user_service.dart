import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error getting user data', e);
      rethrow;
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await getUserData(user.uid);
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error getting current user data', e);
      rethrow;
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error updating user preferences', e);
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
    String? bio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firebase Auth profile
      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
        updateData['name'] = name.trim();
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
        updateData['profilePicture'] = photoURL;
      }

      // Update Firestore document
      if (bio != null) {
        updateData['bio'] = bio.trim();
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error updating user profile', e);
      rethrow;
    }
  }

  // Add book to reading history
  Future<void> addToReadingHistory(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'readingHistory': FieldValue.arrayUnion([
          {'bookId': bookId, 'addedAt': FieldValue.serverTimestamp()},
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error adding to reading history', e);
      rethrow;
    }
  }

  // Remove book from reading history
  Future<void> removeFromReadingHistory(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get current reading history
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final readingHistory = List<Map<String, dynamic>>.from(
        userData['readingHistory'] ?? [],
      );

      // Remove the book from history
      readingHistory.removeWhere((item) => item['bookId'] == bookId);

      await _firestore.collection('users').doc(user.uid).update({
        'readingHistory': readingHistory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.serviceDebug(
        'UserService',
        'Error removing from reading history',
        e,
      );
      rethrow;
    }
  }

  // Add book to favorites
  Future<void> addToFavorites(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'favoriteBooks': FieldValue.arrayUnion([bookId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error adding to favorites', e);
      rethrow;
    }
  }

  // Remove book from favorites
  Future<void> removeFromFavorites(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'favoriteBooks': FieldValue.arrayRemove([bookId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error removing from favorites', e);
      rethrow;
    }
  }

  // Check if book is in favorites
  Future<bool> isBookInFavorites(String bookId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final favoriteBooks = List<String>.from(userData['favoriteBooks'] ?? []);
      return favoriteBooks.contains(bookId);
    } catch (e) {
      Logger.serviceDebug(
        'UserService',
        'Error checking if book is in favorites',
        e,
      );
      return false;
    }
  }

  // Get user's favorite books
  Future<List<String>> getFavoriteBooks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return [];

      return List<String>.from(userData['favoriteBooks'] ?? []);
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error getting favorite books', e);
      return [];
    }
  }

  // Get user's reading history
  Future<List<Map<String, dynamic>>> getReadingHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return [];

      return List<Map<String, dynamic>>.from(userData['readingHistory'] ?? []);
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error getting reading history', e);
      return [];
    }
  }

  // Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user reviews
      final reviewsQuery =
          await _firestore
              .collectionGroup('reviews')
              .where('userId', isEqualTo: user.uid)
              .get();

      final batch = _firestore.batch();
      for (final doc in reviewsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error deleting user account', e);
      rethrow;
    }
  }

  // Update user activity timestamp
  Future<void> updateLastActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error updating last activity', e);
      // Don't rethrow as this is not critical
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error checking if user exists', e);
      return false;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      return userData['isAdmin'] == true;
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error checking admin status', e);
      return false;
    }
  }

  // Check if specific user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      return userData['isAdmin'] == true;
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error checking user admin status', e);
      return false;
    }
  }

  // Set admin status for a user (admin only)
  Future<void> setAdminStatus(String userId, bool isAdmin) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Check if current user is admin
      final isCurrentUserAdmin = await this.isCurrentUserAdmin();
      if (!isCurrentUserAdmin) {
        throw Exception('Only admins can change admin status');
      }

      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.serviceDebug('UserService', 'Admin status updated', {
        'userId': userId,
        'isAdmin': isAdmin,
      });
    } catch (e) {
      Logger.serviceDebug('UserService', 'Error setting admin status', e);
      rethrow;
    }
  }
}
