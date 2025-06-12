import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../services/user_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../widgets/custom_app_bar.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final BookService _bookService = BookService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _languageController = TextEditingController();

  // Form state
  final List<String> _selectedGenres = [];
  DateTime _publishedDate = DateTime.now();
  bool _isLoading = false;
  bool _isAdmin = false;

  // Image picker state
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  // Available genres
  final List<String> _availableGenres = [
    'Fiction',
    'Non-fiction',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Fantasy',
    'Thriller',
    'Biography',
    'History',
    'Science',
    'Self-help',
    'Business',
    'Philosophy',
    'Poetry',
    'Drama',
    'Horror',
    'Adventure',
    'Comedy',
    'Crime',
    'Young Adult',
    'Children',
    'Educational',
    'Religion',
    'Health',
    'Travel',
    'Cooking',
    'Art',
    'Music',
    'Sports',
    'Technology',
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _languageController.text = 'English'; // Default language
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _pageCountController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _userService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });

      if (!isAdmin) {
        // Redirect non-admin users
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access denied: Admin privileges required'),
              backgroundColor: AppTheme.error,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      Logger.screenDebug('AddBookScreen', 'Error checking admin status', e);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGenres.isEmpty) {
      _showSnackBar('Please select at least one genre', AppTheme.error);
      return;
    }

    if (_selectedImage == null) {
      _showSnackBar('Please select a cover image', AppTheme.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Firebase Storage
      String coverUrl;
      if (_uploadedImageUrl != null) {
        // Use already uploaded URL
        coverUrl = _uploadedImageUrl!;
      } else {
        // Upload the selected image
        final userId = context.read<AuthService>().currentUser?.uid;
        if (userId == null) {
          throw Exception('User not logged in');
        }

        coverUrl = await _storageService.uploadFile(
          file: _selectedImage!,
          folder: 'book_covers',
          fileName:
              '${DateTime.now().millisecondsSinceEpoch}_${_titleController.text.trim().replaceAll(' ', '_')}.jpg',
          contentType: 'image/jpeg',
          metadata: {
            'bookTitle': _titleController.text.trim(),
            'uploadedBy': userId,
          },
        );

        setState(() {
          _uploadedImageUrl = coverUrl;
        });
      }

      final bookId = await _bookService.addBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverUrl: coverUrl,
        genres: _selectedGenres,
        pageCount: int.parse(_pageCountController.text.trim()),
        publishedDate: _publishedDate,
        isbn:
            _isbnController.text.trim().isEmpty
                ? null
                : _isbnController.text.trim(),
        publisher:
            _publisherController.text.trim().isEmpty
                ? null
                : _publisherController.text.trim(),
        language: _languageController.text.trim(),
      );

      Logger.userAction('Admin added new book', {
        'bookId': bookId,
        'title': _titleController.text.trim(),
      });

      _showSnackBar('Book added successfully!', AppTheme.success);

      // Clear form or navigate back
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      Logger.screenDebug('AddBookScreen', 'Error adding book', e);
      _showSnackBar('Error adding book: $e', AppTheme.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _publishedDate,
      firstDate: DateTime(1000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _publishedDate) {
      setState(() {
        _publishedDate = picked;
      });
    }
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
      appBar: const CustomAppBar(title: 'Add New Book'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppTheme.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildSectionHeader(
                'Book Information',
                'Add a new book to the library',
                Icons.library_add_rounded,
              ),

              const SizedBox(height: AppTheme.spacing24),

              // Basic Info Section
              _buildCard([
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Enter book title',
                  icon: Icons.title_rounded,
                  required: true,
                ),
                const SizedBox(height: AppTheme.spacing16),
                _buildTextField(
                  controller: _authorController,
                  label: 'Author',
                  hint: 'Enter author name',
                  icon: Icons.person_rounded,
                  required: true,
                ),
                const SizedBox(height: AppTheme.spacing16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter book description',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  required: true,
                ),
              ]),

              const SizedBox(height: AppTheme.spacing24),

              // Cover and Details Section
              _buildCard([
                _buildImagePicker(),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _pageCountController,
                        label: 'Page Count',
                        hint: 'Number of pages',
                        icon: Icons.menu_book_rounded,
                        keyboardType: TextInputType.number,
                        required: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter page count';
                          }
                          final pages = int.tryParse(value);
                          if (pages == null || pages <= 0) {
                            return 'Please enter a valid page count';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildTextField(
                        controller: _languageController,
                        label: 'Language',
                        hint: 'Book language',
                        icon: Icons.language_rounded,
                        required: true,
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: AppTheme.spacing24),

              // Publication Info Section
              _buildCard([
                _buildDateSelector(),
                const SizedBox(height: AppTheme.spacing16),
                _buildTextField(
                  controller: _isbnController,
                  label: 'ISBN (Optional)',
                  hint: 'Enter ISBN',
                  icon: Icons.qr_code_rounded,
                ),
                const SizedBox(height: AppTheme.spacing16),
                _buildTextField(
                  controller: _publisherController,
                  label: 'Publisher (Optional)',
                  hint: 'Enter publisher name',
                  icon: Icons.business_rounded,
                ),
              ]),

              const SizedBox(height: AppTheme.spacing24),

              // Genres Section
              _buildGenreSelector(),

              const SizedBox(height: AppTheme.spacing32),

              // Submit Button
              _buildSubmitButton(),

              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
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

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: AppTheme.elevation2(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      padding: AppTheme.paddingAll20,
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppTheme.grey800
                : AppTheme.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.grey700
                    : AppTheme.grey200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          borderSide: BorderSide(color: AppTheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          borderSide: BorderSide(color: AppTheme.error, width: 2),
        ),
        contentPadding: AppTheme.paddingAll16,
      ),
      validator:
          validator ??
          (required
              ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
              : null),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(AppTheme.radius12),
      child: Container(
        padding: AppTheme.paddingAll16,
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.grey800
                  : AppTheme.grey50,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.grey700
                    : AppTheme.grey200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Published Date',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${_publishedDate.day}/${_publishedDate.month}/${_publishedDate.year}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.grey500),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _isUploadingImage ? null : _pickImage,
      borderRadius: BorderRadius.circular(AppTheme.radius12),
      child: Container(
        padding: AppTheme.paddingAll16,
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.grey800
                  : AppTheme.grey50,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(
            color:
                _selectedImage != null
                    ? AppTheme.primary
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.grey700
                        : AppTheme.grey200),
            width: _selectedImage != null ? 2 : 1,
          ),
        ),
        child:
            _isUploadingImage
                ? Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Text('Selecting image...', style: AppTheme.bodyMedium),
                  ],
                )
                : _selectedImage != null
                ? Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                      child: Image.file(
                        _selectedImage!,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cover Image Selected',
                            style: AppTheme.labelMedium.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            'Tap to change image',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_rounded, color: AppTheme.primary),
                  ],
                )
                : Row(
                  children: [
                    Icon(Icons.image_rounded, color: AppTheme.primary),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cover Image',
                            style: AppTheme.labelMedium.copyWith(
                              color: AppTheme.grey600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            'Tap to select cover image',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.add_a_photo_rounded, color: AppTheme.primary),
                  ],
                ),
      ),
    );
  }

  Widget _buildGenreSelector() {
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
              Icon(Icons.category_rounded, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Genres',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Select at least one genre',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children:
                _availableGenres.map((genre) {
                  final isSelected = _selectedGenres.contains(genre);
                  return FilterChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.grey800
                            : AppTheme.grey100,
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : null,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.grey300,
                      width: isSelected ? 2 : 1,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
          ),
          elevation: 2,
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
                : Icon(Icons.add_rounded, size: 24),
        label: Text(
          _isLoading ? 'Adding Book...' : 'Add Book',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      // Show image source selection
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      // Request appropriate permissions
      PermissionStatus permission;
      if (source == ImageSource.camera) {
        permission = await Permission.camera.request();
        if (permission != PermissionStatus.granted) {
          _showSnackBar('Camera permission is required', AppTheme.error);
          return;
        }
      } else {
        // Gallery permission
        if (Platform.isAndroid) {
          permission = await Permission.photos.request();
          if (permission != PermissionStatus.granted) {
            permission = await Permission.storage.request();
          }
        } else {
          permission = await Permission.photos.request();
        }

        if (permission != PermissionStatus.granted) {
          _showSnackBar('Photo library permission is required', AppTheme.error);
          return;
        }
      }

      setState(() {
        _isUploadingImage = true;
      });

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUrl = null; // Clear any previously uploaded URL
        });
        _showSnackBar('Image selected successfully', AppTheme.success);
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', AppTheme.error);
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Choose Image Source',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: AppTheme.paddingAll8,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(Icons.camera_alt, color: AppTheme.primary),
                  ),
                  title: Text('Camera', style: AppTheme.titleMedium),
                  subtitle: Text('Take a new photo', style: AppTheme.bodySmall),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: AppTheme.spacing8),
                ListTile(
                  leading: Container(
                    padding: AppTheme.paddingAll8,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(Icons.photo_library, color: AppTheme.secondary),
                  ),
                  title: Text('Gallery', style: AppTheme.titleMedium),
                  subtitle: Text(
                    'Choose from gallery',
                    style: AppTheme.bodySmall,
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTheme.labelLarge),
              ),
            ],
          ),
    );
  }
}
