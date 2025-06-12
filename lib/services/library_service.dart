import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_library.dart';
import '../utils/logger.dart';

class LibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add book to user library
  Future<void> addToLibrary({
    required String userId,
    required String bookId,
    required ReadingStatus status,
    bool isFavorite = false,
    List<String> tags = const [],
    String? personalNotes,
  }) async {
    try {
      // Check if book already exists in user's library
      final existingEntry = await getUserLibraryEntry(
        userId: userId,
        bookId: bookId,
      );

      if (existingEntry != null) {
        // Update existing entry
        await updateLibraryEntry(
          entryId: existingEntry.id,
          status: status,
          isFavorite: isFavorite,
          tags: tags,
          personalNotes: personalNotes,
        );
        return;
      }

      final libraryRef = _firestore.collection('userLibrary').doc();

      final now = DateTime.now();
      final libraryEntry = UserLibrary(
        id: libraryRef.id,
        userId: userId,
        bookId: bookId,
        status: status,
        addedAt: now,
        startedAt: status == ReadingStatus.currentlyReading ? now : null,
        isFavorite: isFavorite,
        currentPage: 0,
        progress: 0.0,
        tags: tags,
        personalNotes: personalNotes,
        lastUpdated: now,
      );

      await libraryRef.set(libraryEntry.toFirestore());

      Logger.serviceDebug('LibraryService', 'Book added to library', {
        'bookId': bookId,
        'status': status.name,
      });
    } catch (e) {
      Logger.serviceDebug('LibraryService', 'Error adding book to library', e);
      rethrow;
    }
  }

  // Add book as favorite without requiring status
  Future<void> addToFavorites({
    required String userId,
    required String bookId,
  }) async {
    try {
      // Check if book already exists in user's library
      final existingEntry = await getUserLibraryEntry(
        userId: userId,
        bookId: bookId,
      );

      if (existingEntry != null) {
        // Just toggle favorite status
        await updateLibraryEntry(entryId: existingEntry.id, isFavorite: true);
        return;
      }

      // Add as favorite with default "want to read" status
      await addToLibrary(
        userId: userId,
        bookId: bookId,
        status: ReadingStatus.wantToRead,
        isFavorite: true,
      );

      Logger.serviceDebug('LibraryService', 'Book added to favorites', {
        'bookId': bookId,
      });
    } catch (e) {
      Logger.serviceDebug(
        'LibraryService',
        'Error adding book to favorites',
        e,
      );
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite({
    required String userId,
    required String bookId,
  }) async {
    try {
      final existingEntry = await getUserLibraryEntry(
        userId: userId,
        bookId: bookId,
      );

      if (existingEntry != null) {
        // Toggle existing favorite status
        await updateLibraryEntry(
          entryId: existingEntry.id,
          isFavorite: !existingEntry.isFavorite,
        );
      } else {
        // Add as favorite if not in library
        await addToFavorites(userId: userId, bookId: bookId);
      }

      Logger.serviceDebug('LibraryService', 'Toggled favorite status', {
        'bookId': bookId,
      });
    } catch (e) {
      Logger.serviceDebug('LibraryService', 'Error toggling favorite', e);
      rethrow;
    }
  }

  // Optimized method to get all user library data in one go
  Future<Map<String, dynamic>> getAllUserLibraryData({
    required String userId,
  }) async {
    try {
      // Get all library entries for the user
      final snapshot =
          await _firestore
              .collection('userLibrary')
              .where('userId', isEqualTo: userId)
              .orderBy('lastUpdated', descending: true)
              .get();

      final allLibrary =
          snapshot.docs.map((doc) => UserLibrary.fromFirestore(doc)).toList();

      return _processLibraryData(allLibrary);
    } catch (e) {
      Logger.serviceDebug(
        'LibraryService',
        'Error getting all library data',
        e,
      );
      rethrow;
    }
  }

  // Process library data into organized collections
  Map<String, dynamic> _processLibraryData(List<UserLibrary> allLibrary) {
    final Map<String, int> stats = {
      'total': allLibrary.length,
      'wantToRead': 0,
      'currentlyReading': 0,
      'read': 0,
      'dnf': 0,
      'onHold': 0,
      'rereading': 0,
      'favorites': 0,
    };

    final List<UserLibrary> currentlyReading = [];
    final List<UserLibrary> wantToRead = [];
    final List<UserLibrary> read = [];
    final List<UserLibrary> dnf = [];
    final List<UserLibrary> onHold = [];
    final List<UserLibrary> rereading = [];
    final List<UserLibrary> favorites = [];

    for (final entry in allLibrary) {
      // Count stats
      stats[entry.status.name] = (stats[entry.status.name] ?? 0) + 1;
      if (entry.isFavorite) {
        stats['favorites'] = (stats['favorites'] ?? 0) + 1;
        favorites.add(entry);
      }

      // Categorize by status
      switch (entry.status) {
        case ReadingStatus.currentlyReading:
          currentlyReading.add(entry);
          break;
        case ReadingStatus.wantToRead:
          wantToRead.add(entry);
          break;
        case ReadingStatus.read:
          read.add(entry);
          break;
        case ReadingStatus.dnf:
          dnf.add(entry);
          break;
        case ReadingStatus.onHold:
          onHold.add(entry);
          break;
        case ReadingStatus.rereading:
          rereading.add(entry);
          break;
      }
    }

    return {
      'allBooks': allLibrary,
      'currentlyReading': currentlyReading,
      'wantToRead': wantToRead,
      'read': read,
      'dnf': dnf,
      'onHold': onHold,
      'rereading': rereading,
      'favorites': favorites,
      'stats': stats,
    };
  }

  // Get user's library with filtering (keeping for backwards compatibility)
  Future<List<UserLibrary>> getUserLibrary({
    required String userId,
    ReadingStatus? status,
    bool? isFavorite,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('userLibrary')
          .where('userId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (isFavorite != null) {
        query = query.where('isFavorite', isEqualTo: isFavorite);
      }

      query = query.orderBy('lastUpdated', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => UserLibrary.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.serviceDebug('LibraryService', 'Error getting user library', e);
      rethrow;
    }
  }

  // Get specific library entry
  Future<UserLibrary?> getUserLibraryEntry({
    required String userId,
    required String bookId,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('userLibrary')
              .where('userId', isEqualTo: userId)
              .where('bookId', isEqualTo: bookId)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;
      return UserLibrary.fromFirestore(snapshot.docs.first);
    } catch (e) {
      Logger.serviceDebug('LibraryService', 'Error getting library entry', e);
      rethrow;
    }
  }

  // Update library entry
  Future<void> updateLibraryEntry({
    required String entryId,
    ReadingStatus? status,
    bool? isFavorite,
    int? currentPage,
    double? progress,
    List<String>? tags,
    String? personalNotes,
    int? personalRating,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (status != null) {
        updateData['status'] = status.name;

        // Auto-set dates based on status
        final now = DateTime.now();
        switch (status) {
          case ReadingStatus.currentlyReading:
            updateData['startedAt'] = Timestamp.fromDate(now);
            break;
          case ReadingStatus.read:
            updateData['finishedAt'] = Timestamp.fromDate(now);
            updateData['progress'] = 1.0;
            break;
          case ReadingStatus.dnf:
            updateData['finishedAt'] = Timestamp.fromDate(now);
            break;
          default:
            break;
        }
      }

      if (isFavorite != null) updateData['isFavorite'] = isFavorite;
      if (currentPage != null) updateData['currentPage'] = currentPage;
      if (progress != null) updateData['progress'] = progress;
      if (tags != null) updateData['tags'] = tags;
      if (personalNotes != null) updateData['personalNotes'] = personalNotes;
      if (personalRating != null) updateData['personalRating'] = personalRating;

      await _firestore
          .collection('userLibrary')
          .doc(entryId)
          .update(updateData);

      Logger.serviceDebug('LibraryService', 'Library entry updated', {
        'entryId': entryId,
      });
    } catch (e) {
      Logger.serviceDebug('LibraryService', 'Error updating library entry', e);
      rethrow;
    }
  }

  // Remove from library by entryId
  Future<void> removeFromLibrary(String entryId) async {
    try {
      await _firestore.collection('userLibrary').doc(entryId).delete();

      Logger.serviceDebug('LibraryService', 'Book removed from library', {
        'entryId': entryId,
      });
    } catch (e) {
      Logger.serviceDebug(
        'LibraryService',
        'Error removing book from library',
        e,
      );
      rethrow;
    }
  }

  // Remove from library by userId and bookId
  Future<void> removeFromLibraryByBook({
    required String userId,
    required String bookId,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('userLibrary')
              .where('userId', isEqualTo: userId)
              .where('bookId', isEqualTo: bookId)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        Logger.serviceDebug('LibraryService', 'Book removed from library', {
          'bookId': bookId,
        });
      }
    } catch (e) {
      Logger.serviceDebug(
        'LibraryService',
        'Error removing book from library',
        e,
      );
      rethrow;
    }
  }

  // Get library statistics (optimized)
  Future<Map<String, int>> getLibraryStats(String userId) async {
    try {
      final data = await getAllUserLibraryData(userId: userId);
      return data['stats'] as Map<String, int>;
    } catch (e) {
      Logger.serviceDebug('LibraryService', 'Error getting library stats', e);
      rethrow;
    }
  }

  // Get recently updated books
  Future<List<UserLibrary>> getRecentlyUpdated({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final data = await getAllUserLibraryData(userId: userId);
      final allBooks = data['allBooks'] as List<UserLibrary>;

      // Sort by lastUpdated and take the limit
      allBooks.sort((a, b) {
        final aDate = a.lastUpdated ?? a.addedAt;
        final bDate = b.lastUpdated ?? b.addedAt;
        return bDate.compareTo(aDate);
      });

      return allBooks.take(limit).toList();
    } catch (e) {
      Logger.serviceDebug(
        'LibraryService',
        'Error getting recently updated books',
        e,
      );
      rethrow;
    }
  }
}
