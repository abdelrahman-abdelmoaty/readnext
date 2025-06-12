import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final bool showMessage;
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.showMessage = true,
    this.color,
    this.size = 24,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        widget.color ?? (isDark ? AppTheme.primaryLight : AppTheme.primary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    effectiveColor.withValues(alpha: 0.1),
                    effectiveColor.withValues(alpha: 0.3),
                    effectiveColor,
                    effectiveColor.withValues(alpha: 0.3),
                    effectiveColor.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  transform: GradientRotation(_animation.value * 2 * 3.14159),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppTheme.grey800 : AppTheme.white,
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showMessage && widget.message != null) ...[
          const SizedBox(height: AppTheme.spacing12),
          Text(
            widget.message!,
            style: AppTheme.bodySmall.copyWith(
              color: isDark ? AppTheme.grey400 : AppTheme.grey600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class BookCardSkeleton extends StatefulWidget {
  const BookCardSkeleton({super.key});

  @override
  State<BookCardSkeleton> createState() => _BookCardSkeletonState();
}

class _BookCardSkeletonState extends State<BookCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.grey800 : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        boxShadow: AppTheme.elevation1(isDark),
        border: Border.all(
          color: isDark ? AppTheme.grey700 : AppTheme.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover skeleton
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radius20),
                ),
                color: isDark ? AppTheme.grey700 : AppTheme.grey200,
              ),
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radius20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
                        end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
                        colors: [
                          (isDark ? AppTheme.grey700 : AppTheme.grey200),
                          (isDark ? AppTheme.grey600 : AppTheme.grey100),
                          (isDark ? AppTheme.grey700 : AppTheme.grey200),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Info skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radius8),
                          gradient: LinearGradient(
                            begin: Alignment(
                              -1.0 + _shimmerAnimation.value * 2,
                              0,
                            ),
                            end: Alignment(
                              1.0 + _shimmerAnimation.value * 2,
                              0,
                            ),
                            colors: [
                              (isDark ? AppTheme.grey700 : AppTheme.grey200),
                              (isDark ? AppTheme.grey600 : AppTheme.grey100),
                              (isDark ? AppTheme.grey700 : AppTheme.grey200),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing8),

                  // Author skeleton
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 12,
                        width: double.infinity * 0.7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radius8),
                          gradient: LinearGradient(
                            begin: Alignment(
                              -1.0 + _shimmerAnimation.value * 2,
                              0,
                            ),
                            end: Alignment(
                              1.0 + _shimmerAnimation.value * 2,
                              0,
                            ),
                            colors: [
                              (isDark ? AppTheme.grey700 : AppTheme.grey200),
                              (isDark ? AppTheme.grey600 : AppTheme.grey100),
                              (isDark ? AppTheme.grey700 : AppTheme.grey200),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Bottom badges skeleton
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius8,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment(
                                    -1.0 + _shimmerAnimation.value * 2,
                                    0,
                                  ),
                                  end: Alignment(
                                    1.0 + _shimmerAnimation.value * 2,
                                    0,
                                  ),
                                  colors: [
                                    (isDark
                                        ? AppTheme.grey700
                                        : AppTheme.grey200),
                                    (isDark
                                        ? AppTheme.grey600
                                        : AppTheme.grey100),
                                    (isDark
                                        ? AppTheme.grey700
                                        : AppTheme.grey200),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment(
                                  -1.0 + _shimmerAnimation.value * 2,
                                  0,
                                ),
                                end: Alignment(
                                  1.0 + _shimmerAnimation.value * 2,
                                  0,
                                ),
                                colors: [
                                  (isDark
                                      ? AppTheme.grey700
                                      : AppTheme.grey200),
                                  (isDark
                                      ? AppTheme.grey600
                                      : AppTheme.grey100),
                                  (isDark
                                      ? AppTheme.grey700
                                      : AppTheme.grey200),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridLoadingWidget extends StatelessWidget {
  final int itemCount;

  const GridLoadingWidget({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const BookCardSkeleton();
        },
      ),
    );
  }
}
