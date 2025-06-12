import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusTag extends StatelessWidget {
  final String text;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsets? padding;
  final double? fontSize;

  const StatusTag({
    super.key,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? AppTheme.paddingH8.add(AppTheme.paddingV4);
    final effectiveFontSize = fontSize ?? 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: effectiveFontSize + 2, color: color),
              SizedBox(width: effectiveFontSize * 0.5),
            ],
            Text(
              text,
              style: AppTheme.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: effectiveFontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class SelectableStatusTag extends StatelessWidget {
  final String text;
  final String description;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDisabled;

  const SelectableStatusTag({
    super.key,
    required this.text,
    required this.description,
    required this.color,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Material(
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
          onTap: isDisabled || isSelected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: AppTheme.paddingAll20,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: AppTheme.paddingAll12,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: AppTheme.titleMedium.copyWith(
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppTheme.white
                                      : AppTheme.grey900),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        description,
                        style: AppTheme.bodySmall.copyWith(
                          color:
                              isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : (isDark
                                      ? AppTheme.grey400
                                      : AppTheme.grey600),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: AppTheme.paddingAll8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
