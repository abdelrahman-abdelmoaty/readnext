import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showBackButton;
  final List<Widget>? actions;
  final Function(String)? onSearch;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showSearch = false,
    this.showBackButton = true,
    this.actions,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.primaryColor,
      foregroundColor: Colors.white,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
              : null,
      title:
          showSearch
              ? TextField(
                onChanged: onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                ),
              )
              : Text(title),
      actions: [if (actions != null) ...actions!],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
