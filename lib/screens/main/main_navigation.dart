import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../explore/explore_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';

// Navigation controller for child screens
class MainNavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  late void Function(int) _onTabChange;

  // Tab activation listeners
  final List<void Function(int)> _tabActivationListeners = [];

  int get currentIndex => _currentIndex;

  void _initialize(void Function(int) onTabChange) {
    _onTabChange = onTabChange;
  }

  void navigateToTab(int index) {
    if (index >= 0 && index < 3) {
      _onTabChange(index);
    }
  }

  void _updateIndex(int index) {
    final previousIndex = _currentIndex;
    _currentIndex = index;
    notifyListeners();

    // Notify specific tab activation if changed
    if (previousIndex != index) {
      _notifyTabActivation(index);
    }
  }

  void addTabActivationListener(void Function(int) listener) {
    _tabActivationListeners.add(listener);
  }

  void removeTabActivationListener(void Function(int) listener) {
    _tabActivationListeners.remove(listener);
  }

  void _notifyTabActivation(int tabIndex) {
    for (final listener in _tabActivationListeners) {
      try {
        listener(tabIndex);
      } catch (e) {
        // Ignore errors from listeners to prevent crashes
      }
    }
  }

  // Public method to manually trigger library refresh
  void refreshLibrary() {
    _notifyTabActivation(1); // Library tab is index 1
  }

  @override
  void dispose() {
    _tabActivationListeners.clear();
    super.dispose();
  }
}

// Provider widget to pass navigation controller down the widget tree
class MainNavigationProvider extends InheritedWidget {
  final MainNavigationController navigationController;

  const MainNavigationProvider({
    super.key,
    required this.navigationController,
    required super.child,
  });

  static MainNavigationController? of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<MainNavigationProvider>();
    return provider?.navigationController;
  }

  @override
  bool updateShouldNotify(MainNavigationProvider oldWidget) {
    return navigationController != oldWidget.navigationController;
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final MainNavigationController _navigationController =
      MainNavigationController();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
      screen: const ExploreScreen(),
      color: AppTheme.primary,
    ),
    NavigationItem(
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books,
      label: 'Library',
      screen: const LibraryScreen(),
      color: AppTheme.secondary,
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      screen: const ProfileScreen(),
      color: AppTheme.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _navigationController._initialize(_onTabTapped);
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Double tap to scroll to top or refresh
      _onDoubleTap(index);
      return;
    }

    Logger.userAction('Bottom navigation tap', {'index': index});
    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });
    _navigationController._updateIndex(index);
  }

  void _onDoubleTap(int index) {
    Logger.userAction('Bottom navigation double tap', {'index': index});
    HapticFeedback.lightImpact();

    // For library tab (index 1), trigger a refresh
    if (index == 1) {
      _navigationController._notifyTabActivation(index);
    }

    // Could implement scroll to top or refresh functionality for other tabs here
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: MainNavigationProvider(
        navigationController: _navigationController,
        child: IndexedStack(
          index: _currentIndex,
          children: _navigationItems.map((item) => item.screen).toList(),
        ),
      ),
      bottomNavigationBar: Container(
        margin: AppTheme.marginBottomNav,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.grey800 : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          boxShadow: AppTheme.elevation4(isDark),
          border: Border.all(
            color: isDark ? AppTheme.grey700 : AppTheme.grey200,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: AppTheme.paddingAll12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                _navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == _currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? item.color.withValues(alpha: 0.12)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius18,
                          ),
                          border:
                              isSelected
                                  ? Border.all(
                                    color: item.color.withValues(alpha: 0.25),
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color:
                                  isSelected
                                      ? item.color
                                      : (isDark
                                          ? AppTheme.grey400
                                          : AppTheme.grey600),
                              size: 22,
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              item.label,
                              style: AppTheme.labelSmall.copyWith(
                                color:
                                    isSelected
                                        ? item.color
                                        : (isDark
                                            ? AppTheme.grey400
                                            : AppTheme.grey600),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  final Color color;
  final int? badgeCount;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    required this.color,
    this.badgeCount,
  });
}
