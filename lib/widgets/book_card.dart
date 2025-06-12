import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../utils/app_theme.dart';
import 'status_tag.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final String? statusText;
  final Color? statusColor;
  final double? progress;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.statusText,
    this.statusColor,
    this.progress,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    if (widget.onTap != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onTap!();
      });
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Hero(
            tag: 'book_${widget.book.id}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radius20),
                boxShadow:
                    _isPressed
                        ? AppTheme.elevation3(isDark)
                        : AppTheme.elevation1(isDark),
              ),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  margin: AppTheme.marginAll4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.grey800 : AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius20),
                    border: Border.all(
                      color:
                          _isPressed
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : (isDark ? AppTheme.grey700 : AppTheme.grey200),
                      width: _isPressed ? 2 : 1,
                    ),
                    gradient:
                        _isPressed
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (isDark ? AppTheme.grey800 : AppTheme.white),
                                (isDark ? AppTheme.grey700 : AppTheme.grey50),
                              ],
                            )
                            : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoverImage(isDark),
                      _buildBookInfo(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverImage(bool isDark) {
    return Expanded(
      flex: 3,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radius20),
          ),
          color: isDark ? AppTheme.grey700 : AppTheme.grey100,
        ),
        child: Stack(
          children: [
            // Main Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radius20),
              ),
              child: Stack(
                children: [
                  // Background gradient for better loading states
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark ? AppTheme.grey700 : AppTheme.grey200)
                              .withValues(alpha: 0.5),
                          (isDark ? AppTheme.grey800 : AppTheme.grey300)
                              .withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),

                  // Actual Image
                  CachedNetworkImage(
                    imageUrl: widget.book.coverUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    placeholder:
                        (context, url) => _buildLoadingPlaceholder(isDark),
                    errorWidget:
                        (context, url, error) => _buildErrorWidget(isDark),
                  ),

                  // Subtle overlay for better text readability
                  if (widget.isFavorite ||
                      widget.book.hasAwards ||
                      widget.progress != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Top Badges
            if (widget.isFavorite ||
                widget.book.hasAwards ||
                widget.onFavoriteToggle != null)
              Positioned(
                top: AppTheme.spacing12,
                right: AppTheme.spacing12,
                child: _buildTopBadges(isDark),
              ),

            // Status Badge (Top Left)
            if (widget.statusText != null)
              Positioned(
                top: AppTheme.spacing12,
                left: AppTheme.spacing12,
                child: Container(
                  padding: AppTheme.paddingH8.add(AppTheme.paddingV4),
                  decoration: BoxDecoration(
                    color: widget.statusColor ?? AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.statusText!,
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Progress Indicator
            if (widget.progress != null && widget.progress! > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildProgressIndicator(),
              ),

            // Rating Badge (Bottom Left)
            Positioned(
              bottom: AppTheme.spacing8,
              left: AppTheme.spacing8,
              child: _buildRatingBadge(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppTheme.grey700 : AppTheme.grey200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppTheme.primaryLight : AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Loading...',
            style: AppTheme.labelSmall.copyWith(
              color: isDark ? AppTheme.grey400 : AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Container(
      color: isDark ? AppTheme.grey700 : AppTheme.grey200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 48,
            color: isDark ? AppTheme.grey500 : AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Cover\nUnavailable',
            textAlign: TextAlign.center,
            style: AppTheme.labelSmall.copyWith(
              color: isDark ? AppTheme.grey500 : AppTheme.grey600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadges(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Awards badge
        if (widget.book.hasAwards)
          Container(
            padding: AppTheme.paddingH8.add(AppTheme.paddingV4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.primaryLight,
              size: 16,
            ),
          ),

        if (widget.book.hasAwards &&
            (widget.isFavorite || widget.onFavoriteToggle != null))
          const SizedBox(width: AppTheme.spacing8),

        // Favorite button/badge
        if (widget.isFavorite || widget.onFavoriteToggle != null)
          GestureDetector(
            onTap: widget.onFavoriteToggle,
            child: Container(
              padding: AppTheme.paddingH8.add(AppTheme.paddingV4),
              decoration: BoxDecoration(
                color:
                    widget.isFavorite
                        ? AppTheme.accent.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border:
                    widget.onFavoriteToggle != null
                        ? Border.all(
                          color:
                              widget.isFavorite
                                  ? AppTheme.accent
                                  : Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        )
                        : null,
              ),
              child: Icon(
                widget.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color:
                    widget.isFavorite
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radius20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radius20),
        ),
        child: LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: Colors.black.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: AppTheme.paddingH8.add(AppTheme.paddingV4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: AppTheme.primaryLight),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            widget.book.rating.toStringAsFixed(1),
            style: AppTheme.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo(bool isDark) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: AppTheme.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.book.displayTitle,
              style: AppTheme.titleMedium.copyWith(
                color: isDark ? AppTheme.white : AppTheme.grey900,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppTheme.spacing4),

            // Author
            Text(
              widget.book.author,
              style: AppTheme.bodySmall.copyWith(
                color: isDark ? AppTheme.grey400 : AppTheme.grey600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Bottom Row with Genre Info
            Row(
              children: [
                // Genre Badge
                if (widget.book.genres.isNotEmpty)
                  Flexible(
                    child: StatusTag(
                      text: widget.book.genres.first,
                      color: AppTheme.secondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
