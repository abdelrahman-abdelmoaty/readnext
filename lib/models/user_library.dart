import 'package:cloud_firestore/cloud_firestore.dart';

enum ReadingStatus {
  wantToRead,
  currentlyReading,
  read,
  dnf, // Did not finish
  onHold, // Paused/On hold
  rereading, // Reading again
}

extension ReadingStatusExtension on ReadingStatus {
  String get displayName {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.currentlyReading:
        return 'Currently Reading';
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.dnf:
        return 'Did Not Finish';
      case ReadingStatus.onHold:
        return 'On Hold';
      case ReadingStatus.rereading:
        return 'Re-reading';
    }
  }

  String get description {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Books you plan to read';
      case ReadingStatus.currentlyReading:
        return 'Books you are currently reading';
      case ReadingStatus.read:
        return 'Books you have completed';
      case ReadingStatus.dnf:
        return 'Books you started but did not finish';
      case ReadingStatus.onHold:
        return 'Books you paused temporarily';
      case ReadingStatus.rereading:
        return 'Books you are reading again';
    }
  }

  int get priority {
    switch (this) {
      case ReadingStatus.currentlyReading:
        return 1;
      case ReadingStatus.rereading:
        return 2;
      case ReadingStatus.onHold:
        return 3;
      case ReadingStatus.wantToRead:
        return 4;
      case ReadingStatus.read:
        return 5;
      case ReadingStatus.dnf:
        return 6;
    }
  }
}

class UserLibrary {
  final String id;
  final String userId;
  final String bookId;
  final ReadingStatus status;
  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool isFavorite;
  final int currentPage;
  final double progress; // 0.0 to 1.0
  final List<String> tags; // Personal tags
  final String? personalNotes;
  final int? personalRating; // 1-5, different from public review
  final DateTime? lastUpdated;
  final DateTime? lastReadAt; // When user last read this book
  final int? estimatedReadingTimeMinutes; // User's estimated reading time

  UserLibrary({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.addedAt,
    this.startedAt,
    this.finishedAt,
    required this.isFavorite,
    required this.currentPage,
    required this.progress,
    required this.tags,
    this.personalNotes,
    this.personalRating,
    this.lastUpdated,
    this.lastReadAt,
    this.estimatedReadingTimeMinutes,
  });

  // Helper methods
  bool get isActivelyReading =>
      status == ReadingStatus.currentlyReading ||
      status == ReadingStatus.rereading;

  bool get isCompleted => status == ReadingStatus.read;

  bool get isInProgress =>
      status == ReadingStatus.currentlyReading ||
      status == ReadingStatus.rereading ||
      status == ReadingStatus.onHold;

  Duration? get timeSinceLastRead {
    if (lastReadAt == null) return null;
    return DateTime.now().difference(lastReadAt!);
  }

  String get statusIcon {
    switch (status) {
      case ReadingStatus.wantToRead:
        return '📚';
      case ReadingStatus.currentlyReading:
        return '📖';
      case ReadingStatus.read:
        return '✅';
      case ReadingStatus.dnf:
        return '⏹️';
      case ReadingStatus.onHold:
        return '⏸️';
      case ReadingStatus.rereading:
        return '🔄';
    }
  }

  factory UserLibrary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null for user library ${doc.id}');
    }

    return UserLibrary(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      bookId: data['bookId']?.toString() ?? '',
      status: ReadingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReadingStatus.wantToRead,
      ),
      addedAt:
          data['addedAt'] != null
              ? (data['addedAt'] as Timestamp).toDate()
              : DateTime.now(),
      startedAt:
          data['startedAt'] != null
              ? (data['startedAt'] as Timestamp).toDate()
              : null,
      finishedAt:
          data['finishedAt'] != null
              ? (data['finishedAt'] as Timestamp).toDate()
              : null,
      isFavorite: data['isFavorite'] == true,
      currentPage: (data['currentPage'] ?? 0).toInt(),
      progress: (data['progress'] ?? 0.0).toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      personalNotes: data['personalNotes']?.toString(),
      personalRating: data['personalRating']?.toInt(),
      lastUpdated:
          data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
              : null,
      lastReadAt:
          data['lastReadAt'] != null
              ? (data['lastReadAt'] as Timestamp).toDate()
              : null,
      estimatedReadingTimeMinutes: data['estimatedReadingTimeMinutes']?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookId': bookId,
      'status': status.name,
      'addedAt': Timestamp.fromDate(addedAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'isFavorite': isFavorite,
      'currentPage': currentPage,
      'progress': progress,
      'tags': tags,
      'personalNotes': personalNotes,
      'personalRating': personalRating,
      'lastUpdated': Timestamp.fromDate(lastUpdated ?? DateTime.now()),
      'lastReadAt': lastReadAt != null ? Timestamp.fromDate(lastReadAt!) : null,
      'estimatedReadingTimeMinutes': estimatedReadingTimeMinutes,
    };
  }

  UserLibrary copyWith({
    String? userId,
    String? bookId,
    ReadingStatus? status,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool? isFavorite,
    int? currentPage,
    double? progress,
    List<String>? tags,
    String? personalNotes,
    int? personalRating,
    DateTime? lastUpdated,
    DateTime? lastReadAt,
    int? estimatedReadingTimeMinutes,
  }) {
    return UserLibrary(
      id: id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      currentPage: currentPage ?? this.currentPage,
      progress: progress ?? this.progress,
      tags: tags ?? this.tags,
      personalNotes: personalNotes ?? this.personalNotes,
      personalRating: personalRating ?? this.personalRating,
      lastUpdated: lastUpdated ?? DateTime.now(),
      lastReadAt: lastReadAt ?? this.lastReadAt,
      estimatedReadingTimeMinutes:
          estimatedReadingTimeMinutes ?? this.estimatedReadingTimeMinutes,
    );
  }
}
