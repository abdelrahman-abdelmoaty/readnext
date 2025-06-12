import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

class EmotionData {
  final String emotion;
  final double confidence;
  final String message;

  EmotionData({
    required this.emotion,
    required this.confidence,
    required this.message,
  });

  factory EmotionData.fromJson(Map<String, dynamic> json) {
    return EmotionData(
      emotion: json['emotion']?.toString() ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      message: json['message']?.toString() ?? '',
    );
  }

  /// Factory for warning/empty responses (e.g., only "detail" present)
  factory EmotionData.warning(String message) {
    return EmotionData(
      emotion: 'unknown',
      confidence: 0.0,
      message: message,
    );
  }

  Map<String, dynamic> toJson() {
    return {'emotion': emotion, 'confidence': confidence, 'message': message};
  }

  // Extract just the emotion name without emoji
  String get emotionName {
    return emotion.split(' ').first;
  }

  // Extract just the emoji
  String get emotionEmoji {
    final parts = emotion.split(' ');
    return parts.length > 1 ? parts.last : '';
  }
}

class EmotionService {
  static const String _baseUrl =
      'https://emotion-classifier-production.up.railway.app';
  static const Duration _timeout = Duration(seconds: 10);

  // Predict emotion from text
  static Future<EmotionData?> predictEmotion(String text) async {
    try {
      if (text.trim().isEmpty) {
        Logger.serviceDebug(
          'EmotionService',
          'Empty text provided for emotion prediction',
        );
        return null;
      }

      // Encode the text for URL
      final encodedText = Uri.encodeComponent(text.trim());
      final url = Uri.parse('$_baseUrl/predict?text=$encodedText');

      Logger.serviceDebug(
        'EmotionService',
        'Making emotion prediction request',
        {'text_length': text.length, 'url': url.toString()},
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Handle case where only a warning/detail is returned (see image)
        if (jsonData is Map<String, dynamic> &&
            jsonData.length == 1 &&
            jsonData.containsKey('detail')) {
          Logger.serviceDebug('EmotionService', 'Received warning/detail from API', {
            'detail': jsonData['detail'],
          });
          return EmotionData.warning(jsonData['detail']?.toString() ?? 'Unknown warning');
        }

        final emotionData = EmotionData.fromJson(jsonData);

        Logger.serviceDebug('EmotionService', 'Emotion prediction successful', {
          'emotion': emotionData.emotion,
          'confidence': emotionData.confidence,
        });

        return emotionData;
      } else {
        Logger.serviceDebug('EmotionService', 'Emotion API error', {
          'status_code': response.statusCode,
          'body': response.body,
        });
        return null;
      }
    } catch (e) {
      Logger.serviceDebug('EmotionService', 'Error predicting emotion', e);
      return null;
    }
  }

  // Predict emotion with retry mechanism
  static Future<EmotionData?> predictEmotionWithRetry(
    String text, {
    int maxRetries = 2,
  }) async {
    for (int i = 0; i <= maxRetries; i++) {
      final result = await predictEmotion(text);
      if (result != null) {
        return result;
      }

      if (i < maxRetries) {
        Logger.serviceDebug('EmotionService', 'Retrying emotion prediction', {
          'attempt': i + 1,
        });
        await Future.delayed(Duration(seconds: i + 1)); // Exponential backoff
      }
    }

    Logger.serviceDebug(
      'EmotionService',
      'Failed to predict emotion after retries',
    );
    return null;
  }

  // Batch predict emotions for multiple texts
  static Future<List<EmotionData?>> batchPredictEmotions(
    List<String> texts,
  ) async {
    final List<EmotionData?> results = [];

    for (final text in texts) {
      final emotion = await predictEmotion(text);
      results.add(emotion);

      // Add small delay between requests to avoid overwhelming the API
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return results;
  }

  // Check if emotion service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final testEmotion = await predictEmotion('I am happy');
      return testEmotion != null;
    } catch (e) {
      return false;
    }
  }
}
