import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/preferences_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ImageUploader {
  static const String _imgurApiUrl = 'https://api.imgur.com/3/image';
  static const String _clientId = 'e5d3a307c49f160';
  static const String _clientSecret =
      '03f97a2ca6dd400ae4f22eee66b78dbb581243b4';
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  /// Uploads an image to Imgur and returns the URL of the uploaded image.
  /// Returns null if consent is not given or if upload fails.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Check for consent
      final preferencesService = await PreferencesService.getInstance();
      if (!preferencesService.getPhotoConsent()) {
        throw Exception('Photo storage consent not given');
      }

      // Validate file exists and size
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      if (fileSize > _maxFileSizeBytes) {
        throw Exception('Image file is too large (max 10MB)');
      }

      // Read file as bytes to validate it's a proper image
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Could not read image file');
      }

      // Create a multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_imgurApiUrl));
      request.headers['Authorization'] = 'Client-ID $_clientId';

      // Add the file as bytes instead of path
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.path.split('/').last,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);

        // Store the deleteHash in preferences for future deletion
        final String deleteHash = jsonData['data']['deletehash'];
        final String imageId = jsonData['data']['id'];
        await _saveDeleteHash(imageId, deleteHash);

        return jsonData['data']['link'];
      } else {
        throw Exception(
          'Upload failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Deletes an image from Imgur using its image hash or delete hash.
  /// Returns true if deletion was successful.
  static Future<bool> deleteImage(String imageHash) async {
    try {
      // First try to get the delete hash from preferences
      final deleteHash = await _getDeleteHash(imageHash);

      // If we have the delete hash, we can delete the image using client ID
      if (deleteHash != null) {
        return await _deleteWithHash(deleteHash);
      }

      // If we don't have the delete hash stored, we can't delete it
      // as we need authorization for that
      debugPrint('No delete hash found for image: $imageHash');
      return false;
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      return false;
    }
  }

  /// Deletes an image using the delete hash
  static Future<bool> _deleteWithHash(String deleteHash) async {
    try {
      final url = 'https://api.imgur.com/3/image/$deleteHash';
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Client-ID $_clientId'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        debugPrint('Delete failed with status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Saves the delete hash for an image
  static Future<void> _saveDeleteHash(String imageId, String deleteHash) async {
    try {
      final preferencesService = await PreferencesService.getInstance();
      await preferencesService.saveDeleteHash(imageId, deleteHash);
    } catch (e) {
      debugPrint('Failed to save delete hash: $e');
    }
  }

  /// Gets the delete hash for an image
  static Future<String?> _getDeleteHash(String imageId) async {
    try {
      final preferencesService = await PreferencesService.getInstance();
      return preferencesService.getDeleteHash(imageId);
    } catch (e) {
      debugPrint('Failed to get delete hash: $e');
      return null;
    }
  }
}
