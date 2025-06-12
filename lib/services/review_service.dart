import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user review count
  Future<int> getUserReviewCount(String? userId) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return 0;

      final snapshot =
          await _firestore
              .collectionGroup('reviews')
              .where('userId', isEqualTo: uid)
              .get();

      return snapshot.docs.length;
    } catch (e) {
      Logger.serviceDebug(
        'ReviewService',
        'Error getting user review count',
        e,
      );
      return 0;
    }
  }

  // Like a review
  Future<void> likeReview({
    required String bookId,
    required String reviewId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final reviewRef = _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .doc(reviewId);

      await _firestore.runTransaction((transaction) async {
        final reviewDoc = await transaction.get(reviewRef);
        if (!reviewDoc.exists) {
          throw Exception('Review not found');
        }

        final data = reviewDoc.data()!;
        final likes = List<String>.from(data['likes'] ?? []);
        final dislikes = List<String>.from(data['dislikes'] ?? []);

        // Remove from dislikes if present
        if (dislikes.contains(user.uid)) {
          dislikes.remove(user.uid);
        }

        // Toggle like
        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
        } else {
          likes.add(user.uid);
        }

        transaction.update(reviewRef, {'likes': likes, 'dislikes': dislikes});
      });
    } catch (e) {
      Logger.serviceDebug('ReviewService', 'Error liking review', e);
      rethrow;
    }
  }

  // Dislike a review
  Future<void> dislikeReview({
    required String bookId,
    required String reviewId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final reviewRef = _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .doc(reviewId);

      await _firestore.runTransaction((transaction) async {
        final reviewDoc = await transaction.get(reviewRef);
        if (!reviewDoc.exists) {
          throw Exception('Review not found');
        }

        final data = reviewDoc.data()!;
        final likes = List<String>.from(data['likes'] ?? []);
        final dislikes = List<String>.from(data['dislikes'] ?? []);

        // Remove from likes if present
        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
        }

        // Toggle dislike
        if (dislikes.contains(user.uid)) {
          dislikes.remove(user.uid);
        } else {
          dislikes.add(user.uid);
        }

        transaction.update(reviewRef, {'likes': likes, 'dislikes': dislikes});
      });
    } catch (e) {
      Logger.serviceDebug('ReviewService', 'Error disliking review', e);
      rethrow;
    }
  }

  // Check if user has liked a review
  Future<bool> hasUserLikedReview({
    required String bookId,
    required String reviewId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewDoc =
          await _firestore
              .collection('books')
              .doc(bookId)
              .collection('reviews')
              .doc(reviewId)
              .get();

      if (!reviewDoc.exists) return false;

      final data = reviewDoc.data()!;
      final likes = List<String>.from(data['likes'] ?? []);
      return likes.contains(user.uid);
    } catch (e) {
      Logger.serviceDebug(
        'ReviewService',
        'Error checking if user liked review',
        e,
      );
      return false;
    }
  }

  // Check if user has disliked a review
  Future<bool> hasUserDislikedReview({
    required String bookId,
    required String reviewId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewDoc =
          await _firestore
              .collection('books')
              .doc(bookId)
              .collection('reviews')
              .doc(reviewId)
              .get();

      if (!reviewDoc.exists) return false;

      final data = reviewDoc.data()!;
      final dislikes = List<String>.from(data['dislikes'] ?? []);
      return dislikes.contains(user.uid);
    } catch (e) {
      Logger.serviceDebug(
        'ReviewService',
        'Error checking if user disliked review',
        e,
      );
      return false;
    }
  }

  // Get user's reviews
  Future<List<Map<String, dynamic>>> getUserReviews(String? userId) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot =
          await _firestore
              .collectionGroup('reviews')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'bookId': data['bookId'], ...data};
      }).toList();
    } catch (e) {
      Logger.serviceDebug('ReviewService', 'Error getting user reviews', e);
      return [];
    }
  }
}
