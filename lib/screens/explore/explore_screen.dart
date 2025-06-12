import 'package:flutter/material.dart';
import 'package:read_next/widgets/book_card.dart';
import '../../services/book_service.dart';
import '../../services/library_service.dart';
import '../../services/auth_service.dart';
import '../../models/book.dart';
import '../book/book_details_screen.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_dropdown.dart';
import 'package:provider/provider.dart';
import '../main/main_navigation.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final BookService _bookService = BookService();
  final LibraryService _libraryService = LibraryService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  Set<String> _favoritedBookIds = {}; // Track which books are favorited
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

  String _selectedGenre = 'All';
  double _minRating = 0.0;
  String _sortBy = 'rating';

  final List<String> _genres = [
    'All',
    'Fiction',
    'Non-fiction',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Fantasy',
    'Thriller',
    'Biography',
    'History',
    'Science',
    'Self-help',
    'Business',
    'Philosophy',
    'Poetry',
    'Drama',
    'Horror',
    'Adventure',
    'Comedy',
    'Crime',
    'Young Adult',
    'Children',
    'Educational',
    'Religion',
    'Health',
    'Travel',
    'Cooking',
    'Art',
    'Music',
    'Sports',
    'Technology',
  ];

  final List<SortOption> _sortOptions = [
    SortOption('rating', 'Rating', Icons.star),
    SortOption('reviewCount', 'Popularity', Icons.trending_up),
    SortOption('publishedDate', 'Newest', Icons.new_releases),
    SortOption('title', 'Title A-Z', Icons.sort_by_alpha),
  ];

  @override
  void initState() {
    super.initState();
    Logger.screenDebug('ExploreScreen', 'Initializing Explore Screen');
    _loadBooks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load books and user's library data in parallel
      final futures = await Future.wait([
        _bookService.getBooks(
          minRating: 0.0,
          limit: 100,
          sortBy: 'rating',
          descending: true,
        ),
        _loadUserFavorites(),
      ]);

      final books = futures[0] as List<Book>;

      setState(() {
        _books = books;
        _filteredBooks = books;
      });
    } catch (e) {
      Logger.screenDebug('ExploreScreen', 'Error loading books', e);
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserFavorites() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        return; // User not logged in, no favorites to load
      }

      final libraryData = await _libraryService.getAllUserLibraryData(
        userId: userId,
      );

      final favorites = libraryData['favorites'] as List;
      setState(() {
        _favoritedBookIds =
            favorites.map((entry) => entry.bookId as String).toSet();
      });
    } catch (e) {
      Logger.screenDebug('ExploreScreen', 'Error loading user favorites', e);
      // Continue without favorites data
    }
  }

  void _applyFilters() {
    if (_isLoading) return;

    setState(() {
      _isSearching = true;
    });

    final query = _searchController.text.trim().toLowerCase();

    List<Book> filtered =
        _books.where((book) {
          // Search filter
          bool matchesSearch =
              query.isEmpty ||
              book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query) ||
              book.genres.any((genre) => genre.toLowerCase().contains(query));

          // Genre filter
          bool matchesGenre =
              _selectedGenre == 'All' || book.genres.contains(_selectedGenre);

          // Rating filter
          bool matchesRating = book.rating >= _minRating;

          return matchesSearch && matchesGenre && matchesRating;
        }).toList();

    // Apply sorting
    _sortBooks(filtered);

    setState(() {
      _filteredBooks = filtered;
      _isSearching = false;
    });
  }

  void _sortBooks(List<Book> books) {
    switch (_sortBy) {
      case 'title':
        books.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'rating':
        books.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'reviewCount':
        books.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case 'publishedDate':
        books.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
        break;
    }
  }

  void _navigateToBookDetails(Book book) {
    Logger.userAction('Navigate to book details from explore', {
      'bookId': book.id,
      'bookTitle': book.title,
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
    ).then((_) {
      // Refresh favorites when returning from book details
      if (mounted) {
        _loadUserFavorites();
      }
    });
  }

  Future<void> _toggleFavorite(Book book) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Optimistically update the UI
      final wasAlreadyFavorited = _favoritedBookIds.contains(book.id);
      setState(() {
        if (wasAlreadyFavorited) {
          _favoritedBookIds.remove(book.id);
        } else {
          _favoritedBookIds.add(book.id);
        }
      });

      await _libraryService.toggleFavorite(userId: userId, bookId: book.id);

      // Trigger library refresh
      if (mounted) {
        final navigationController = MainNavigationProvider.of(context);
        if (navigationController != null) {
          navigationController.refreshLibrary();
        }
      }

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasAlreadyFavorited
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert the optimistic update on error
      setState(() {
        if (_favoritedBookIds.contains(book.id)) {
          _favoritedBookIds.remove(book.id);
        } else {
          _favoritedBookIds.add(book.id);
        }
      });

      Logger.screenDebug('ExploreScreen', 'Error toggling favorite', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildFiltersSection(),
          Expanded(child: _buildBooksList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discover', style: AppTheme.headlineMedium),
          Text(
            'Find your next great read',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing20,
        AppTheme.spacing20,
        AppTheme.spacing20,
        AppTheme.spacing12,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          boxShadow: AppTheme.elevation2(isDark),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTheme.bodyLarge.copyWith(
            color: isDark ? AppTheme.white : AppTheme.grey900,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Discover amazing books, authors, genres...',
            hintStyle: AppTheme.bodyLarge.copyWith(
              color: isDark ? AppTheme.grey400 : AppTheme.grey500,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: AppTheme.paddingAll12,
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? Container(
                      margin: const EdgeInsets.only(right: AppTheme.spacing8),
                      child: IconButton(
                        icon: Container(
                          padding: AppTheme.paddingAll8,
                          decoration: BoxDecoration(
                            color: AppTheme.grey300.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius20,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark ? AppTheme.grey400 : AppTheme.grey600,
                            size: 16,
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    )
                    : Container(
                      margin: const EdgeInsets.only(right: AppTheme.spacing12),
                      child: Icon(
                        Icons.tune_rounded,
                        color: isDark ? AppTheme.grey400 : AppTheme.grey500,
                        size: 20,
                      ),
                    ),
            filled: true,
            fillColor: isDark ? AppTheme.grey800 : AppTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius24),
              borderSide: BorderSide(
                color: isDark ? AppTheme.grey700 : AppTheme.grey200,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius24),
              borderSide: BorderSide(
                color: isDark ? AppTheme.grey700 : AppTheme.grey200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius24),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: AppTheme.paddingH24.add(AppTheme.paddingV20),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        0,
        AppTheme.spacing16,
        AppTheme.spacing8,
      ),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.grey800 : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: AppTheme.elevation2(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre Filter (no label)
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected = _selectedGenre == genre;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacing8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radius20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                      onTap: () {
                        setState(() {
                          _selectedGenre = genre;
                        });
                        _applyFilters();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                          vertical: AppTheme.spacing10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppTheme.primary
                                  : (isDark
                                      ? AppTheme.grey800
                                      : AppTheme.grey100),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius20,
                          ),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppTheme.primary
                                    : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : [
                                    BoxShadow(
                                      color:
                                          isDark
                                              ? Colors.black.withValues(
                                                alpha: 0.1,
                                              )
                                              : AppTheme.grey900.withValues(
                                                alpha: 0.05,
                                              ),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: AppTheme.spacing6),
                            ],
                            Text(
                              genre,
                              style: AppTheme.labelMedium.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppTheme.grey300
                                            : AppTheme.grey700),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppTheme.spacing12),

          // Rating and Sort Row (no labels)
          Row(
            children: [
              Expanded(child: _buildRatingFilter(isDark)),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(child: _buildSortFilter(isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter(bool isDark) {
    return CustomDropdown<double>(
      value: _minRating,
      prefixIcon: Icons.star_rounded,
      items: const [
        CustomDropdownItem(
          value: 0.0,
          label: 'Any',
          icon: Icons.star_outline_rounded,
        ),
        CustomDropdownItem(
          value: 3.0,
          label: '3.0+',
          icon: Icons.star_half_rounded,
        ),
        CustomDropdownItem(
          value: 3.5,
          label: '3.5+',
          icon: Icons.star_half_rounded,
        ),
        CustomDropdownItem(value: 4.0, label: '4.0+', icon: Icons.star_rounded),
        CustomDropdownItem(value: 4.5, label: '4.5+', icon: Icons.star_rounded),
        CustomDropdownItem(value: 5.0, label: '5.0', icon: Icons.stars_rounded),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _minRating = value;
          });
          _applyFilters();
        }
      },
    );
  }

  Widget _buildSortFilter(bool isDark) {
    return CustomDropdown<String>(
      value: _sortBy,
      prefixIcon: Icons.sort_rounded,
      items:
          _sortOptions.map((option) {
            return CustomDropdownItem<String>(
              value: option.value,
              label: option.label,
              icon: option.icon,
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _sortBy = value;
          });
          _applyFilters();
        }
      },
    );
  }

  Widget _buildBooksList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(AppTheme.spacing24),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text('Something went wrong', style: AppTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  _error!,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                ElevatedButton.icon(
                  onPressed: _loadBooks,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredBooks.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(AppTheme.spacing24),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text('No books found', style: AppTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Try adjusting your search or filters to discover more books',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedGenre = 'All';
                      _minRating = 0.0;
                      _sortBy = 'rating';
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Results Header
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Icon(
                  Icons.auto_stories,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                '${_filteredBooks.length} books found',
                style: AppTheme.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(width: AppTheme.spacing16),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Books Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
                final isFavorited = _favoritedBookIds.contains(book.id);
                return BookCard(
                  book: book,
                  onTap: () => _navigateToBookDetails(book),
                  onFavoriteToggle: () => _toggleFavorite(book),
                  isFavorite: isFavorited,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class SortOption {
  final String value;
  final String label;
  final IconData icon;

  SortOption(this.value, this.label, this.icon);
}
