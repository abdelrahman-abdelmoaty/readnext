import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T value;
  final List<CustomDropdownItem<T>> items;
  final void Function(T?) onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
    this.isExpanded = true,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppTheme.grey800 : AppTheme.grey50),
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radius12),
        border: Border.all(
          color: borderColor ?? (isDark ? AppTheme.grey700 : AppTheme.grey300),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppTheme.grey900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: isExpanded,
          hint:
              hint != null
                  ? Text(
                    hint!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: isDark ? AppTheme.grey400 : AppTheme.grey500,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  : null,
          style: AppTheme.bodyMedium.copyWith(
            color: isDark ? AppTheme.white : AppTheme.grey900,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: isDark ? AppTheme.grey700 : AppTheme.white,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.expand_more_rounded,
              color: AppTheme.primary,
              size: 16,
            ),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          elevation: 8,
          items:
              items.map((CustomDropdownItem<T> item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing8,
                      horizontal: AppTheme.spacing4,
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (item.iconColor ?? AppTheme.primary)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              item.icon,
                              size: 16,
                              color: item.iconColor ?? AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                        ] else if (prefixIcon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              prefixIcon,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: AppTheme.bodyMedium.copyWith(
                              color: isDark ? AppTheme.white : AppTheme.grey900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.trailing != null) ...[
                          const SizedBox(width: AppTheme.spacing8),
                          item.trailing!,
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class CustomDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const CustomDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.trailing,
  });
}
