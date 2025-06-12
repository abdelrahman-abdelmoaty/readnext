import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a profile image and return the download URL
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      Logger.serviceDebug('StorageService', 'Starting profile image upload');

      // Create a unique filename
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Reference to the storage location
      final Reference ref = _storage
          .ref()
          .child('profile_images')
          .child(fileName);

      // Upload the file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get the download URL
        final String downloadUrl = await ref.getDownloadURL();
        Logger.serviceDebug(
          'StorageService',
          'Profile image uploaded successfully',
        );
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      Logger.serviceDebug('StorageService', 'Error uploading profile image', e);
      rethrow;
    }
  }

  /// Delete a profile image
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      Logger.serviceDebug('StorageService', 'Deleting profile image');

      // Get reference from URL
      final Reference ref = _storage.refFromURL(imageUrl);

      // Delete the file
      await ref.delete();

      Logger.serviceDebug(
        'StorageService',
        'Profile image deleted successfully',
      );
    } catch (e) {
      Logger.serviceDebug('StorageService', 'Error deleting profile image', e);
      rethrow;
    }
  }

  /// Upload any file and return the download URL
  Future<String> uploadFile({
    required File file,
    required String folder,
    required String fileName,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      Logger.serviceDebug('StorageService', 'Starting file upload: $fileName');

      // Reference to the storage location
      final Reference ref = _storage.ref().child(folder).child(fileName);

      // Prepare metadata
      final Map<String, String> customMetadata = {
        'uploadedAt': DateTime.now().toIso8601String(),
        ...?metadata,
      };

      // Upload the file
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: customMetadata,
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get the download URL
        final String downloadUrl = await ref.getDownloadURL();
        Logger.serviceDebug(
          'StorageService',
          'File uploaded successfully: $fileName',
        );
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      Logger.serviceDebug(
        'StorageService',
        'Error uploading file: $fileName',
        e,
      );
      rethrow;
    }
  }

  /// Delete a file by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      Logger.serviceDebug('StorageService', 'Deleting file');

      // Get reference from URL
      final Reference ref = _storage.refFromURL(fileUrl);

      // Delete the file
      await ref.delete();

      Logger.serviceDebug('StorageService', 'File deleted successfully');
    } catch (e) {
      Logger.serviceDebug('StorageService', 'Error deleting file', e);
      rethrow;
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      Logger.serviceDebug('StorageService', 'Error getting file metadata', e);
      rethrow;
    }
  }
}
