import 'package:flutter/material.dart';

class EmotionChip extends StatelessWidget {
  final String? emotion;
  final double? confidence;
  final bool showConfidence;
  final double? fontSize;

  const EmotionChip({
    super.key,
    this.emotion,
    this.confidence,
    this.showConfidence = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (emotion == null || emotion!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extract emotion name and emoji
    final parts = emotion!.split(' ');
    final emotionName = parts.first;
    final emotionEmoji = parts.length > 1 ? parts.last : '';

    // Get color based on emotion
    Color chipColor = _getEmotionColor(emotionName, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emotionEmoji.isNotEmpty) ...[
            Text(emotionEmoji, style: TextStyle(fontSize: fontSize ?? 12)),
            const SizedBox(width: 4),
          ],
          Text(
            emotionName.toUpperCase(),
            style: TextStyle(
              color: chipColor,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showConfidence && confidence != null) ...[
            const SizedBox(width: 4),
            Text(
              '${confidence!.toStringAsFixed(1)}%',
              style: TextStyle(
                color: chipColor.withValues(alpha: 0.7),
                fontSize: (fontSize ?? 12) - 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getEmotionColor(String emotionName, bool isDark) {
    final baseColors = {
      'joy': Colors.teal,
      'sadness': Colors.indigo,
      'love': Colors.deepPurple,
      'anger': Colors.deepOrange,
      'fear': Colors.brown,
      'surprise': Colors.cyan,
    };

    Color baseColor = baseColors[emotionName] ?? Colors.grey;

    // Adjust for dark theme
    if (isDark) {
      return baseColor.withValues(alpha: 0.8);
    }
    return baseColor;
  }
}

// Widget for displaying emotion statistics
class EmotionStatsWidget extends StatelessWidget {
  final Map<String, int> emotionCounts;
  final Map<String, double> avgConfidences;
  final String? dominantEmotion;
  final int totalReviews;

  const EmotionStatsWidget({
    super.key,
    required this.emotionCounts,
    required this.avgConfidences,
    this.dominantEmotion,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    if (emotionCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Emotions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (dominantEmotion != null) ...[
              Text(
                'Most common emotion: ${dominantEmotion!}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  emotionCounts.entries.map((entry) {
                    final emotion = entry.key;
                    final count = entry.value;

                    return Chip(
                      label: Text(
                        '$emotion ($count)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getEmotionColor(
                        emotion,
                        theme.brightness == Brightness.dark,
                      ).withValues(alpha: 0.15),
                      side: BorderSide(
                        color: _getEmotionColor(
                          emotion,
                          theme.brightness == Brightness.dark,
                        ).withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotionName, bool isDark) {
    final baseColors = {
      'joy': Colors.teal,
      'sadness': Colors.indigo,
      'love': Colors.deepPurple,
      'anger': Colors.deepOrange,
      'fear': Colors.brown,
      'surprise': Colors.cyan,
    };

    Color baseColor = baseColors[emotionName] ?? Colors.grey;
    return isDark ? baseColor.withValues(alpha: 0.8) : baseColor;
  }
}
