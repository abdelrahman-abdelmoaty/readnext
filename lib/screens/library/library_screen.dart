import 'package:flutter/material.dart';
import '../../services/library_service.dart';
import '../../services/book_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_library.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_dropdown.dart';
import 'package:provider/provider.dart';
import '../main/main_navigation.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final LibraryService _libraryService = LibraryService();
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;

  // Navigation controller for auto-refresh
  MainNavigationController? _navigationController;

  List<UserLibrary> _allBooks = [];
  List<UserLibrary> _currentlyReading = [];
  List<UserLibrary> _wantToRead = [];
  List<UserLibrary> _read = [];
  List<UserLibrary> _onHold = [];
  List<UserLibrary> _dnf = [];
  List<UserLibrary> _rereading = [];
  List<UserLibrary> _favorites = [];

  List<UserLibrary> _filteredBooks = [];

  // Cache for book data to avoid redundant API calls during the same session
  final Map<String, Book> _booksCache = {};

  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

  String _sortBy = 'lastUpdated';
  bool _showFavoritesOnly = false;

  final List<SortOption> _sortOptions = [
    SortOption('lastUpdated', 'Recently Updated', Icons.access_time),
    SortOption('addedAt', 'Date Added', Icons.date_range),
    SortOption('title', 'Title A-Z', Icons.sort_by_alpha),
    SortOption('rating', 'Rating', Icons.star),
    SortOption('progress', 'Progress', Icons.trending_up),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
    Logger.screenDebug('LibraryScreen', 'Initializing LibraryScreen');

    // Set up navigation controller listener for auto-refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationController = MainNavigationProvider.of(context);
      if (_navigationController != null) {
        _navigationController!.addTabActivationListener(_onMainTabActivated);
      }
    });

    _loadLibraryData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh library data when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      Logger.screenDebug('LibraryScreen', 'App resumed, refreshing library');
      _refreshLibraryData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();

    // Clean up navigation controller listener
    if (_navigationController != null) {
      _navigationController!.removeTabActivationListener(_onMainTabActivated);
    }

    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Tab change is complete, apply filters
      Logger.screenDebug(
        'LibraryScreen',
        'Tab changed to ${_tabController.index}',
      );
      _applyFilters();
    }
  }

  // Handle main navigation tab activation
  void _onMainTabActivated(int tabIndex) {
    // Library tab is index 1 in main navigation
    if (tabIndex == 1 && mounted) {
      Logger.screenDebug(
        'LibraryScreen',
        'Library tab activated, refreshing data',
      );
      _refreshLibraryData();
    }
  }

  Future<void> _loadLibraryData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      Logger.screenDebug('LibraryScreen', 'Loading library data', {
        'forceRefresh': forceRefresh,
        'userId': userId,
      });

      // Clear book cache if force refresh is requested
      if (forceRefresh) {
        _booksCache.clear();
      }

      // Use the optimized single API call (always fresh data)
      final libraryData = await _libraryService.getAllUserLibraryData(
        userId: userId,
      );

      // Extract all the data from the single response
      _allBooks = libraryData['allBooks'] as List<UserLibrary>;
      _currentlyReading = libraryData['currentlyReading'] as List<UserLibrary>;
      _wantToRead = libraryData['wantToRead'] as List<UserLibrary>;
      _read = libraryData['read'] as List<UserLibrary>;
      _onHold = libraryData['onHold'] as List<UserLibrary>;
      _dnf = libraryData['dnf'] as List<UserLibrary>;
      _rereading = libraryData['rereading'] as List<UserLibrary>;
      _favorites = libraryData['favorites'] as List<UserLibrary>;

      Logger.screenDebug('LibraryScreen', 'Library data loaded', {
        'totalBooks': _allBooks.length,
        'currentlyReading': _currentlyReading.length,
        'wantToRead': _wantToRead.length,
        'read': _read.length,
        'favorites': _favorites.length,
      });

      // Pre-load book data for better performance
      await _preloadBooksData(_allBooks);

      _filteredBooks = _allBooks;
      _applyFilters();
    } catch (e) {
      Logger.screenDebug('LibraryScreen', 'Error loading library data', e);
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

  Future<void> _refreshLibraryData() async {
    Logger.screenDebug('LibraryScreen', 'Starting library data refresh');
    await _loadLibraryData(forceRefresh: true);
    Logger.screenDebug('LibraryScreen', 'Library data refresh completed');
  }

  // Pre-load book data to avoid multiple API calls during filtering/display
  Future<void> _preloadBooksData(List<UserLibrary> libraryEntries) async {
    try {
      final bookIds =
          libraryEntries
              .map((entry) => entry.bookId)
              .where((id) => !_booksCache.containsKey(id))
              .toSet()
              .toList();

      if (bookIds.isEmpty) return;

      // Load books in batches to avoid overwhelming the API
      const batchSize = 10;
      for (int i = 0; i < bookIds.length; i += batchSize) {
        final batchIds = bookIds.skip(i).take(batchSize).toList();
        final futures = batchIds.map((id) => _bookService.getBookById(id));
        final books = await Future.wait(futures);

        for (int j = 0; j < books.length; j++) {
          final book = books[j];
          if (book != null) {
            _booksCache[batchIds[j]] = book;
          }
        }
      }
    } catch (e) {
      Logger.screenDebug('LibraryScreen', 'Error preloading books data', e);
      // Continue without throwing to not break the main flow
    }
  }

  void _applyFilters() {
    if (_isLoading) return;

    setState(() {
      _isSearching = true;
    });

    // Get current tab's books
    List<UserLibrary> sourceBooks;
    final currentTabIndex = _tabController.index;

    switch (currentTabIndex) {
      case 0:
        sourceBooks = _allBooks;
        break;
      case 1:
        sourceBooks = _currentlyReading;
        break;
      case 2:
        sourceBooks = _wantToRead;
        break;
      case 3:
        sourceBooks = _read;
        break;
      case 4:
        sourceBooks = _onHold;
        break;
      case 5:
        sourceBooks = _dnf;
        break;
      case 6:
        sourceBooks = _rereading;
        break;
      default:
        sourceBooks = _allBooks;
    }

    Logger.screenDebug('LibraryScreen', 'Applying filters', {
      'currentTab': currentTabIndex,
      'sourceBooks': sourceBooks.length,
      'searchQuery': _searchController.text,
      'favoritesOnly': _showFavoritesOnly,
    });

    List<UserLibrary> filtered = List.from(sourceBooks);

    // Apply search filter using cached book data
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered =
          filtered.where((entry) {
            final book = _booksCache[entry.bookId];
            if (book == null) return false;

            return book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.genres.any((genre) => genre.toLowerCase().contains(query));
          }).toList();
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((entry) => entry.isFavorite).toList();
    }

    // Apply sorting
    _sortBooks(filtered);

    setState(() {
      _filteredBooks = filtered;
      _isSearching = false;
    });

    Logger.screenDebug('LibraryScreen', 'Filters applied', {
      'filteredBooks': filtered.length,
    });
  }

  void _sortBooks(List<UserLibrary> books) {
    switch (_sortBy) {
      case 'title':
        books.sort((a, b) {
          final bookA = _booksCache[a.bookId];
          final bookB = _booksCache[b.bookId];
          if (bookA == null || bookB == null) return 0;
          return bookA.title.compareTo(bookB.title);
        });
        break;
      case 'lastUpdated':
        books.sort((a, b) {
          final aDate = a.lastUpdated ?? a.addedAt;
          final bDate = b.lastUpdated ?? b.addedAt;
          return bDate.compareTo(aDate);
        });
        break;
      case 'addedAt':
        books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case 'progress':
        books.sort((a, b) => (b.progress).compareTo(a.progress));
        break;
      case 'rating':
        books.sort(
          (a, b) => (b.personalRating ?? 0).compareTo(a.personalRating ?? 0),
        );
        break;
    }
  }

  void _navigateToBookDetails(UserLibrary libraryEntry) async {
    // Try to get book from cache first
    Book? book = _booksCache[libraryEntry.bookId];

    // If not in cache, try to load it
    if (book == null) {
      book = await _bookService.getBookById(libraryEntry.bookId);
      if (book != null) {
        _booksCache[libraryEntry.bookId] = book;
      }
    }

    if (book != null && mounted) {
      Logger.userAction('Navigate to book details from library', {
        'bookId': book.id,
        'bookTitle': book.title,
      });

      // Always refresh when returning from book details
      if (mounted) {
        Logger.screenDebug(
          'LibraryScreen',
          'Returned from book details, refreshing library',
        );
        await _refreshLibraryData();
      }
    } else {
      // Show error message if book cannot be loaded
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load book details'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(UserLibrary libraryEntry) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _libraryService.toggleFavorite(
        userId: userId,
        bookId: libraryEntry.bookId,
      );

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              libraryEntry.isFavorite
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refresh library data to show updated favorite status
      await _refreshLibraryData();
    } catch (e) {
      Logger.screenDebug('LibraryScreen', 'Error toggling favorite', e);
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
          _buildQuickFilters(),
          _buildTabBar(),
          Expanded(child: _buildCurrentTabContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Library', style: AppTheme.headlineMedium),
          Text(
            'Your personal book collection',
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
            hintText: 'Search your library: books, authors, genres...',
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
                        Icons.filter_list_rounded,
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

  Widget _buildQuickFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing24,
        0,
        AppTheme.spacing24,
        AppTheme.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacing4,
              bottom: AppTheme.spacing12,
            ),
            child: Text(
              'Filters & Sort',
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.grey300 : AppTheme.grey700,
                fontSize: 13,
              ),
            ),
          ),

          // Filter Row
          Row(
            children: [
              // Sort Button
              Expanded(
                child: CustomDropdown<String>(
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
                ),
              ),

              const SizedBox(width: AppTheme.spacing16),

              // Favorites Filter
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                  onTap: () {
                    setState(() {
                      _showFavoritesOnly = !_showFavoritesOnly;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _showFavoritesOnly
                              ? AppTheme.accent
                              : (isDark ? AppTheme.grey800 : AppTheme.grey50),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      boxShadow:
                          _showFavoritesOnly
                              ? [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showFavoritesOnly
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color:
                              _showFavoritesOnly
                                  ? Colors.white
                                  : (isDark
                                      ? AppTheme.grey400
                                      : AppTheme.grey600),
                          size: 18,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Favorites',
                              style: AppTheme.labelMedium.copyWith(
                                color:
                                    _showFavoritesOnly
                                        ? Colors.white
                                        : (isDark
                                            ? AppTheme.white
                                            : AppTheme.grey900),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (_showFavoritesOnly)
                              Text(
                                '${_favorites.length} books',
                                style: AppTheme.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing20,
        AppTheme.spacing24,
        AppTheme.spacing20,
        AppTheme.spacing16,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: AppTheme.paddingH4,
        child: Row(
          children: [
            _buildStatusTab(
              index: 0,
              label: 'All Books',
              icon: Icons.library_books_outlined,
              activeIcon: Icons.library_books,
              color: AppTheme.primary,
              count: _allBooks.length,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildStatusTab(
              index: 1,
              label: ReadingStatus.currentlyReading.displayName,
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              color: AppTheme.primary,
              count: _currentlyReading.length,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildStatusTab(
              index: 2,
              label: ReadingStatus.wantToRead.displayName,
              icon: Icons.bookmark_add_outlined,
              activeIcon: Icons.bookmark_add,
              color: AppTheme.primary,
              count: _wantToRead.length,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildStatusTab(
              index: 3,
              label: ReadingStatus.read.displayName,
              icon: Icons.check_circle_outline,
              activeIcon: Icons.check_circle,
              color: AppTheme.primary,
              count: _read.length,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildStatusTab(
              index: 4,
              label: ReadingStatus.onHold.displayName,
              icon: Icons.pause_circle_outline,
              activeIcon: Icons.pause_circle,
              color: AppTheme.primary,
              count: _onHold.length,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildStatusTab(
              index: 5,
              label: ReadingStatus.dnf.displayName,
              icon: Icons.cancel_outlined,
              activeIcon: Icons.cancel,
              color: AppTheme.primary,
              count: _dnf.length,
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildStatusTab(
              index: 6,
              label: ReadingStatus.rereading.displayName,
              icon: Icons.refresh_outlined,
              activeIcon: Icons.refresh,
              color: AppTheme.primary,
              count: _rereading.length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color color,
    required int count,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing20,
          vertical: AppTheme.spacing16,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? color : (isDark ? AppTheme.grey800 : AppTheme.white),
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          border: Border.all(
            color:
                isSelected
                    ? color
                    : (isDark ? AppTheme.grey700 : AppTheme.grey300),
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : AppTheme.elevation1(isDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.titleSmall.copyWith(
                    color:
                        isSelected
                            ? Colors.white
                            : (isDark ? AppTheme.white : AppTheme.grey900),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  '$count ${count == 1 ? 'book' : 'books'}',
                  style: AppTheme.labelSmall.copyWith(
                    color:
                        isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isDark ? AppTheme.grey400 : AppTheme.grey600),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
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
                  onPressed: _refreshLibraryData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
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
                  _showFavoritesOnly ? Icons.favorite : Icons.library_books,
                  color:
                      _showFavoritesOnly
                          ? AppTheme.accent
                          : Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_filteredBooks.length} books',
                      style: AppTheme.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_showFavoritesOnly)
                      Text(
                        'Showing favorites only',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                  ],
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
          child:
              _filteredBooks.isEmpty ? _buildEmptyState() : _buildBooksGrid(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppTheme.spacing24),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.book_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text('No books found', style: AppTheme.headlineSmall),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                _searchController.text.isNotEmpty || _showFavoritesOnly
                    ? 'Try adjusting your search or filters'
                    : 'Start building your library by adding books from the Discover tab',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (_searchController.text.isNotEmpty || _showFavoritesOnly) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showFavoritesOnly = false;
                      _sortBy = 'lastUpdated';
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ] else ...[
                // When there are truly no books in the library
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to discover tab using the main navigation controller
                          final navigationController =
                              MainNavigationProvider.of(context);
                          if (navigationController != null) {
                            navigationController.navigateToTab(0);
                          }
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Discover Books'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksGrid() {
    return Padding(
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
          final libraryEntry = _filteredBooks[index];
          final book = _booksCache[libraryEntry.bookId];

          // If book data is not available, show a placeholder or skip
          if (book == null) {
            return _buildMissingBookCard(libraryEntry);
          }

          return BookCard(
            book: book,
            onTap: () => _navigateToBookDetails(libraryEntry),
            onFavoriteToggle: () => _toggleFavorite(libraryEntry),
            isFavorite: libraryEntry.isFavorite,
            statusText: libraryEntry.status.displayName,
            statusColor: _getStatusColor(libraryEntry.status),
          );
        },
      ),
    );
  }

  Widget _buildMissingBookCard(UserLibrary libraryEntry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: AppTheme.grey400),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Book not available',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              libraryEntry.status.displayName,
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReadingStatus status) {
    // Using consistent primary color for all statuses
    return AppTheme.primary;
  }
}

class SortOption {
  final String value;
  final String label;
  final IconData icon;

  SortOption(this.value, this.label, this.icon);
}
