import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../models/review.dart';
import '../utils/logger.dart';
import 'user_service.dart';
import 'emotion_service.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Get books with pagination and filtering
  Future<List<Book>> getBooks({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? genre,
    String? searchQuery,
    double? minRating,
    int? minReviews,
    String? sortBy,
    bool descending = true,
  }) async {
    try {
      Query query = _firestore.collection('books');

      // Apply filters
      if (genre != null) {
        query = query.where('genres', arrayContains: genre);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // For title-focused search, we'll handle this differently
        // This method will be primarily used with other filters
        query = query.where(
          'searchKeywords',
          arrayContains: searchQuery.toLowerCase(),
        );
      }

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (minReviews != null) {
        query = query.where('reviewCount', isGreaterThanOrEqualTo: minReviews);
      }

      // Apply sorting
      if (sortBy != null) {
        query = query.orderBy(sortBy, descending: descending);
      } else {
        // Default sort by rating and review count
        query = query
            .orderBy('rating', descending: true)
            .orderBy('reviewCount', descending: true);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting books', e);
      rethrow;
    }
  }

  // Get book by ID
  Future<Book?> getBookById(String bookId) async {
    try {
      final doc = await _firestore.collection('books').doc(bookId).get();
      if (!doc.exists) return null;
      return Book.fromFirestore(doc);
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting book by ID', e);
      rethrow;
    }
  }

  // Get book reviews
  Future<List<Review>> getBookReviews({
    required String bookId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting book reviews', e);
      rethrow;
    }
  }

  // Add a review with transaction safety and emotion analysis
  Future<void> addReview({
    required String bookId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String content,
    bool isVerifiedPurchase = false,
    bool analyzeEmotion = true,
  }) async {
    try {
      // Validate inputs
      if (bookId.isEmpty || userId.isEmpty || userName.isEmpty) {
        throw ArgumentError('Required fields cannot be empty');
      }

      if (rating < 0 || rating > 5) {
        throw ArgumentError('Rating must be between 0 and 5');
      }

      if (content.trim().isEmpty) {
        throw ArgumentError('Review content cannot be empty');
      }

      // Analyze emotion if enabled
      EmotionData? emotionData;
      if (analyzeEmotion && content.trim().isNotEmpty) {
        try {
          Logger.serviceDebug('BookService', 'Analyzing emotion for review', {
            'content_length': content.length,
          });
          emotionData = await EmotionService.predictEmotionWithRetry(
            content.trim(),
          );
        } catch (e) {
          Logger.serviceDebug(
            'BookService',
            'Emotion analysis failed, continuing without',
            e,
          );
          // Continue without emotion data if analysis fails
        }
      }

      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final bookRef = _firestore.collection('books').doc(bookId);
        final bookDoc = await transaction.get(bookRef);

        if (!bookDoc.exists) {
          throw Exception('Book not found');
        }

        final book = Book.fromFirestore(bookDoc);

        // Check if user already reviewed this book
        final existingReviewQuery =
            await _firestore
                .collection('books')
                .doc(bookId)
                .collection('reviews')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

        if (existingReviewQuery.docs.isNotEmpty) {
          throw Exception('User has already reviewed this book');
        }

        final reviewRef =
            _firestore
                .collection('books')
                .doc(bookId)
                .collection('reviews')
                .doc();

        final review = Review(
          id: reviewRef.id,
          bookId: bookId,
          userId: userId,
          userName: userName.trim(),
          userAvatar: userAvatar,
          rating: rating,
          content: content.trim(),
          createdAt: DateTime.now(),
          likes: [],
          dislikes: [],
          isVerifiedPurchase: isVerifiedPurchase,
          emotion: emotionData?.emotion,
          emotionConfidence: emotionData?.confidence,
          emotionAnalyzedAt: emotionData != null ? DateTime.now() : null,
        );

        // Add the review
        transaction.set(reviewRef, review.toFirestore());

        // Update book rating and review count
        final newReviewCount = book.reviewCount + 1;
        final newRating =
            ((book.rating * book.reviewCount) + rating) / newReviewCount;

        transaction.update(bookRef, {
          'rating': double.parse(newRating.toStringAsFixed(2)),
          'reviewCount': newReviewCount,
          'lastReviewAt': FieldValue.serverTimestamp(),
        });
      });

      // Log successful emotion analysis if available
      if (emotionData != null) {
        Logger.serviceDebug(
          'BookService',
          'Review added with emotion analysis',
          {
            'emotion': emotionData.emotion,
            'confidence': emotionData.confidence,
          },
        );
      }
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error adding review', e);
      rethrow;
    }
  }

  // Get trending books
  Future<List<Book>> getTrendingBooks({int limit = 20}) async {
    try {
      final snapshot =
          await _firestore
              .collection('books')
              .orderBy('reviewCount', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting trending books', e);
      rethrow;
    }
  }

  // Get new releases
  Future<List<Book>> getNewReleases({int limit = 20}) async {
    try {
      final snapshot =
          await _firestore
              .collection('books')
              .orderBy('publishedDate', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting new releases', e);
      rethrow;
    }
  }

  // Search books by title with fallback to keyword search
  Future<List<Book>> searchBooks({
    required String query,
    int limit = 20,
  }) async {
    try {
      final results = <Book>[];
      final addedBookIds = <String>{};
      final searchTerm = query.toLowerCase().trim();

      if (searchTerm.isEmpty) return results;

      // 1. Search for exact title matches (case-insensitive)
      final exactTitleQuery =
          await _firestore
              .collection('books')
              .where('title', isGreaterThanOrEqualTo: query)
              .where('title', isLessThan: '$query\uf8ff')
              .limit(limit ~/ 3)
              .get();

      for (final doc in exactTitleQuery.docs) {
        final book = Book.fromFirestore(doc);
        if (book.title.toLowerCase().contains(searchTerm)) {
          results.add(book);
          addedBookIds.add(book.id);
        }
      }

      // 2. Search for title word matches using searchKeywords
      if (results.length < limit) {
        final titleWordsQuery =
            await _firestore
                .collection('books')
                .where('searchKeywords', arrayContains: searchTerm)
                .limit(limit)
                .get();

        for (final doc in titleWordsQuery.docs) {
          final book = Book.fromFirestore(doc);
          if (!addedBookIds.contains(book.id)) {
            // Prioritize books where the search term appears in the title
            final titleWords = book.title.toLowerCase().split(' ');
            final hasExactTitleWord = titleWords.any(
              (word) =>
                  word.startsWith(searchTerm) || word.contains(searchTerm),
            );

            if (hasExactTitleWord) {
              results.insert(0, book); // Add to beginning for higher priority
              addedBookIds.add(book.id);
            } else {
              results.add(book);
              addedBookIds.add(book.id);
            }
          }

          if (results.length >= limit) break;
        }
      }

      // Sort results by relevance: exact title matches first, then partial title matches
      results.sort((a, b) {
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();

        // Exact title match gets highest priority
        final aExactMatch = aTitle == searchTerm;
        final bExactMatch = bTitle == searchTerm;
        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;

        // Title starts with search term gets second priority
        final aStartsWith = aTitle.startsWith(searchTerm);
        final bStartsWith = bTitle.startsWith(searchTerm);
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;

        // Title contains search term gets third priority
        final aContains = aTitle.contains(searchTerm);
        final bContains = bTitle.contains(searchTerm);
        if (aContains && !bContains) return -1;
        if (!aContains && bContains) return 1;

        // Finally sort by rating
        return b.rating.compareTo(a.rating);
      });

      return results.take(limit).toList();
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error searching books', e);
      rethrow;
    }
  }

  // Enhanced search that supports both title-focused and general keyword search
  Future<List<Book>> searchBooksByTitle({
    required String titleQuery,
    int limit = 20,
  }) async {
    try {
      final searchTerm = titleQuery.toLowerCase().trim();
      if (searchTerm.isEmpty) return [];

      // Search specifically in title field with better text matching
      final query =
          await _firestore
              .collection('books')
              .where('title', isGreaterThanOrEqualTo: titleQuery)
              .where('title', isLessThan: '$titleQuery\uf8ff')
              .orderBy('title')
              .limit(limit)
              .get();

      final results =
          query.docs
              .map((doc) => Book.fromFirestore(doc))
              .where((book) => book.title.toLowerCase().contains(searchTerm))
              .toList();

      // Sort by relevance: exact match -> starts with -> contains
      results.sort((a, b) {
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();

        if (aTitle == searchTerm && bTitle != searchTerm) return -1;
        if (aTitle != searchTerm && bTitle == searchTerm) return 1;

        if (aTitle.startsWith(searchTerm) && !bTitle.startsWith(searchTerm)) {
          return -1;
        }
        if (!aTitle.startsWith(searchTerm) && bTitle.startsWith(searchTerm)) {
          return 1;
        }

        return a.title.compareTo(b.title);
      });

      return results;
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error searching books by title', e);
      rethrow;
    }
  }

  // Quick title search for autocomplete/suggestions
  Future<List<String>> getBookTitleSuggestions({
    required String partialTitle,
    int limit = 10,
  }) async {
    try {
      final searchTerm = partialTitle.toLowerCase().trim();
      if (searchTerm.isEmpty) return [];

      final query =
          await _firestore
              .collection('books')
              .where('title', isGreaterThanOrEqualTo: partialTitle)
              .where('title', isLessThan: '$partialTitle\uf8ff')
              .orderBy('title')
              .limit(limit * 2) // Get more to filter properly
              .get();

      final suggestions =
          query.docs
              .map((doc) => Book.fromFirestore(doc))
              .where((book) => book.title.toLowerCase().contains(searchTerm))
              .map((book) => book.title)
              .take(limit)
              .toList();

      return suggestions;
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting title suggestions', e);
      rethrow;
    }
  }

  // Admin: Add a new book to the database
  Future<String> addBook({
    required String title,
    required String author,
    required String description,
    required String coverUrl,
    required List<String> genres,
    required int pageCount,
    required DateTime publishedDate,
    String? isbn,
    String? publisher,
    String? language,
  }) async {
    try {
      // Check if current user is admin
      final isAdmin = await _userService.isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can add books');
      }

      // Validate required fields
      if (title.trim().isEmpty) {
        throw ArgumentError('Title cannot be empty');
      }
      if (author.trim().isEmpty) {
        throw ArgumentError('Author cannot be empty');
      }
      if (description.trim().isEmpty) {
        throw ArgumentError('Description cannot be empty');
      }
      if (coverUrl.trim().isEmpty) {
        throw ArgumentError('Cover URL cannot be empty');
      }
      if (genres.isEmpty) {
        throw ArgumentError('At least one genre is required');
      }
      if (pageCount <= 0) {
        throw ArgumentError('Page count must be greater than 0');
      }

      // Create document reference
      final bookRef = _firestore.collection('books').doc();

      // Generate search keywords for better searchability
      final searchKeywords = _generateSearchKeywords(title, author);

      // Create book data
      final bookData = {
        'id': bookRef.id,
        'title': title.trim(),
        'author': author.trim(),
        'description': description.trim(),
        'coverUrl': coverUrl.trim(),
        'genres': genres.map((g) => g.trim()).toList(),
        'pageCount': pageCount,
        'publishedDate': Timestamp.fromDate(publishedDate),
        'isbn': isbn?.trim(),
        'publisher': publisher?.trim(),
        'language': language?.trim() ?? 'English',
        'rating': 0.0,
        'reviewCount': 0,
        'searchKeywords': searchKeywords,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'addedBy': _auth.currentUser?.uid,
      };

      // Add the book
      await bookRef.set(bookData);

      Logger.serviceDebug('BookService', 'Book added successfully', {
        'bookId': bookRef.id,
        'title': title,
        'author': author,
      });

      return bookRef.id;
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error adding book', e);
      rethrow;
    }
  }

  // Admin: Update an existing book
  Future<void> updateBook({
    required String bookId,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    List<String>? genres,
    int? pageCount,
    DateTime? publishedDate,
    String? isbn,
    String? publisher,
    String? language,
  }) async {
    try {
      // Check if current user is admin
      final isAdmin = await _userService.isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can update books');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null && title.trim().isNotEmpty) {
        updateData['title'] = title.trim();
      }
      if (author != null && author.trim().isNotEmpty) {
        updateData['author'] = author.trim();
      }
      if (description != null && description.trim().isNotEmpty) {
        updateData['description'] = description.trim();
      }
      if (coverUrl != null && coverUrl.trim().isNotEmpty) {
        updateData['coverUrl'] = coverUrl.trim();
      }
      if (genres != null && genres.isNotEmpty) {
        updateData['genres'] = genres.map((g) => g.trim()).toList();
      }
      if (pageCount != null && pageCount > 0) {
        updateData['pageCount'] = pageCount;
      }
      if (publishedDate != null) {
        updateData['publishedDate'] = Timestamp.fromDate(publishedDate);
      }
      if (isbn != null) {
        updateData['isbn'] = isbn.trim();
      }
      if (publisher != null) {
        updateData['publisher'] = publisher.trim();
      }
      if (language != null) {
        updateData['language'] = language.trim();
      }

      // Update search keywords if title or author changed
      if (title != null || author != null) {
        final bookDoc = await _firestore.collection('books').doc(bookId).get();
        if (bookDoc.exists) {
          final currentBook = Book.fromFirestore(bookDoc);
          final newTitle = title ?? currentBook.title;
          final newAuthor = author ?? currentBook.author;
          updateData['searchKeywords'] = _generateSearchKeywords(
            newTitle,
            newAuthor,
          );
        }
      }

      await _firestore.collection('books').doc(bookId).update(updateData);

      Logger.serviceDebug('BookService', 'Book updated successfully', {
        'bookId': bookId,
      });
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error updating book', e);
      rethrow;
    }
  }

  // Admin: Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      // Check if current user is admin
      final isAdmin = await _userService.isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can delete books');
      }

      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final bookRef = _firestore.collection('books').doc(bookId);
        final bookDoc = await transaction.get(bookRef);

        if (!bookDoc.exists) {
          throw Exception('Book not found');
        }

        // Delete all reviews for this book
        final reviewsQuery =
            await _firestore
                .collection('books')
                .doc(bookId)
                .collection('reviews')
                .get();

        for (final reviewDoc in reviewsQuery.docs) {
          transaction.delete(reviewDoc.reference);
        }

        // Delete the book
        transaction.delete(bookRef);
      });

      Logger.serviceDebug('BookService', 'Book deleted successfully', {
        'bookId': bookId,
      });
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error deleting book', e);
      rethrow;
    }
  }

  // Helper: Generate search keywords for better searchability
  List<String> _generateSearchKeywords(String title, String author) {
    final keywords = <String>{};

    // Add title words
    final titleWords = title.toLowerCase().split(RegExp(r'\s+'));
    keywords.addAll(titleWords);

    // Add author words
    final authorWords = author.toLowerCase().split(RegExp(r'\s+'));
    keywords.addAll(authorWords);

    // Add partial words for better matching
    for (final word in [...titleWords, ...authorWords]) {
      if (word.length > 3) {
        for (int i = 3; i <= word.length; i++) {
          keywords.add(word.substring(0, i));
        }
      }
    }

    return keywords.toList();
  }

  // Analyze emotions for existing reviews that don't have emotion data
  Future<int> analyzeExistingReviewEmotions({
    String? bookId,
    int? limit,
  }) async {
    try {
      int analyzedCount = 0;
      Query reviewsQuery = _firestore.collectionGroup('reviews');

      // Filter by book if specified
      if (bookId != null) {
        reviewsQuery = reviewsQuery.where('bookId', isEqualTo: bookId);
      }

      // Only get reviews without emotion analysis
      reviewsQuery = reviewsQuery.where('emotion', isNull: true);

      if (limit != null) {
        reviewsQuery = reviewsQuery.limit(limit);
      }

      final reviewsSnapshot = await reviewsQuery.get();

      Logger.serviceDebug('BookService', 'Starting batch emotion analysis', {
        'total_reviews': reviewsSnapshot.docs.length,
      });

      for (final reviewDoc in reviewsSnapshot.docs) {
        try {
          final reviewData = reviewDoc.data() as Map<String, dynamic>;
          final content = reviewData['content']?.toString();

          if (content == null || content.trim().isEmpty) {
            continue;
          }

          // Analyze emotion
          final emotionData = await EmotionService.predictEmotion(content);

          if (emotionData != null) {
            // Update the review with emotion data
            await reviewDoc.reference.update({
              'emotion': emotionData.emotion,
              'emotionConfidence': emotionData.confidence,
              'emotionAnalyzedAt': FieldValue.serverTimestamp(),
            });

            analyzedCount++;

            Logger.serviceDebug('BookService', 'Updated review with emotion', {
              'review_id': reviewDoc.id,
              'emotion': emotionData.emotion,
              'confidence': emotionData.confidence,
            });
          }

          // Add delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          Logger.serviceDebug(
            'BookService',
            'Failed to analyze review emotion',
            {'review_id': reviewDoc.id, 'error': e.toString()},
          );
          // Continue with next review
        }
      }

      Logger.serviceDebug('BookService', 'Batch emotion analysis completed', {
        'analyzed_count': analyzedCount,
        'total_reviews': reviewsSnapshot.docs.length,
      });

      return analyzedCount;
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error in batch emotion analysis', e);
      rethrow;
    }
  }

  // Get emotion statistics for a book's reviews
  Future<Map<String, dynamic>> getBookEmotionStats(String bookId) async {
    try {
      final reviewsSnapshot =
          await _firestore
              .collection('books')
              .doc(bookId)
              .collection('reviews')
              .where('emotion', isNull: false)
              .get();

      final emotionCounts = <String, int>{};
      final emotionConfidences = <String, List<double>>{};
      int totalAnalyzed = 0;

      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final emotion = data['emotion']?.toString();
        final confidence = data['emotionConfidence']?.toDouble();

        if (emotion != null && confidence != null) {
          totalAnalyzed++;

          // Extract emotion name (without emoji)
          final emotionName = emotion.split(' ').first;

          emotionCounts[emotionName] = (emotionCounts[emotionName] ?? 0) + 1;
          emotionConfidences[emotionName] =
              (emotionConfidences[emotionName] ?? [])..add(confidence);
        }
      }

      // Calculate average confidences
      final avgConfidences = <String, double>{};
      emotionConfidences.forEach((emotion, confidences) {
        avgConfidences[emotion] =
            confidences.reduce((a, b) => a + b) / confidences.length;
      });

      return {
        'totalReviews': reviewsSnapshot.docs.length,
        'analyzedReviews': totalAnalyzed,
        'emotionCounts': emotionCounts,
        'avgConfidences': avgConfidences,
        'dominantEmotion':
            emotionCounts.isNotEmpty
                ? emotionCounts.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key
                : null,
      };
    } catch (e) {
      Logger.serviceDebug('BookService', 'Error getting book emotion stats', e);
      rethrow;
    }
  }
}
