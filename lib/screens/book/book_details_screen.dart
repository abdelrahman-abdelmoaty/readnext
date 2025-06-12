import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/review.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../services/review_service.dart';
import '../../services/library_service.dart';
import '../../models/user_library.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/status_tag.dart';
import '../../widgets/emotion_chip.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../main/main_navigation.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final BookService _bookService = BookService();
  final ReviewService _reviewService = ReviewService();
  final LibraryService _libraryService = LibraryService();
  List<Review> _reviews = [];
  UserLibrary? _libraryEntry;
  bool _isLoading = true;
  bool _isReviewing = false;
  bool _isUpdatingLibrary = false;
  final _reviewController = TextEditingController();
  double _userRating = 0;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadReviews(), _loadLibraryEntry()]);
  }

  Future<void> _loadLibraryEntry() async {
    try {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        _libraryEntry = await _libraryService.getUserLibraryEntry(
          userId: user.uid,
          bookId: widget.book.id,
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      _reviews = await _bookService.getBookReviews(bookId: widget.book.id);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      _showSnackBar('Please select a rating', Colors.red);
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      _showSnackBar('Please write a review', Colors.red);
      return;
    }

    setState(() => _isReviewing = true);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _bookService.addReview(
        bookId: widget.book.id,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userAvatar: user.photoURL ?? '',
        rating: _userRating,
        content: _reviewController.text.trim(),
      );

      _reviewController.clear();
      _userRating = 0;
      await _loadReviews();

      _showSnackBar('Review submitted successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error submitting review: $e', Colors.red);
    } finally {
      setState(() => _isReviewing = false);
    }
  }

  Future<void> _likeReview(String reviewId) async {
    try {
      await _reviewService.likeReview(
        bookId: widget.book.id,
        reviewId: reviewId,
      );
      await _loadReviews();
    } catch (e) {
      _showSnackBar('Error liking review: $e', Colors.red);
    }
  }

  Future<void> _dislikeReview(String reviewId) async {
    try {
      await _reviewService.dislikeReview(
        bookId: widget.book.id,
        reviewId: reviewId,
      );
      await _loadReviews();
    } catch (e) {
      _showSnackBar('Error disliking review: $e', Colors.red);
    }
  }

  Future<void> _updateLibraryStatus(ReadingStatus status) async {
    setState(() => _isUpdatingLibrary = true);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      Logger.screenDebug('BookDetailsScreen', 'Updating library status', {
        'bookId': widget.book.id,
        'newStatus': status.name,
        'hasExistingEntry': _libraryEntry != null,
      });

      if (_libraryEntry == null) {
        // Add new entry
        await _libraryService.addToLibrary(
          userId: user.uid,
          bookId: widget.book.id,
          status: status,
        );
      } else {
        // Update existing entry
        await _libraryService.updateLibraryEntry(
          entryId: _libraryEntry!.id,
          status: status,
        );
      }

      await _loadLibraryEntry();

      Logger.screenDebug(
        'BookDetailsScreen',
        'Library status updated successfully',
        {
          'bookId': widget.book.id,
          'newStatus': status.name,
          'entryId': _libraryEntry?.id,
        },
      );

      // Trigger library refresh
      if (mounted) {
        final navigationController = MainNavigationProvider.of(context);
        if (navigationController != null) {
          navigationController.refreshLibrary();
        }
      }

      _showSnackBar('Added to ${_getStatusText(status)}', AppTheme.success);
    } catch (e) {
      Logger.screenDebug(
        'BookDetailsScreen',
        'Error updating library status',
        e,
      );
      _showSnackBar('Error updating status: $e', Colors.red);
    } finally {
      setState(() => _isUpdatingLibrary = false);
    }
  }

  Future<void> _removeFromLibrary() async {
    setState(() => _isUpdatingLibrary = true);
    try {
      if (_libraryEntry != null) {
        await _libraryService.removeFromLibrary(_libraryEntry!.id);
        setState(() {
          _libraryEntry = null;
        });

        // Trigger library refresh
        if (mounted) {
          final navigationController = MainNavigationProvider.of(context);
          if (navigationController != null) {
            navigationController.refreshLibrary();
          }
        }

        _showSnackBar('Removed from library', AppTheme.warning);
      }
    } catch (e) {
      _showSnackBar('Error removing from library: $e', Colors.red);
    } finally {
      setState(() => _isUpdatingLibrary = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_libraryEntry == null) return;

    setState(() => _isUpdatingLibrary = true);
    try {
      await _libraryService.updateLibraryEntry(
        entryId: _libraryEntry!.id,
        isFavorite: !_libraryEntry!.isFavorite,
      );
      await _loadLibraryEntry();

      // Trigger library refresh
      if (mounted) {
        final navigationController = MainNavigationProvider.of(context);
        if (navigationController != null) {
          navigationController.refreshLibrary();
        }
      }

      _showSnackBar(
        _libraryEntry!.isFavorite
            ? 'Added to favorites'
            : 'Removed from favorites',
        AppTheme.accent,
      );
    } catch (e) {
      _showSnackBar('Error updating favorite: $e', Colors.red);
    } finally {
      setState(() => _isUpdatingLibrary = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getStatusText(ReadingStatus status) {
    return status.displayName;
  }

  IconData _getStatusIcon(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return Icons.bookmark_add;
      case ReadingStatus.currentlyReading:
        return Icons.menu_book;
      case ReadingStatus.read:
        return Icons.check_circle;
      case ReadingStatus.dnf:
        return Icons.cancel;
      case ReadingStatus.onHold:
        return Icons.pause_circle;
      case ReadingStatus.rereading:
        return Icons.refresh;
    }
  }

  Color _getStatusColor(ReadingStatus status) {
    // Using consistent primary color for all statuses
    return AppTheme.primary;
  }

  String _getStatusDescription(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return 'Books you plan to read';
      case ReadingStatus.currentlyReading:
        return 'Currently reading this book';
      case ReadingStatus.read:
        return 'Finished reading';
      case ReadingStatus.dnf:
        return 'Did not finish';
      case ReadingStatus.onHold:
        return 'Paused reading';
      case ReadingStatus.rereading:
        return 'Reading again';
    }
  }

  Widget _buildLibraryActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.collections_bookmark,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Library',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_libraryEntry != null)
                          Text(
                            'Currently in: ${_getStatusText(_libraryEntry!.status)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_libraryEntry != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _isUpdatingLibrary ? null : _toggleFavorite,
                        icon: Icon(
                          _libraryEntry!.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              _libraryEntry!.isFavorite
                                  ? Colors.pink
                                  : Colors.grey,
                          size: 20,
                        ),
                        tooltip:
                            _libraryEntry!.isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Current status display (enhanced)
              if (_libraryEntry != null) ...[
                StatusTag(
                  text: _getStatusText(_libraryEntry!.status),
                  color: _getStatusColor(_libraryEntry!.status),
                  icon: _getStatusIcon(_libraryEntry!.status),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing12,
                  ),
                  fontSize: 14,
                ),
                const SizedBox(height: AppTheme.spacing20),
              ],

              // Status selection header
              Row(
                children: [
                  Text(
                    _libraryEntry == null
                        ? 'Choose a reading status:'
                        : 'Change status:',
                    style: AppTheme.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_libraryEntry != null)
                    Text(
                      'Tap to switch',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.grey500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Clean status selection list
              Column(
                children:
                    ReadingStatus.values.map((status) {
                      final isSelected = _libraryEntry?.status == status;
                      final isDisabled = _isUpdatingLibrary;

                      return SelectableStatusTag(
                        text: _getStatusText(status),
                        description: _getStatusDescription(status),
                        color: _getStatusColor(status),
                        icon: _getStatusIcon(status),
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        onTap: () => _updateLibraryStatus(status),
                      );
                    }).toList(),
              ),

              // Remove option and loading indicator
              if (_libraryEntry != null) ...[
                const SizedBox(height: AppTheme.spacing20),
                const Divider(),
                const SizedBox(height: AppTheme.spacing12),
                Center(
                  child: TextButton.icon(
                    onPressed: _isUpdatingLibrary ? null : _removeFromLibrary,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Remove from Library',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing8,
                      ),
                    ),
                  ),
                ),
              ],

              // Loading indicator
              if (_isUpdatingLibrary) ...[
                const SizedBox(height: AppTheme.spacing16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.grey100.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Updating...',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      review.userAvatar.isNotEmpty
                          ? NetworkImage(review.userAvatar)
                          : null,
                  child:
                      review.userAvatar.isEmpty
                          ? Text(
                            review.userName.isNotEmpty
                                ? review.userName[0].toUpperCase()
                                : 'U',
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        review.createdAt.toString().split(' ')[0],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.content, style: const TextStyle(fontSize: 16)),
            // Enhanced emotion analysis section
            if (review.hasEmotionAnalysis) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI detected emotion:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    EmotionChip(
                      emotion: review.emotion,
                      confidence: review.emotionConfidence,
                      showConfidence: true,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined),
                        onPressed: () => _likeReview(review.id),
                      ),
                      Text('${review.likes.length}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.thumb_down_outlined),
                        onPressed: () => _dislikeReview(review.id),
                      ),
                      Text('${review.dislikes.length}'),
                    ],
                  ),
                ),
                // Show emotion analysis status for reviews without analysis
                if (!review.hasEmotionAnalysis)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No emotion analysis',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Book Details'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book header
            Container(
              margin: AppTheme.marginAll16,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius20),
                ),
                child: Padding(
                  padding: AppTheme.paddingAll20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'book_${widget.book.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius16,
                            ),
                            boxShadow: AppTheme.elevation2(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius16,
                            ),
                            child: Image.network(
                              widget.book.coverUrl,
                              height: 220,
                              width: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 220,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: AppTheme.grey300,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radius16,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_stories_rounded,
                                        size: 48,
                                        color: AppTheme.grey500,
                                      ),
                                      const SizedBox(height: AppTheme.spacing8),
                                      Text(
                                        'Cover\nUnavailable',
                                        textAlign: TextAlign.center,
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.grey600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: AppTheme.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing8),
                            Text(
                              'by ${widget.book.author}',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.grey600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing16),

                            // Rating badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.warning.withValues(alpha: 0.15),
                                    AppTheme.warning.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius20,
                                ),
                                border: Border.all(
                                  color: AppTheme.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacing6),
                                  Text(
                                    widget.book.rating.toStringAsFixed(1),
                                    style: AppTheme.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacing6),
                                  Text(
                                    '(${widget.book.reviewCount})',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.grey600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.spacing16),

                            // Book details
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                  color: AppTheme.grey500,
                                ),
                                const SizedBox(width: AppTheme.spacing6),
                                Text(
                                  '${widget.book.pageCount} pages',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacing6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: AppTheme.grey500,
                                ),
                                const SizedBox(width: AppTheme.spacing6),
                                Text(
                                  'Published ${widget.book.publishedDate.toString().split(' ')[0]}',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Genres
                            if (widget.book.genres.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacing16),
                              Wrap(
                                spacing: AppTheme.spacing8,
                                runSpacing: AppTheme.spacing6,
                                children:
                                    widget.book.genres.take(3).map((genre) {
                                      return StatusTag(
                                        text: genre,
                                        color: AppTheme.secondary,
                                        fontSize: 11,
                                      );
                                    }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Library actions
            _buildLibraryActions(),

            // Description
            Container(
              margin: AppTheme.marginAll16,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                ),
                child: Padding(
                  padding: AppTheme.paddingAll20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: AppTheme.paddingAll8,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                            ),
                            child: Icon(
                              Icons.description_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Text(
                            'Description',
                            style: AppTheme.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        widget.book.description,
                        style: AppTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.grey300
                                  : AppTheme.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Reviews section
            Container(
              margin: AppTheme.marginAll16,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                ),
                child: Padding(
                  padding: AppTheme.paddingAll20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: AppTheme.paddingAll8,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                            ),
                            child: Icon(
                              Icons.rate_review_rounded,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Text(
                            'Write a Review',
                            style: AppTheme.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing20),

                      // Rating stars
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _userRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppTheme.warning,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _userRating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: AppTheme.spacing12),

                      // Review text field
                      TextField(
                        controller: _reviewController,
                        maxLines: 4,
                        style: AppTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts about this book...',
                          hintStyle: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.grey500,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.grey800
                                  : AppTheme.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius12,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius12,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius12,
                            ),
                            borderSide: BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: AppTheme.paddingAll16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isReviewing ? null : _submitReview,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacing16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                            ),
                          ),
                          icon:
                              _isReviewing
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Icon(Icons.send_rounded),
                          label: Text(
                            _isReviewing ? 'Submitting...' : 'Submit Review',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Reviews list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.reviews),
                  const SizedBox(width: 8),
                  Text(
                    'Reviews (${_reviews.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No reviews yet. Be the first to review this book!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._reviews.map(_buildReviewItem),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
