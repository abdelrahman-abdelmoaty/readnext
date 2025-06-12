import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/storage_service.dart';
import '../../services/seed_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';
import 'help_support_screen.dart';
import '../admin/add_book_screen.dart';
import '../admin/emotion_analysis_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isUpdatingImage = false;
  Map<String, dynamic>? _userData;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditingName = false;
  bool _isEditingBio = false;

  // Admin functionality
  final UserService _userService = UserService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final userData = await authService.getUserData();

      if (mounted) {
        setState(() {
          _userData = userData;
          _nameController.text =
              _userData?['name'] ?? authService.currentUser?.displayName ?? '';
          _bioController.text = _userData?['bio'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading profile', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        final isAdmin = await _userService.isUserAdmin(user.uid);
        if (mounted) {
          setState(() => _isAdmin = isAdmin);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error checking admin status', isError: true);
      }
    }
  }

  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Permission Required',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            content: Text(
              '$permissionType permission is required to change your profile photo. Please enable it in app settings.',
              style: AppTheme.bodyLarge,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTheme.labelLarge),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('Open Settings', style: AppTheme.labelLarge),
              ),
            ],
          ),
    );
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Name cannot be empty', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);
      await context.read<AuthService>().updateUserProfile(name: newName);
      if (mounted) {
        setState(() {
          _userData = {...?_userData, 'name': newName};
          _isEditingName = false;
        });
        _showSnackBar('Name updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating name', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateBio() async {
    final newBio = _bioController.text.trim();

    try {
      setState(() => _isLoading = true);
      await context.read<AuthService>().updateUserProfile(
        bio: newBio.isEmpty ? null : newBio,
      );
      if (mounted) {
        setState(() {
          _userData = {...?_userData, 'bio': newBio.isEmpty ? null : newBio};
          _isEditingBio = false;
        });
        _showSnackBar(
          newBio.isEmpty ? 'Bio removed' : 'Bio updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating bio', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
      'Sign Out',
      'Are you sure you want to sign out?',
      actionButtonText: 'Sign Out',
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);
        final authService = context.read<AuthService>();
        await authService.signOut();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Error signing out', isError: true);
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius8),
          ),
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String content, {
    String? actionButtonText,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title, style: AppTheme.titleLarge),
            content: Text(content, style: AppTheme.bodyLarge),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: AppTheme.labelLarge),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  actionButtonText ?? 'Confirm',
                  style: AppTheme.labelLarge,
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing20,
                    AppTheme.spacing20,
                    AppTheme.spacing20,
                    AppTheme.spacing20 + 100, // Match home screen bottom margin
                  ),
                  child: Column(
                    children: [
                      _buildProfileHeader(isDark),
                      const SizedBox(height: AppTheme.spacing32),
                      _buildEditableFields(isDark),
                      const SizedBox(height: AppTheme.spacing32),
                      _buildMenuItems(isDark),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    return Container(
      padding: AppTheme.paddingAll24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Enhanced Profile Image Section
          _buildProfileImageSection(user, isDark),
          const SizedBox(height: AppTheme.spacing24),

          // Enhanced Email Info Section
          _buildEmailInfoSection(user, isDark),

          // Account Info Section
          const SizedBox(height: AppTheme.spacing16),
          _buildAccountInfoSection(user, isDark),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(dynamic user, bool isDark) {
    return Column(
      children: [
        // Profile Image with Enhanced Edit Overlay
        Stack(
          children: [
            // Main Profile Image
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.elevation3(isDark),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user?.photoURL == null
                        ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.2),
                                AppTheme.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: AppTheme.primary,
                          ),
                        )
                        : null,
              ),
            ),

            // Enhanced Edit Button
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.elevation2(isDark),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isUpdatingImage ? null : _showImageOptionsDialog,
                    child: Container(
                      padding: AppTheme.paddingAll8,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.grey800 : Colors.white,
                          width: 2,
                        ),
                      ),
                      child:
                          _isUpdatingImage
                              ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailInfoSection(dynamic user, bool isDark) {
    return Container(
      padding: AppTheme.paddingAll16,
      decoration: BoxDecoration(
        color:
            isDark
                ? AppTheme.grey800.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: isDark ? AppTheme.grey700 : AppTheme.grey200,
          width: 1,
        ),
        boxShadow: AppTheme.elevation1(isDark),
      ),
      child: Column(
        children: [
          // Email Header
          Row(
            children: [
              Container(
                padding: AppTheme.paddingAll8,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Icon(
                  Icons.email_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Address',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.grey500,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      user?.email ?? 'No email available',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.grey600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Email Verification Status
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(dynamic user, bool isDark) {
    final joinDate = user?.metadata?.creationTime;
    final lastSignIn = user?.metadata?.lastSignInTime;

    return Container(
      padding: AppTheme.paddingAll16,
      decoration: BoxDecoration(
        color:
            isDark
                ? AppTheme.grey800.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: isDark ? AppTheme.grey700 : AppTheme.grey300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Join Date
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.grey500,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Joined',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.grey500,
                    fontSize: 10,
                  ),
                ),
                Text(
                  joinDate != null ? _formatDate(joinDate) : 'Unknown',
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 40,
            width: 1,
            color: isDark ? AppTheme.grey700 : AppTheme.grey300,
          ),

          // Last Sign In
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppTheme.grey500,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Last Sign In',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.grey500,
                    fontSize: 10,
                  ),
                ),
                Text(
                  lastSignIn != null ? _formatDate(lastSignIn) : 'Unknown',
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableFields(bool isDark) {
    return Column(
      children: [
        // Editable Name Field
        _buildEditableField(
          title: 'Display Name',
          icon: Icons.person_rounded,
          controller: _nameController,
          isEditing: _isEditingName,
          placeholder: 'Enter your display name',
          onEdit: () => setState(() => _isEditingName = true),
          onSave: _updateName,
          onCancel: () {
            setState(() {
              _isEditingName = false;
              _nameController.text =
                  _userData?['name'] ??
                  context.read<AuthService>().currentUser?.displayName ??
                  '';
            });
          },
          isDark: isDark,
        ),

        const SizedBox(height: AppTheme.spacing16),

        // Editable Bio Field
        _buildEditableField(
          title: 'Bio',
          icon: Icons.edit_note_rounded,
          controller: _bioController,
          isEditing: _isEditingBio,
          placeholder: 'Tell others about yourself...',
          onEdit: () => setState(() => _isEditingBio = true),
          onSave: _updateBio,
          onCancel: () {
            setState(() {
              _isEditingBio = false;
              _bioController.text = _userData?['bio'] ?? '';
            });
          },
          isDark: isDark,
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditing,
    required String placeholder,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      padding: AppTheme.paddingAll20,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.grey800 : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color:
              isEditing
                  ? AppTheme.primary
                  : (isDark ? AppTheme.grey700 : AppTheme.grey200),
          width: isEditing ? 2 : 1,
        ),
        boxShadow: AppTheme.elevation1(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: AppTheme.paddingAll8,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isEditing)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    padding: AppTheme.paddingAll8,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Content
          if (isEditing) ...[
            TextField(
              controller: controller,
              maxLines: maxLines,
              maxLength: maxLength,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppTheme.bodyLarge.copyWith(color: AppTheme.grey500),
                filled: true,
                fillColor: isDark ? AppTheme.grey700 : AppTheme.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: AppTheme.paddingAll16,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(Icons.close_rounded, size: 18),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: Icon(Icons.check_rounded, size: 18),
                    label: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              controller.text.isNotEmpty ? controller.text : placeholder,
              style: AppTheme.bodyLarge.copyWith(
                color: controller.text.isNotEmpty ? null : AppTheme.grey500,
                fontStyle: controller.text.isNotEmpty ? null : FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItems(bool isDark) {
    return Column(
      children: [
        // Admin menu items (only show for admins)
        if (_isAdmin) ...[
          _buildMenuItem(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Admin Panel',
            subtitle: 'Manage books and content',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBookScreen()),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildMenuItem(
            icon: Icons.psychology_rounded,
            title: 'Emotion Analysis',
            subtitle: 'AI-powered review sentiment analysis',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmotionAnalysisScreen(),
                ),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(height: AppTheme.spacing12),
        ],
        _buildMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get assistance and support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
          isDark: isDark,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return _buildMenuItem(
              icon: themeService.themeModeIcon,
              title: 'Theme',
              subtitle: 'Currently: ${themeService.themeModeString}',
              onTap: () => themeService.toggleTheme(),
              isDark: isDark,
            );
          },
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'App information and version',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'ReadNext',
              applicationVersion: '1.0.0',
              applicationIcon: Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
              children: [
                Text(
                  'Discover your next great read with ReadNext.',
                  style: AppTheme.bodyMedium,
                ),
              ],
            );
          },
          isDark: isDark,
        ),
        const SizedBox(height: AppTheme.spacing12),
        // Seed Data Menu Item (Admin only)
        if (_isAdmin) ...[
          Consumer<SeedService>(
            builder: (context, seedService, child) {
              return _buildMenuItem(
                icon: Icons.dataset_rounded,
                title: 'Seed Data',
                subtitle:
                    seedService.isSeeding
                        ? 'Seeding in progress...'
                        : 'Add sample books and reviews',
                onTap:
                    seedService.isSeeding ? null : () => _showSeedDataDialog(),
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: AppTheme.spacing12),
        ],
        const SizedBox(height: AppTheme.spacing32),

        // Sign Out Button - Match auth button styles
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.error.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _signOut,
            icon: Icon(Icons.logout_rounded),
            label: Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: AppTheme.paddingV20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius16),
              ),
              minimumSize: const Size(double.infinity, 56),
              textStyle: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.grey800 : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: isDark ? AppTheme.grey700 : AppTheme.grey200,
          width: 1,
        ),
        boxShadow: AppTheme.elevation1(isDark),
      ),
      child: ListTile(
        leading: Container(
          padding: AppTheme.paddingAll8,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radius8),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(
          title,
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppTheme.grey500,
        ),
        onTap: onTap,
        contentPadding: AppTheme.paddingAll16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (date is String) {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
    } else {
      throw Exception('Unsupported date format');
    }
  }

  Future<void> _showImageOptionsDialog() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: AppTheme.paddingAll20,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radius20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing20),

                Text(
                  'Profile Photo Options',
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Camera Option
                ListTile(
                  leading: Container(
                    padding: AppTheme.paddingAll8,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(Icons.camera_alt, color: AppTheme.primary),
                  ),
                  title: Text('Take Photo', style: AppTheme.titleMedium),
                  subtitle: Text(
                    'Use camera to take a new photo',
                    style: AppTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _updateProfileImageFromSource(ImageSource.camera);
                  },
                ),

                // Gallery Option
                ListTile(
                  leading: Container(
                    padding: AppTheme.paddingAll8,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(Icons.photo_library, color: AppTheme.secondary),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Select photo from your gallery',
                    style: AppTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _updateProfileImageFromSource(ImageSource.gallery);
                  },
                ),

                // Remove Photo Option (if user has photo)
                if (context.read<AuthService>().currentUser?.photoURL != null)
                  ListTile(
                    leading: Container(
                      padding: AppTheme.paddingAll8,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                      ),
                      child: Icon(Icons.delete, color: AppTheme.error),
                    ),
                    title: Text('Remove Photo', style: AppTheme.titleMedium),
                    subtitle: Text(
                      'Remove current profile photo',
                      style: AppTheme.bodySmall,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePhoto();
                    },
                  ),

                const SizedBox(height: AppTheme.spacing16),
              ],
            ),
          ),
    );
  }

  Future<void> _updateProfileImageFromSource(ImageSource source) async {
    try {
      // Capture uid before any async operations
      final userId = context.read<AuthService>().currentUser!.uid;

      // Request appropriate permissions based on source
      PermissionStatus permission;
      if (source == ImageSource.camera) {
        permission = await Permission.camera.request();
        if (permission != PermissionStatus.granted) {
          _showSnackBar(
            'Camera permission is required to take photos',
            isError: true,
          );
          if (permission == PermissionStatus.permanentlyDenied) {
            _showPermissionDialog('Camera');
          }
          return;
        }
      } else {
        if (Platform.isAndroid) {
          permission = await Permission.photos.request();
          if (permission != PermissionStatus.granted) {
            permission = await Permission.storage.request();
          }
        } else {
          permission = await Permission.photos.request();
        }

        if (permission != PermissionStatus.granted) {
          _showSnackBar(
            'Photo library permission is required to select photos',
            isError: true,
          );
          if (permission == PermissionStatus.permanentlyDenied) {
            _showPermissionDialog('Photo Library');
          }
          return;
        }
      }

      setState(() => _isUpdatingImage = true);

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final storageService = StorageService();
        final downloadUrl = await storageService.uploadProfileImage(
          File(image.path),
          userId,
        );

        if (mounted) {
          await context.read<AuthService>().updateUserProfile(
            photoURL: downloadUrl,
          );

          await _loadUserData();
          _showSnackBar('Profile photo updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile photo: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingImage = false);
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    final confirmed = await _showConfirmDialog(
      'Remove Profile Photo',
      'Are you sure you want to remove your profile photo?',
      actionButtonText: 'Remove',
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isUpdatingImage = true);

        await context.read<AuthService>().updateUserProfile(photoURL: null);

        if (mounted) {
          await _loadUserData();
          _showSnackBar('Profile photo removed successfully');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error removing profile photo: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdatingImage = false);
        }
      }
    }
  }

  Future<void> _showSeedDataDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => Consumer<SeedService>(
            builder: (context, seedService, child) {
              return AlertDialog(
                title: Row(
                  children: [
                    Container(
                      padding: AppTheme.paddingAll8,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                      ),
                      child: Icon(
                        Icons.dataset_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        'Seed Database',
                        style: AppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (seedService.isSeeding) ...[
                        // Show progress when seeding
                        Text(
                          seedService.statusMessage,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        LinearProgressIndicator(
                          value: seedService.progress,
                          backgroundColor: AppTheme.grey200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          '${(seedService.progress * 100).toInt()}% Complete',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.grey600,
                          ),
                        ),
                      ] else ...[
                        // Show options when not seeding
                        Text(
                          'Add sample data to your database for testing and development.',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        Container(
                          padding: AppTheme.paddingAll16,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius12,
                            ),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Text(
                                    'What will be created:',
                                    style: AppTheme.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              Text(
                                '• 20 popular books with covers\n'
                                '• 50-100 realistic reviews\n'
                                '• Random likes and interactions\n'
                                '• Proper ratings and metadata',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.grey700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (seedService.statusMessage.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacing16),
                          Container(
                            padding: AppTheme.paddingAll12,
                            decoration: BoxDecoration(
                              color:
                                  seedService.statusMessage.contains('Error')
                                      ? AppTheme.error.withValues(alpha: 0.1)
                                      : AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                              border: Border.all(
                                color:
                                    seedService.statusMessage.contains('Error')
                                        ? AppTheme.error.withValues(alpha: 0.3)
                                        : AppTheme.success.withValues(
                                          alpha: 0.3,
                                        ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  seedService.statusMessage.contains('Error')
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  color:
                                      seedService.statusMessage.contains(
                                            'Error',
                                          )
                                          ? AppTheme.error
                                          : AppTheme.success,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Expanded(
                                  child: Text(
                                    seedService.statusMessage,
                                    style: AppTheme.bodySmall.copyWith(
                                      color:
                                          seedService.statusMessage.contains(
                                                'Error',
                                              )
                                              ? AppTheme.error
                                              : AppTheme.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (!seedService.isSeeding) ...[
                    // Wrap buttons in a row for better control
                    SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // First row: Clear Data and Start Seeding
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _clearSeedData(seedService),
                                  icon: Icon(Icons.delete_outline, size: 18),
                                  label: Text('Clear Data'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                    side: BorderSide(
                                      color: AppTheme.error.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppTheme.spacing12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _startSeeding(seedService),
                                  icon: Icon(Icons.play_arrow, size: 18),
                                  label: Text('Start Seeding'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppTheme.spacing12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          // Second row: Cancel button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing12,
                                ),
                              ),
                              child: Text('Cancel', style: AppTheme.labelLarge),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            seedService.progress >= 1.0
                                ? () => Navigator.pop(context)
                                : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12,
                          ),
                        ),
                        child: Text(
                          seedService.progress >= 1.0
                              ? 'Close'
                              : 'Please wait...',
                          style: AppTheme.labelLarge,
                        ),
                      ),
                    ),
                  ],
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                ),
              );
            },
          ),
    );
  }

  Future<void> _startSeeding(SeedService seedService) async {
    try {
      await seedService.seedData(bookCount: 20, reviewsPerBook: 5);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error during seeding: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _clearSeedData(SeedService seedService) async {
    final confirmed = await _showConfirmDialog(
      'Clear All Data',
      'This will permanently delete all books, reviews, and related data from the database. This action cannot be undone.',
      actionButtonText: 'Clear Data',
    );

    if (confirmed == true && mounted) {
      try {
        await seedService.clearAllData();
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error clearing data: ${e.toString()}', isError: true);
        }
      }
    }
  }
}
