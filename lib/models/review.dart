import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likes;
  final List<String> dislikes;
  final bool isVerifiedPurchase;
  // Emotion analysis fields
  final String? emotion;
  final double? emotionConfidence;
  final DateTime? emotionAnalyzedAt;

  Review({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.likes,
    required this.dislikes,
    required this.isVerifiedPurchase,
    this.emotion,
    this.emotionConfidence,
    this.emotionAnalyzedAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null for review ${doc.id}');
    }

    return Review(
      id: doc.id,
      bookId: data['bookId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userAvatar: data['userAvatar']?.toString() ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      content: data['content']?.toString() ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      isVerifiedPurchase: data['isVerifiedPurchase'] == true,
      emotion: data['emotion']?.toString(),
      emotionConfidence: data['emotionConfidence']?.toDouble(),
      emotionAnalyzedAt:
          data['emotionAnalyzedAt'] != null
              ? (data['emotionAnalyzedAt'] as Timestamp).toDate()
              : null,
    );
  }

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id']?.toString() ?? '',
      bookId: data['bookId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userAvatar: data['userAvatar']?.toString() ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      content: data['content']?.toString() ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      isVerifiedPurchase: data['isVerifiedPurchase'] == true,
      emotion: data['emotion']?.toString(),
      emotionConfidence: data['emotionConfidence']?.toDouble(),
      emotionAnalyzedAt:
          data['emotionAnalyzedAt'] != null
              ? (data['emotionAnalyzedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likes': likes,
      'dislikes': dislikes,
      'isVerifiedPurchase': isVerifiedPurchase,
      'emotion': emotion,
      'emotionConfidence': emotionConfidence,
      'emotionAnalyzedAt':
          emotionAnalyzedAt != null
              ? Timestamp.fromDate(emotionAnalyzedAt!)
              : null,
    };
  }

  // Helper methods for emotion display
  String get emotionDisplay {
    return emotion ?? 'Unknown';
  }

  String get emotionEmoji {
    if (emotion == null) return '';
    final parts = emotion!.split(' ');
    return parts.length > 1 ? parts.last : '';
  }

  String get emotionName {
    if (emotion == null) return '';
    return emotion!.split(' ').first;
  }

  bool get hasEmotionAnalysis {
    return emotion != null && emotionConfidence != null;
  }

  String get confidenceDisplay {
    if (emotionConfidence == null) return '';
    return '${emotionConfidence!.toStringAsFixed(1)}%';
  }
}
