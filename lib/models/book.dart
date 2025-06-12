import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final List<String> genres;
  final double rating;
  final int reviewCount;
  final int pageCount;
  final String isbn;
  final DateTime publishedDate;
  final String publisher;
  final String language;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final List<String> awards; // Book awards and honors
  final String? series; // Book series name
  final int? seriesNumber; // Position in series
  final double? averageReadingTime; // In hours
  final List<String> similarBooks; // IDs of similar books
  final List<String> relatedAuthors; // Related author names
  final bool isAvailable; // Whether book is available for reading
  final DateTime? lastUpdated;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.genres,
    required this.rating,
    required this.reviewCount,
    required this.pageCount,
    required this.isbn,
    required this.publishedDate,
    required this.publisher,
    required this.language,
    required this.tags,
    required this.metadata,
    this.awards = const [],
    this.series,
    this.seriesNumber,
    this.averageReadingTime,
    this.similarBooks = const [],
    this.relatedAuthors = const [],
    this.isAvailable = true,
    this.lastUpdated,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null for book ${doc.id}');
    }

    return Book(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      coverUrl: data['coverUrl']?.toString() ?? '',
      genres: List<String>.from(data['genres'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      pageCount: (data['pageCount'] ?? 0).toInt(),
      isbn: data['isbn']?.toString() ?? '',
      publishedDate:
          data['publishedDate'] != null
              ? (data['publishedDate'] as Timestamp).toDate()
              : DateTime.now(),
      publisher: data['publisher']?.toString() ?? '',
      language: data['language']?.toString() ?? 'English',
      tags: List<String>.from(data['tags'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      awards: List<String>.from(data['awards'] ?? []),
      series: data['series']?.toString(),
      seriesNumber: data['seriesNumber']?.toInt(),
      averageReadingTime: data['averageReadingTime']?.toDouble(),
      similarBooks: List<String>.from(data['similarBooks'] ?? []),
      relatedAuthors: List<String>.from(data['relatedAuthors'] ?? []),
      isAvailable: data['isAvailable'] != false,
      lastUpdated:
          data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'genres': genres,
      'rating': rating,
      'reviewCount': reviewCount,
      'pageCount': pageCount,
      'isbn': isbn,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'publisher': publisher,
      'language': language,
      'tags': tags,
      'metadata': metadata,
      'awards': awards,
      'series': series,
      'seriesNumber': seriesNumber,
      'averageReadingTime': averageReadingTime,
      'similarBooks': similarBooks,
      'relatedAuthors': relatedAuthors,
      'isAvailable': isAvailable,
      'lastUpdated': Timestamp.fromDate(lastUpdated ?? DateTime.now()),
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>{};

    // Prioritize title words - add both individual words and the full title
    final titleWords = title.toLowerCase().split(' ');
    keywords.addAll(titleWords);

    // Add the full title for exact searches
    keywords.add(title.toLowerCase());

    // Add partial title combinations for better matching
    for (int i = 0; i < titleWords.length; i++) {
      for (int j = i + 1; j <= titleWords.length; j++) {
        final phrase = titleWords.sublist(i, j).join(' ');
        if (phrase.length >= 3) {
          keywords.add(phrase);
        }
      }
    }

    // Add author words (secondary priority)
    keywords.addAll(author.toLowerCase().split(' '));
    keywords.add(author.toLowerCase());

    // Add genres (lower priority)
    keywords.addAll(genres.map((g) => g.toLowerCase()));

    // Add tags (lower priority)
    keywords.addAll(tags.map((t) => t.toLowerCase()));

    // Add publisher (lower priority)
    keywords.addAll(publisher.toLowerCase().split(' '));

    // Add series if available (lower priority)
    if (series != null) {
      keywords.addAll(series!.toLowerCase().split(' '));
      keywords.add(series!.toLowerCase());
    }

    // Remove empty strings and very short words (but keep important 2-letter words)
    keywords.removeWhere(
      (keyword) =>
          keyword.isEmpty ||
          (keyword.length == 1) ||
          (keyword.length == 2 && !RegExp(r'^[a-z]{2}$').hasMatch(keyword)),
    );

    return keywords.toList();
  }

  String get displayTitle {
    if (series != null && seriesNumber != null) {
      return '$title ($series #$seriesNumber)';
    } else if (series != null) {
      return '$title ($series)';
    }
    return title;
  }

  String get readingTimeText {
    if (averageReadingTime == null) return '';
    final hours = averageReadingTime!.floor();
    final minutes = ((averageReadingTime! % 1) * 60).round();
    if (hours == 0) {
      return '${minutes}min read';
    } else if (minutes == 0) {
      return '${hours}h read';
    } else {
      return '${hours}h ${minutes}min read';
    }
  }

  bool get isPartOfSeries => series != null;

  bool get hasAwards => awards.isNotEmpty;
}
