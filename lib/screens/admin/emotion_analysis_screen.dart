import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import '../../services/emotion_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/emotion_chip.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';

class EmotionAnalysisScreen extends StatefulWidget {
  const EmotionAnalysisScreen({super.key});

  @override
  State<EmotionAnalysisScreen> createState() => _EmotionAnalysisScreenState();
}

class _EmotionAnalysisScreenState extends State<EmotionAnalysisScreen> {
  final BookService _bookService = BookService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _isAdmin = false;
  bool _isServiceAvailable = false;

  int _analyzedCount = 0;
  String _statusMessage = '';
  double _progress = 0.0;

  final TextEditingController _bookIdController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _testTextController = TextEditingController();

  String? _testEmotion;
  double? _testConfidence;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _checkServiceAvailability();
    _limitController.text = '50'; // Default limit
  }

  @override
  void dispose() {
    _bookIdController.dispose();
    _limitController.dispose();
    _testTextController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _userService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });

      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Access denied: Admin privileges required'),
              backgroundColor: AppTheme.error,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      Logger.screenDebug(
        'EmotionAnalysisScreen',
        'Error checking admin status',
        e,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _checkServiceAvailability() async {
    setState(() => _isLoading = true);
    try {
      final isAvailable = await EmotionService.isServiceAvailable();
      setState(() {
        _isServiceAvailable = isAvailable;
        _statusMessage =
            isAvailable
                ? 'Emotion service is available and ready'
                : 'Emotion service is currently unavailable';
      });
    } catch (e) {
      setState(() {
        _isServiceAvailable = false;
        _statusMessage = 'Error checking service availability: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeExistingReviews() async {
    if (!_isServiceAvailable) {
      _showSnackBar('Emotion service is not available', AppTheme.error);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _progress = 0.0;
      _statusMessage = 'Starting emotion analysis...';
    });

    try {
      final bookId =
          _bookIdController.text.trim().isEmpty
              ? null
              : _bookIdController.text.trim();
      final limit = int.tryParse(_limitController.text.trim());

      Logger.userAction('Admin started emotion analysis', {
        'bookId': bookId,
        'limit': limit,
      });

      final analyzedCount = await _bookService.analyzeExistingReviewEmotions(
        bookId: bookId,
        limit: limit,
      );

      setState(() {
        _analyzedCount = analyzedCount;
        _statusMessage = 'Analysis completed! Analyzed $analyzedCount reviews.';
        _progress = 1.0;
      });

      _showSnackBar(
        'Successfully analyzed $analyzedCount reviews',
        AppTheme.success,
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during analysis: $e';
      });
      _showSnackBar('Error analyzing reviews: $e', AppTheme.error);
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _testEmotionPrediction() async {
    if (!_isServiceAvailable) {
      _showSnackBar('Emotion service is not available', AppTheme.error);
      return;
    }

    final text = _testTextController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter some text to test', AppTheme.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emotionData = await EmotionService.predictEmotion(text);

      if (emotionData != null) {
        setState(() {
          _testEmotion = emotionData.emotion;
          _testConfidence = emotionData.confidence;
        });
        _showSnackBar('Emotion prediction successful!', AppTheme.success);
      } else {
        _showSnackBar('Failed to predict emotion', AppTheme.error);
      }
    } catch (e) {
      _showSnackBar('Error testing emotion: $e', AppTheme.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Access Denied'),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Emotion Analysis'),
      body: SingleChildScrollView(
        padding: AppTheme.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildSectionHeader(
              'AI Emotion Analysis',
              'Analyze emotions in book reviews using machine learning',
              Icons.psychology_rounded,
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Service Status Card
            _buildServiceStatusCard(),

            const SizedBox(height: AppTheme.spacing24),

            // Test Emotion Prediction Card
            _buildTestCard(),

            const SizedBox(height: AppTheme.spacing24),

            // Batch Analysis Card
            _buildBatchAnalysisCard(),

            const SizedBox(height: AppTheme.spacing24),

            // Analysis Results Card
            if (_analyzedCount > 0 || _statusMessage.isNotEmpty)
              _buildResultsCard(),

            const SizedBox(height: AppTheme.spacing24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: AppTheme.paddingAll12,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                subtitle,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: AppTheme.elevation2(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      padding: AppTheme.paddingAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return _buildCard('Service Status', Icons.cloud_rounded, [
      Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isServiceAvailable ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              _isServiceAvailable
                  ? 'Emotion API is online and ready'
                  : 'Emotion API is currently unavailable',
              style: AppTheme.bodyMedium.copyWith(
                color: _isServiceAvailable ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppTheme.primary),
              onPressed: _checkServiceAvailability,
              tooltip: 'Refresh status',
            ),
        ],
      ),
      if (_statusMessage.isNotEmpty) ...[
        const SizedBox(height: AppTheme.spacing8),
        Text(
          _statusMessage,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
        ),
      ],
    ]);
  }

  Widget _buildTestCard() {
    return _buildCard('Test Emotion Prediction', Icons.science_rounded, [
      TextField(
        controller: _testTextController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              'Enter text to analyze emotion (e.g., "I loved this book!")',
          filled: true,
          fillColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.grey800
                  : AppTheme.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacing16),

      if (_testEmotion != null) ...[
        Row(
          children: [
            Text(
              'Result: ',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            EmotionChip(
              emotion: _testEmotion,
              confidence: _testConfidence,
              showConfidence: true,
              fontSize: 14,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
      ],

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              (_isLoading || !_isServiceAvailable)
                  ? null
                  : _testEmotionPrediction,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
          ),
          icon:
              _isLoading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(Icons.psychology_rounded),
          label: Text(_isLoading ? 'Analyzing...' : 'Test Emotion'),
        ),
      ),
    ]);
  }

  Widget _buildBatchAnalysisCard() {
    return _buildCard('Batch Analysis', Icons.batch_prediction_rounded, [
      TextField(
        controller: _bookIdController,
        decoration: InputDecoration(
          labelText: 'Book ID (Optional)',
          hintText: 'Leave empty to analyze all books',
          filled: true,
          fillColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.grey800
                  : AppTheme.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacing16),

      TextField(
        controller: _limitController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Limit',
          hintText: 'Maximum number of reviews to analyze',
          filled: true,
          fillColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.grey800
                  : AppTheme.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacing16),

      if (_isAnalyzing) ...[
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppTheme.grey300,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          _statusMessage,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
        ),
        const SizedBox(height: AppTheme.spacing16),
      ],

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              (_isAnalyzing || !_isServiceAvailable)
                  ? null
                  : _analyzeExistingReviews,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
          ),
          icon:
              _isAnalyzing
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(Icons.auto_fix_high_rounded),
          label: Text(
            _isAnalyzing ? 'Analyzing Reviews...' : 'Start Batch Analysis',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildResultsCard() {
    return _buildCard('Analysis Results', Icons.analytics_rounded, [
      if (_analyzedCount > 0) ...[
        Container(
          padding: AppTheme.paddingAll16,
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Complete',
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                    Text(
                      'Successfully analyzed $_analyzedCount reviews',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      if (_statusMessage.isNotEmpty) ...[
        const SizedBox(height: AppTheme.spacing12),
        Text(
          _statusMessage,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
        ),
      ],
    ]);
  }
}
