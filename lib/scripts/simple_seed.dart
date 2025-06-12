import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import '../services/emotion_service.dart';

class SimpleSeed {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Sample data
  final List<Map<String, dynamic>> _bookData = [
    {
      'title': 'The Great Gatsby',
      'author': 'F. Scott Fitzgerald',
      'description':
          'A classic American novel set in the Jazz Age, exploring themes of wealth, love, and the American Dream.',
      'genres': ['Classic', 'Fiction', 'Literature'],
      'pageCount': 180,
      'isbn': '9780743273565',
      'publisher': 'Scribner',
      'language': 'English',
      'tags': ['Classic', 'American Literature', 'Jazz Age'],
      'awards': ['Modern Library 100 Best Novels'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 3.5,
    },
    {
      'title': 'To Kill a Mockingbird',
      'author': 'Harper Lee',
      'description':
          'A gripping tale of racial injustice and childhood innocence in the American South.',
      'genres': ['Classic', 'Fiction', 'Drama'],
      'pageCount': 376,
      'isbn': '9780061120084',
      'publisher': 'J.B. Lippincott & Co.',
      'language': 'English',
      'tags': ['Classic', 'Social Justice', 'Coming of Age'],
      'awards': ['Pulitzer Prize for Fiction'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 7.2,
    },
    {
      'title': '1984',
      'author': 'George Orwell',
      'description':
          'A dystopian masterpiece about totalitarianism and the dangers of unchecked government power.',
      'genres': ['Dystopian', 'Science Fiction', 'Classic'],
      'pageCount': 328,
      'isbn': '9780451524935',
      'publisher': 'Harcourt Brace Jovanovich',
      'language': 'English',
      'tags': ['Dystopian', 'Political', 'Surveillance'],
      'awards': ['Time\'s 100 Best English-language Novels'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 6.5,
    },
    {
      'title': 'Harry Potter and the Philosopher\'s Stone',
      'author': 'J.K. Rowling',
      'description':
          'The magical beginning of Harry Potter\'s journey at Hogwarts School of Witchcraft and Wizardry.',
      'genres': ['Fantasy', 'Young Adult', 'Adventure'],
      'pageCount': 309,
      'isbn': '9780747532699',
      'publisher': 'Bloomsbury',
      'language': 'English',
      'tags': ['Magic', 'School', 'Adventure', 'Coming of Age'],
      'awards': ['Nestlé Smarties Book Prize'],
      'series': 'Harry Potter',
      'seriesNumber': 1,
      'averageReadingTime': 5.8,
    },
    {
      'title': 'The Hobbit',
      'author': 'J.R.R. Tolkien',
      'description':
          'Bilbo Baggins\' unexpected journey to help dwarves reclaim their homeland from a dragon.',
      'genres': ['Fantasy', 'Adventure', 'Classic'],
      'pageCount': 310,
      'isbn': '9780547928227',
      'publisher': 'Houghton Mifflin',
      'language': 'English',
      'tags': ['Fantasy', 'Adventure', 'Dragons', 'Dwarves'],
      'awards': ['Carnegie Medal'],
      'series': 'Middle-earth',
      'seriesNumber': null,
      'averageReadingTime': 6.0,
    },
    {
      'title': 'Dune',
      'author': 'Frank Herbert',
      'description':
          'An epic science fiction saga set on the desert planet Arrakis, where spice is the most valuable substance.',
      'genres': ['Science Fiction', 'Adventure', 'Epic'],
      'pageCount': 688,
      'isbn': '9780441172719',
      'publisher': 'Ace Books',
      'language': 'English',
      'tags': ['Space Opera', 'Desert', 'Politics', 'Ecology'],
      'awards': ['Hugo Award', 'Nebula Award'],
      'series': 'Dune',
      'seriesNumber': 1,
      'averageReadingTime': 12.5,
    },
    {
      'title': 'The Catcher in the Rye',
      'author': 'J.D. Salinger',
      'description':
          'Holden Caulfield\'s story of alienation and rebellion in post-war America.',
      'genres': ['Classic', 'Coming of Age', 'Fiction'],
      'pageCount': 277,
      'isbn': '9780316769488',
      'publisher': 'Little, Brown and Company',
      'language': 'English',
      'tags': ['Coming of Age', 'Alienation', 'Teen Angst'],
      'awards': ['Time\'s 100 Best English-language Novels'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 5.2,
    },
    {
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'description':
          'Elizabeth Bennet\'s story of love, family, and social class in Regency England.',
      'genres': ['Romance', 'Classic', 'Fiction'],
      'pageCount': 432,
      'isbn': '9780141439518',
      'publisher': 'Penguin Classics',
      'language': 'English',
      'tags': ['Romance', 'Regency', 'Social Class', 'Family'],
      'awards': ['BBC\'s Big Read'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 8.0,
    },
    {
      'title': 'The Lord of the Rings: The Fellowship of the Ring',
      'author': 'J.R.R. Tolkien',
      'description':
          'The epic beginning of Frodo\'s quest to destroy the One Ring and save Middle-earth.',
      'genres': ['Fantasy', 'Adventure', 'Epic'],
      'pageCount': 423,
      'isbn': '9780547928210',
      'publisher': 'Houghton Mifflin',
      'language': 'English',
      'tags': ['Fantasy', 'Epic Quest', 'Ring', 'Middle-earth'],
      'awards': ['International Fantasy Award'],
      'series': 'The Lord of the Rings',
      'seriesNumber': 1,
      'averageReadingTime': 8.5,
    },
    {
      'title': 'Brave New World',
      'author': 'Aldous Huxley',
      'description':
          'A dystopian vision of a future society controlled by technology and conditioning.',
      'genres': ['Dystopian', 'Science Fiction', 'Classic'],
      'pageCount': 268,
      'isbn': '9780060850524',
      'publisher': 'Harper Perennial Modern Classics',
      'language': 'English',
      'tags': ['Dystopian', 'Technology', 'Society', 'Control'],
      'awards': ['Modern Library 100 Best Novels'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 5.0,
    },
    {
      'title': 'The Hitchhiker\'s Guide to the Galaxy',
      'author': 'Douglas Adams',
      'description':
          'A comedic science fiction adventure following Arthur Dent\'s journey through space.',
      'genres': ['Science Fiction', 'Comedy', 'Adventure'],
      'pageCount': 216,
      'isbn': '9780345391803',
      'publisher': 'Del Rey Books',
      'language': 'English',
      'tags': ['Comedy', 'Space Travel', 'Absurd', 'Adventure'],
      'awards': ['Golden Pan Award'],
      'series': 'The Hitchhiker\'s Guide to the Galaxy',
      'seriesNumber': 1,
      'averageReadingTime': 4.0,
    },
    {
      'title': 'One Hundred Years of Solitude',
      'author': 'Gabriel García Márquez',
      'description':
          'The magical realist saga of the Buendía family in the fictional town of Macondo.',
      'genres': ['Magical Realism', 'Classic', 'Literature'],
      'pageCount': 417,
      'isbn': '9780060883287',
      'publisher': 'Harper & Row',
      'language': 'English',
      'tags': ['Magical Realism', 'Family Saga', 'Latin American'],
      'awards': ['Nobel Prize in Literature'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 8.2,
    },
    {
      'title': 'The Shining',
      'author': 'Stephen King',
      'description':
          'A psychological horror novel about a family isolated in a haunted hotel.',
      'genres': ['Horror', 'Thriller', 'Psychological'],
      'pageCount': 447,
      'isbn': '9780307743657',
      'publisher': 'Doubleday',
      'language': 'English',
      'tags': ['Horror', 'Haunted', 'Isolation', 'Psychological'],
      'awards': ['World Fantasy Award nomination'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 8.5,
    },
    {
      'title': 'Jane Eyre',
      'author': 'Charlotte Brontë',
      'description':
          'The story of an orphaned girl who becomes a governess and finds love and independence.',
      'genres': ['Classic', 'Romance', 'Gothic'],
      'pageCount': 507,
      'isbn': '9780141441146',
      'publisher': 'Penguin Classics',
      'language': 'English',
      'tags': ['Gothic', 'Orphan', 'Independence', 'Romance'],
      'awards': ['BBC\'s Big Read'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 9.5,
    },
    {
      'title': 'The Alchemist',
      'author': 'Paulo Coelho',
      'description':
          'A young shepherd\'s journey to find treasure and discover his personal legend.',
      'genres': ['Philosophy', 'Adventure', 'Spirituality'],
      'pageCount': 163,
      'isbn': '9780061122415',
      'publisher': 'HarperOne',
      'language': 'English',
      'tags': ['Journey', 'Dreams', 'Spirituality', 'Self-discovery'],
      'awards': ['Crystal Award'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 3.0,
    },
    {
      'title': 'Fahrenheit 451',
      'author': 'Ray Bradbury',
      'description':
          'A dystopian future where books are banned and "firemen" burn any that are found.',
      'genres': ['Dystopian', 'Science Fiction', 'Classic'],
      'pageCount': 249,
      'isbn': '9781451673319',
      'publisher': 'Simon & Schuster',
      'language': 'English',
      'tags': ['Censorship', 'Books', 'Fire', 'Dystopian'],
      'awards': ['Hugo Award', 'Prometheus Hall of Fame Award'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 4.5,
    },
    {
      'title': 'Crime and Punishment',
      'author': 'Fyodor Dostoevsky',
      'description':
          'The psychological drama of Raskolnikov, a student who commits murder and faces the consequences.',
      'genres': ['Classic', 'Psychological', 'Crime'],
      'pageCount': 671,
      'isbn': '9780143058144',
      'publisher': 'Penguin Classics',
      'language': 'English',
      'tags': ['Psychology', 'Crime', 'Guilt', 'Redemption'],
      'awards': ['One of the greatest novels ever written'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 12.0,
    },
    {
      'title': 'The Handmaid\'s Tale',
      'author': 'Margaret Atwood',
      'description':
          'A dystopian novel about a totalitarian society where women are subjugated.',
      'genres': ['Dystopian', 'Science Fiction', 'Feminism'],
      'pageCount': 311,
      'isbn': '9780385490818',
      'publisher': 'McClelland & Stewart',
      'language': 'English',
      'tags': ['Feminism', 'Totalitarian', 'Reproductive Rights'],
      'awards': ['Arthur C. Clarke Award', 'Governor General\'s Award'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 6.0,
    },
    {
      'title': 'The Girl with the Dragon Tattoo',
      'author': 'Stieg Larsson',
      'description':
          'A journalist and a hacker investigate a wealthy family\'s dark secrets.',
      'genres': ['Thriller', 'Crime', 'Mystery'],
      'pageCount': 590,
      'isbn': '9780307454546',
      'publisher': 'Knopf',
      'language': 'English',
      'tags': ['Hacker', 'Investigation', 'Dark Secrets', 'Sweden'],
      'awards': ['Glass Key Award'],
      'series': 'Millennium',
      'seriesNumber': 1,
      'averageReadingTime': 11.0,
    },
    {
      'title': 'Gone Girl',
      'author': 'Gillian Flynn',
      'description':
          'A psychological thriller about a marriage gone terribly wrong.',
      'genres': ['Thriller', 'Psychological', 'Mystery'],
      'pageCount': 419,
      'isbn': '9780307588371',
      'publisher': 'Crown Publishing',
      'language': 'English',
      'tags': ['Marriage', 'Deception', 'Psychological', 'Unreliable Narrator'],
      'awards': ['Goodreads Choice Award'],
      'series': null,
      'seriesNumber': null,
      'averageReadingTime': 8.0,
    },
  ];

  final List<String> _userNames = [
    'Alex Johnson',
    'Sarah Williams',
    'Michael Brown',
    'Emma Davis',
    'James Wilson',
    'Olivia Miller',
    'William Moore',
    'Sophia Taylor',
    'Benjamin Anderson',
    'Isabella Thomas',
    'Lucas Jackson',
    'Charlotte White',
    'Henry Harris',
    'Amelia Martin',
    'Alexander Thompson',
    'Mia Garcia',
    'Daniel Martinez',
    'Harper Robinson',
    'Matthew Clark',
    'Evelyn Rodriguez',
    'David Lewis',
    'Abigail Lee',
    'Joseph Walker',
    'Emily Hall',
    'Samuel Allen',
    'Elizabeth Young',
    'Christopher King',
    'Madison Wright',
    'Andrew Lopez',
    'Sofia Hill',
    'Joshua Green',
    'Avery Adams',
    'Ryan Baker',
    'Ella Gonzalez',
    'Nicholas Nelson',
    'Scarlett Carter',
    'Jonathan Mitchell',
    'Grace Perez',
    'Christian Roberts',
    'Chloe Turner',
    'Anthony Phillips',
    'Victoria Campbell',
    'Mark Parker',
    'Zoey Evans',
    'Steven Edwards',
    'Penelope Collins',
    'Kenneth Stewart',
    'Nora Sanchez',
    'Paul Morris',
    'Lily Rogers',
  ];

  final List<String> _reviewTexts = [
    // Joy/Happiness reviews
    'An absolutely captivating read that kept me turning pages until the very end!',
    'Beautifully written with complex characters and an engaging plot.',
    'This book changed my perspective on life. Highly recommend!',
    'A masterpiece of storytelling. The author\'s prose is simply magnificent.',
    'Couldn\'t put it down! The plot twists were unexpected and well-executed.',
    'One of the best books I\'ve read this year. Absolutely phenomenal!',
    'The world-building is incredible and the story is gripping from start to finish.',
    'A perfect blend of adventure, emotion, and brilliant writing.',
    'This book made me laugh out loud so many times. Pure joy to read!',
    'Exceptional storytelling with memorable characters that feel real.',
    'What a delightful surprise this book was! Exceeded all my expectations.',
    'I\'m so happy I discovered this author. This book brought me so much joy!',

    // Love/Romance reviews
    'This book made me believe in love again. Such beautiful romance!',
    'The chemistry between the characters is absolutely electric and wonderful.',
    'A heartwarming love story that will make you swoon and smile.',
    'I fell in love with every character in this book. So romantic and touching.',

    // Sadness/Emotional reviews
    'This book made me cry tears of both sadness and joy. Emotionally devastating.',
    'Heartbreaking but beautiful. I need time to recover from this emotional journey.',
    'Prepare yourself for tears. This book will break your heart in the best way.',
    'Such a melancholy and touching story that will stay with me forever.',
    'I\'m still crying thinking about this book. So beautifully sad.',

    // Anger/Frustration reviews
    'This book made me so angry at the injustices portrayed, but in a good way.',
    'Frustrated by some character choices, but that shows great writing.',
    'The antagonist made me furious - which means they were written perfectly.',

    // Fear/Suspense reviews
    'This thriller had me on the edge of my seat, heart pounding with fear!',
    'Genuinely scary and suspenseful. I couldn\'t sleep after reading this.',
    'The tension in this book is incredible - I was terrified and couldn\'t stop reading.',
    'This horror novel gave me chills. Perfectly crafted atmosphere of dread.',

    // Surprise/Wonder reviews
    'The plot twists completely shocked me! Never saw that coming.',
    'What an unexpected journey this book took me on. Full of surprises!',
    'I was amazed by the creativity and originality of this story.',
    'This book surprised me at every turn. Brilliant and unpredictable.',

    // Thoughtful/Contemplative reviews
    'Deep, thought-provoking, and emotionally resonant. A true work of art.',
    'This book made me think deeply about important social issues.',
    'A thought-provoking exploration of human nature and society.',
    'Philosophical and meaningful. This book challenged my worldview.',
    'Made me reflect on my own life choices. Very contemplative read.',

    // Mixed emotions
    'This book put me through every emotion possible. What a rollercoaster!',
    'I laughed, I cried, I got angry - this book has it all emotionally.',
    'Bittersweet ending that left me feeling both satisfied and melancholy.',

    // Disappointment/Neutral
    'Not quite what I expected, but still a decent read overall.',
    'The writing was okay, but the plot felt a bit predictable to me.',
    'An average book. Nothing spectacular, but not bad either.',
    'It was fine. I\'ve read better, but it passed the time adequately.',
  ];

  // Generate random cover URL
  String _generateCoverUrl() {
    final bookId = _random.nextInt(1000) + 1;
    return 'https://picsum.photos/300/450?random=$bookId';
  }

  // Generate random avatar URL
  String _generateAvatarUrl() {
    final userId = _random.nextInt(100) + 1;
    return 'https://i.pravatar.cc/150?img=$userId';
  }

  // Generate search keywords for a book
  List<String> _generateSearchKeywords(
    String title,
    String author,
    List<String> genres,
    List<String> tags,
  ) {
    final keywords = <String>{};

    // Add title words
    final titleWords = title.toLowerCase().split(' ');
    keywords.addAll(titleWords);
    keywords.add(title.toLowerCase());

    // Add author words
    keywords.addAll(author.toLowerCase().split(' '));
    keywords.add(author.toLowerCase());

    // Add genres and tags
    keywords.addAll(genres.map((g) => g.toLowerCase()));
    keywords.addAll(tags.map((t) => t.toLowerCase()));

    // Remove empty strings and very short words
    keywords.removeWhere((keyword) => keyword.isEmpty || keyword.length < 2);

    return keywords.toList();
  }

  // Seed books
  Future<List<String>> seedBooks({int count = 20}) async {
    debugPrint('🌱 Starting to seed $count books...');

    final batch = _firestore.batch();
    final bookIds = <String>[];

    for (int i = 0; i < count && i < _bookData.length; i++) {
      final bookData = _bookData[i];
      final bookRef = _firestore.collection('books').doc();
      final bookId = bookRef.id;
      bookIds.add(bookId);

      final publishedDate = DateTime.now().subtract(
        Duration(days: _random.nextInt(3650)),
      ); // Random date within last 10 years

      final bookDocument = {
        'title': bookData['title'],
        'author': bookData['author'],
        'description': bookData['description'],
        'coverUrl': _generateCoverUrl(),
        'genres': bookData['genres'],
        'rating':
            3.0 +
            (_random.nextDouble() * 2.0), // Random rating between 3.0 and 5.0
        'reviewCount': 0, // Will be updated as reviews are added
        'pageCount': bookData['pageCount'],
        'isbn': bookData['isbn'],
        'publishedDate': publishedDate,
        'publisher': bookData['publisher'],
        'language': bookData['language'],
        'tags': bookData['tags'],
        'metadata': {},
        'awards': bookData['awards'],
        'series': bookData['series'],
        'seriesNumber': bookData['seriesNumber'],
        'averageReadingTime': bookData['averageReadingTime'],
        'similarBooks': [],
        'relatedAuthors': [],
        'isAvailable': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'searchKeywords': _generateSearchKeywords(
          bookData['title'],
          bookData['author'],
          List<String>.from(bookData['genres']),
          List<String>.from(bookData['tags']),
        ),
      };

      batch.set(bookRef, bookDocument);
    }

    await batch.commit();
    debugPrint('✅ Successfully seeded ${bookIds.length} books!');
    return bookIds;
  }

  // Seed reviews for books
  Future<void> seedReviews(
    List<String> bookIds, {
    int reviewsPerBook = 5,
  }) async {
    debugPrint('📝 Starting to seed reviews...');

    int totalReviews = 0;
    int emotionAnalyzedCount = 0;

    // Check if emotion service is available
    final isEmotionServiceAvailable = await EmotionService.isServiceAvailable();
    debugPrint('🧠 Emotion service available: $isEmotionServiceAvailable');

    for (final bookId in bookIds) {
      final batch = _firestore.batch();
      final reviewCount =
          _random.nextInt(reviewsPerBook) +
          1; // 1 to reviewsPerBook reviews per book

      for (int i = 0; i < reviewCount; i++) {
        final reviewRef =
            _firestore
                .collection('books')
                .doc(bookId)
                .collection('reviews')
                .doc();

        final userName = _userNames[_random.nextInt(_userNames.length)];
        final userAvatar = _generateAvatarUrl();
        final rating =
            (_random.nextInt(3) + 3).toDouble(); // Rating between 3.0 and 5.0
        final content = _reviewTexts[_random.nextInt(_reviewTexts.length)];
        final createdAt = DateTime.now().subtract(
          Duration(days: _random.nextInt(365)),
        );

        final reviewDocument = {
          'bookId': bookId,
          'userId': 'seed_user_${_random.nextInt(1000)}',
          'userName': userName,
          'userAvatar': userAvatar,
          'rating': rating,
          'content': content,
          'createdAt': createdAt,
          'updatedAt': null,
          'likes': <String>[],
          'dislikes': <String>[],
          'isVerifiedPurchase': _random.nextBool(),
        };

        // Add emotion analysis if service is available
        if (isEmotionServiceAvailable) {
          try {
            // Add a small delay to respect API rate limits
            await Future.delayed(const Duration(milliseconds: 300));

            final emotionData = await EmotionService.predictEmotion(content);
            if (emotionData != null) {
              reviewDocument['emotion'] = emotionData.emotion;
              reviewDocument['emotionConfidence'] = emotionData.confidence;
              reviewDocument['emotionAnalyzedAt'] = DateTime.now();
              emotionAnalyzedCount++;
              debugPrint(
                '✨ Emotion predicted for review: ${emotionData.emotion} (${emotionData.confidence.toStringAsFixed(1)}%)',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Failed to predict emotion for review: $e');
            // Continue without emotion data
          }
        }

        batch.set(reviewRef, reviewDocument);
      }

      await batch.commit();

      // Update book rating and review count
      final bookRef = _firestore.collection('books').doc(bookId);
      final reviewsSnapshot =
          await _firestore
              .collection('books')
              .doc(bookId)
              .collection('reviews')
              .get();
      final reviews = reviewsSnapshot.docs;

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold(
          0.0,
          (total, doc) => total + (doc.data()['rating'] ?? 0.0),
        );
        final averageRating = totalRating / reviews.length;

        await bookRef.update({
          'rating': double.parse(averageRating.toStringAsFixed(2)),
          'reviewCount': reviews.length,
        });
      }

      totalReviews += reviewCount;
    }

    debugPrint('✅ Successfully seeded $totalReviews reviews!');
    debugPrint(
      '🧠 Emotion analysis: $emotionAnalyzedCount/$totalReviews reviews analyzed',
    );
  }

  // Seed likes for reviews
  Future<void> seedLikes(List<String> bookIds) async {
    debugPrint('👍 Starting to seed likes...');

    int totalLikes = 0;
    final fakeUserIds = List.generate(100, (index) => 'seed_user_$index');

    for (final bookId in bookIds) {
      final reviewsSnapshot =
          await _firestore
              .collection('books')
              .doc(bookId)
              .collection('reviews')
              .get();

      for (final reviewDoc in reviewsSnapshot.docs) {
        final batch = _firestore.batch();
        final reviewRef = reviewDoc.reference;

        // Random number of likes (0 to 15)
        final likeCount = _random.nextInt(16);
        final dislikeCount = _random.nextInt(5);

        // Select random users for likes
        final likedUsers = <String>[];
        final dislikedUsers = <String>[];

        for (int i = 0; i < likeCount; i++) {
          final userId = fakeUserIds[_random.nextInt(fakeUserIds.length)];
          if (!likedUsers.contains(userId) && !dislikedUsers.contains(userId)) {
            likedUsers.add(userId);
          }
        }

        for (int i = 0; i < dislikeCount; i++) {
          final userId = fakeUserIds[_random.nextInt(fakeUserIds.length)];
          if (!dislikedUsers.contains(userId) && !likedUsers.contains(userId)) {
            dislikedUsers.add(userId);
          }
        }

        batch.update(reviewRef, {
          'likes': likedUsers,
          'dislikes': dislikedUsers,
        });

        await batch.commit();
        totalLikes += likedUsers.length + dislikedUsers.length;
      }
    }

    debugPrint('✅ Successfully seeded $totalLikes likes and dislikes!');
  }

  // Main seed function
  Future<void> seedAll({int bookCount = 20, int reviewsPerBook = 5}) async {
    try {
      debugPrint('🚀 Starting complete seeding process...');
      debugPrint(
        '📊 Will create: $bookCount books with up to $reviewsPerBook reviews each',
      );

      // Step 1: Seed books
      final bookIds = await seedBooks(count: bookCount);

      // Step 2: Seed reviews
      await seedReviews(bookIds, reviewsPerBook: reviewsPerBook);

      // Step 3: Seed likes
      await seedLikes(bookIds);

      debugPrint('🎉 Seeding completed successfully!');
      debugPrint('📈 Summary:');
      debugPrint('   📚 Books: ${bookIds.length}');
      debugPrint(
        '   📝 Reviews: ~${bookIds.length * (reviewsPerBook / 2)} (average)',
      );
      debugPrint('   👍 Likes: Random distribution across all reviews');
    } catch (e) {
      debugPrint('❌ Error during seeding: $e');
      rethrow;
    }
  }

  // Clear all seeded data
  Future<void> clearAllData() async {
    try {
      debugPrint('🗑️ Clearing all seeded data...');

      // Get all books
      final booksSnapshot = await _firestore.collection('books').get();

      // Delete books and their reviews in batches
      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final bookDoc in booksSnapshot.docs) {
        // Delete reviews subcollection
        final reviewsSnapshot =
            await bookDoc.reference.collection('reviews').get();
        for (final reviewDoc in reviewsSnapshot.docs) {
          batch.delete(reviewDoc.reference);
          deleteCount++;
        }

        // Delete book
        batch.delete(bookDoc.reference);
        deleteCount++;

        // Commit batch every 500 operations
        if (deleteCount >= 500) {
          await batch.commit();
          deleteCount = 0;
        }
      }

      // Commit remaining operations
      if (deleteCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ Successfully cleared all data!');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      rethrow;
    }
  }
}
