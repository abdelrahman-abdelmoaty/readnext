import 'package:flutter/foundation.dart';
import '../scripts/simple_seed.dart';
import 'user_service.dart';

class SeedService extends ChangeNotifier {
  bool _isSeeding = false;
  String _statusMessage = '';
  double _progress = 0.0;

  bool get isSeeding => _isSeeding;
  String get statusMessage => _statusMessage;
  double get progress => _progress;

  final SimpleSeed _simpleSeed = SimpleSeed();
  final UserService _userService = UserService();

  // Seed data with progress updates
  Future<void> seedData({int bookCount = 20, int reviewsPerBook = 5}) async {
    if (_isSeeding) return;

    // Check if current user is admin
    final isAdmin = await _userService.isCurrentUserAdmin();
    if (!isAdmin) {
      _statusMessage = 'Error: Admin privileges required';
      notifyListeners();
      throw Exception('Only admins can seed data');
    }

    try {
      _isSeeding = true;
      _progress = 0.0;
      _statusMessage = 'Starting seeding process...';
      notifyListeners();

      // Step 1: Seed books (25% progress)
      _statusMessage = 'Creating books...';
      _progress = 0.1;
      notifyListeners();

      final bookIds = await _simpleSeed.seedBooks(count: bookCount);

      _progress = 0.25;
      _statusMessage = 'Created ${bookIds.length} books';
      notifyListeners();

      // Step 2: Seed reviews with emotion analysis (65% progress)
      _statusMessage = 'Adding reviews with AI emotion analysis...';
      _progress = 0.3;
      notifyListeners();

      await _simpleSeed.seedReviews(bookIds, reviewsPerBook: reviewsPerBook);

      _progress = 0.65;
      _statusMessage = 'Added reviews with emotion analysis for all books';
      notifyListeners();

      // Step 3: Seed likes (100% progress)
      _statusMessage = 'Adding likes and interactions...';
      _progress = 0.7;
      notifyListeners();

      await _simpleSeed.seedLikes(bookIds);

      _progress = 1.0;
      _statusMessage =
          'Seeding completed successfully! All reviews include AI emotion analysis.';
      notifyListeners();

      // Wait a moment to show completion
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _statusMessage = 'Error during seeding: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isSeeding = false;
      _progress = 0.0;
      notifyListeners();
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    if (_isSeeding) return;

    // Check if current user is admin
    final isAdmin = await _userService.isCurrentUserAdmin();
    if (!isAdmin) {
      _statusMessage = 'Error: Admin privileges required';
      notifyListeners();
      throw Exception('Only admins can clear data');
    }

    try {
      _isSeeding = true;
      _progress = 0.0;
      _statusMessage = 'Clearing all data...';
      notifyListeners();

      await _simpleSeed.clearAllData();

      _progress = 1.0;
      _statusMessage = 'All data cleared successfully!';
      notifyListeners();

      // Wait a moment to show completion
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _statusMessage = 'Error clearing data: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isSeeding = false;
      _progress = 0.0;
      notifyListeners();
    }
  }

  // Reset status
  void resetStatus() {
    _statusMessage = '';
    _progress = 0.0;
    notifyListeners();
  }
}
