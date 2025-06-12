import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            // Contact Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 48,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text('Need Help?', style: AppTheme.headlineSmall),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'We\'re here to help! Contact our support team.',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing24),

                    // Contact Methods
                    _buildContactTile(
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      subtitle: 'support@readnext.app',
                      onTap:
                          () => _showContactInfo(
                            context,
                            'Email',
                            'support@readnext.app',
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildContactTile(
                      icon: Icons.web_outlined,
                      title: 'Help Center',
                      subtitle: 'readnext.app/help',
                      onTap:
                          () => _showContactInfo(
                            context,
                            'Help Center',
                            'Visit readnext.app/help for guides and tutorials',
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Quick FAQs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: AppTheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text('Quick Help', style: AppTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    _buildFAQItem(
                      'How do I add books to my library?',
                      'Search for books in the Discover tab, then tap a book and select your reading status.',
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildFAQItem(
                      'How do I change my reading status?',
                      'Go to the book details page and tap on the reading status buttons to change it.',
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildFAQItem(
                      'How do I write a review?',
                      'On the book details page, scroll down to find the "Write a Review" section.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // App Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories, size: 40, color: AppTheme.accent),
                    const SizedBox(height: AppTheme.spacing12),
                    Text('ReadNext', style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'Version 1.0.0',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Discover your next great read',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius8),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          answer,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
        ),
      ],
    );
  }

  static void _showContactInfo(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
