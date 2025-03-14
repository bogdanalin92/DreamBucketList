import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../utils/image_upload.dart';
import 'package:http/http.dart' as http;

/// Service to handle local image storage and retrieval
class LocalImageService {
  static final LocalImageService _instance = LocalImageService._internal();

  factory LocalImageService() {
    return _instance;
  }

  LocalImageService._internal();

  /// Saves an image file to local storage and returns the local path
  Future<String> saveLocalImage(File imageFile) async {
    if (kIsWeb) {
      throw UnsupportedError('Local image saving not supported on web');
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/bucket_list_images';

      // Create the directory if it doesn't exist
      final directory = Directory(imagesDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate a unique filename
      final String fileName = '${const Uuid().v4()}.jpg';
      final String localPath = '$imagesDir/$fileName';

      // Copy the file to our app's documents directory
      final File localFile = await imageFile.copy(localPath);

      return localFile.path;
    } catch (e) {
      throw Exception('Failed to save local image: $e');
    }
  }

  /// Checks if the path is a local file path
  bool isLocalPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('/') && !path.startsWith('http');
  }

  /// Deletes a local image file
  Future<void> deleteLocalImage(String localPath) async {
    if (!isLocalPath(localPath)) return;

    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local image: $e');
    }
  }

  /// Converts a local image to a network image by uploading to Imgur
  /// Returns the URL of the uploaded image
  Future<String> convertLocalToNetworkImage(String localPath) async {
    if (!isLocalPath(localPath)) return localPath; // Already a network path

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Local image file not found');
      }

      // Use existing ImageUploader to upload the file
      final String? networkUrl = await ImageUploader.uploadImage(file);

      if (networkUrl == null || networkUrl.isEmpty) {
        throw Exception('Failed to upload image');
      }

      // Optionally delete the local file after successful upload
      // await deleteLocalImage(localPath);

      return networkUrl;
    } catch (e) {
      throw Exception('Failed to convert local to network image: $e');
    }
  }

  /// Converts a network image to local by downloading it and storing locally
  /// Returns the local file path of the downloaded image
  Future<String> convertNetworkToLocalImage(String networkUrl) async {
    if (isLocalPath(networkUrl)) return networkUrl; // Already a local path

    try {
      // Create a temporary file to download the image to
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/${const Uuid().v4()}.jpg';
      final File tempFile = File(tempPath);

      // Download the image
      final response = await http.get(Uri.parse(networkUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download image: HTTP ${response.statusCode}',
        );
      }

      // Write the response body to the file
      await tempFile.writeAsBytes(response.bodyBytes);

      // Save the downloaded image to local storage
      final String localPath = await saveLocalImage(tempFile);

      // Delete the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return localPath;
    } catch (e) {
      throw Exception('Failed to convert network to local image: $e');
    }
  }

  /// Deletes an image from Imgur using its URL
  /// Returns true if deletion was successful
  Future<bool> deleteNetworkImage(String imageUrl) async {
    if (isLocalPath(imageUrl)) return false; // Not a network image

    try {
      // Extract the image hash from the URL
      // Imgur URLs typically look like https://i.imgur.com/{hash}.{extension}
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments.last;
      final String imageHash = path.split('.').first;

      if (imageHash.isEmpty) {
        throw Exception('Could not extract image hash from URL');
      }

      // Attempt to delete the image using the ImageUploader
      final bool deleted = await ImageUploader.deleteImage(imageHash);
      return deleted;
    } catch (e) {
      debugPrint('Error deleting image from Imgur: $e');
      return false;
    }
  }
}
