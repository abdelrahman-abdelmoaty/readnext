import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final userData = await authService.getUserData();
      if (mounted) {
        setState(() {
          _preferences =
              userData?['preferences'] ??
              {
                'notifications': true,
                'darkMode': false,
                'language': 'English',
                'autoSync': true,
                'downloadWifi': true,
                'readingReminders': true,
              };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    setState(() {
      _preferences = {..._preferences!, key: value};
    });

    try {
      final authService = context.read<AuthService>();
      await authService.updateUserPreferences(_preferences!);
    } catch (e) {
      // Revert the change if update fails
      setState(() {
        _preferences = {..._preferences!, key: !value};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLanguageSelector() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Italian'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                languages.map((language) {
                  return RadioListTile<String>(
                    title: Text(language),
                    value: language,
                    groupValue: _preferences?['language'] ?? 'English',
                    onChanged: (String? value) {
                      Navigator.pop(context);
                      if (value != null) {
                        _updatePreference('language', value);
                      }
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();

                try {
                  final userService = UserService();
                  await userService.deleteUserAccount();

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate to login screen
                    navigator.pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error deleting account: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Passwords do not match'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);
                            final navigator = Navigator.of(context);
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            try {
                              final authService = context.read<AuthService>();
                              await authService.changePassword(
                                currentPassword: currentPasswordController.text,
                                newPassword: newPasswordController.text,
                              );

                              if (mounted) {
                                navigator.pop();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password changed successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'Privacy Policy\n\n'
              'Read Next is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.\n\n'
              'Information We Collect:\n'
              '• Account information (email, name)\n'
              '• Reading preferences and history\n'
              '• Book reviews and ratings\n'
              '• Usage analytics\n\n'
              'How We Use Your Information:\n'
              '• To provide and improve our services\n'
              '• To personalize your reading experience\n'
              '• To send notifications about new books\n'
              '• To analyze app usage and performance\n\n'
              'Data Security:\n'
              'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.\n\n'
              'Contact Us:\n'
              'If you have any questions about this Privacy Policy, please contact us at privacy@readnext.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const SingleChildScrollView(
            child: Text(
              'Terms of Service\n\n'
              'Welcome to Read Next. By using our app, you agree to these terms.\n\n'
              'Acceptable Use:\n'
              '• You must be at least 13 years old to use this app\n'
              '• You are responsible for maintaining account security\n'
              '• You may not use the app for illegal purposes\n'
              '• You may not spam or harass other users\n\n'
              'Content:\n'
              '• You retain ownership of content you create\n'
              '• You grant us license to use your content within the app\n'
              '• We may remove content that violates our guidelines\n\n'
              'Disclaimers:\n'
              '• The app is provided "as is" without warranties\n'
              '• We are not liable for any damages from app use\n'
              '• Book information may not always be accurate\n\n'
              'Changes:\n'
              'We may update these terms at any time. Continued use constitutes acceptance of new terms.\n\n'
              'Contact:\n'
              'Questions? Contact us at legal@readnext.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings', showBackButton: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Notifications Section
                  _SectionHeader(title: 'Notifications'),
                  Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications,
                          title: 'Push Notifications',
                          subtitle:
                              'Receive notifications about new books and updates',
                          trailing: Switch(
                            value: _preferences?['notifications'] ?? true,
                            onChanged:
                                (value) =>
                                    _updatePreference('notifications', value),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.schedule,
                          title: 'Reading Reminders',
                          subtitle: 'Get reminders to read your books',
                          trailing: Switch(
                            value: _preferences?['readingReminders'] ?? true,
                            onChanged:
                                (value) => _updatePreference(
                                  'readingReminders',
                                  value,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Appearance Section
                  _SectionHeader(title: 'Appearance'),
                  Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.dark_mode,
                          title: 'Dark Mode',
                          subtitle: 'Switch to dark theme',
                          trailing: Switch(
                            value: _preferences?['darkMode'] ?? false,
                            onChanged:
                                (value) => _updatePreference('darkMode', value),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: _preferences?['language'] ?? 'English',
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _showLanguageSelector,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Data & Sync Section
                  _SectionHeader(title: 'Data & Sync'),
                  Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.sync,
                          title: 'Auto Sync',
                          subtitle: 'Automatically sync your data',
                          trailing: Switch(
                            value: _preferences?['autoSync'] ?? true,
                            onChanged:
                                (value) => _updatePreference('autoSync', value),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.wifi,
                          title: 'Download on WiFi Only',
                          subtitle:
                              'Only download content when connected to WiFi',
                          trailing: Switch(
                            value: _preferences?['downloadWifi'] ?? true,
                            onChanged:
                                (value) =>
                                    _updatePreference('downloadWifi', value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Section
                  _SectionHeader(title: 'Account'),
                  Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.lock,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _showChangePasswordDialog,
                        ),
                        _SettingsTile(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showPrivacyPolicy();
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.description,
                          title: 'Terms of Service',
                          subtitle: 'Read our terms of service',
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showTermsOfService();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Danger Zone
                  _SectionHeader(title: 'Danger Zone'),
                  Card(
                    child: _SettingsTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account and all data',
                      trailing: const Icon(Icons.arrow_forward_ios),
                      iconColor: Colors.red,
                      titleColor: Colors.red,
                      onTap: _showDeleteAccountDialog,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Read Next',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Built with ❤️ for book lovers',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
