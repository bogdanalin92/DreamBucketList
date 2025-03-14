import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/preferences_service.dart';
import '../services/local_image_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'image_upload.dart';

class ImagePickerHelper {
  /// Checks and requests permission to access photos
  static Future<bool> _requestPhotoPermission(BuildContext context) async {
    // For iOS 14+ and Android 13+, the image_picker plugin handles permissions internally
    // but we'll add extra handling for better UX

    Permission permission;
    if (Platform.isAndroid) {
      if (await DeviceInfoPlugin().androidInfo.then(
            (info) => info.version.sdkInt,
          ) >=
          33) {
        // Android 13+ uses READ_MEDIA_IMAGES
        permission = Permission.photos;
      } else {
        // Older Android versions use storage permission
        permission = Permission.storage;
      }
    } else if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      // Default to photos for other platforms
      permission = Permission.photos;
    }

    // Check permission status
    var status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Request permission
      status = await permission.request();
      if (status.isGranted) {
        return true;
      }
    }

    // If permission is permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          'Photo Access Required',
          'This app needs access to your photos to upload images. Please enable it in app settings.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
          // Re-check permission after returning from settings
          return await permission.status.isGranted;
        }
      }
    }

    return false;
  }

  /// Checks and requests permission to access camera
  static Future<bool> _requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          'Camera Access Required',
          'This app needs access to your camera to take photos. Please enable it in app settings.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
          return await Permission.camera.status.isGranted;
        }
      }
    }

    return false;
  }

  /// Shows permission dialog with options to open settings or cancel
  static Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  /// Shows a dialog to choose between camera and gallery
  static Future<ImageSource?> _showImageSourceDialog(
    BuildContext context,
  ) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Picks an image from gallery or camera and either:
  /// - For anonymous users: stores it locally
  /// - For authenticated users: uploads it to Imgur
  /// Returns the path/URL of the image
  static Future<String?> pickAndUploadImage(BuildContext context) async {
    try {
      // Get the auth state to determine if the user is anonymous
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bool isAnonymous = authProvider.isAnonymous;

      // Anonymous users don't need photo consent for local storage
      if (!isAnonymous) {
        // First check if photo consent is given for Imgur upload
        final preferencesService = await PreferencesService.getInstance();
        if (!preferencesService.getPhotoConsent()) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Photo Storage Disabled'),
                    content: const Text(
                      'Photo upload is currently disabled. To upload photos, please enable photo storage in your profile settings and accept the terms for storing photos on Imgur\'s servers.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/profile');
                        },
                        child: const Text('Go to Settings'),
                      ),
                    ],
                  ),
            );
          }
          return null;
        }
      }

      // Show dialog to choose image source
      final imageSource = await _showImageSourceDialog(context);
      if (imageSource == null) {
        return null; // User canceled the dialog
      }

      // Check appropriate permissions
      bool hasPermission;
      if (imageSource == ImageSource.gallery) {
        hasPermission = await _requestPhotoPermission(context);
      } else {
        hasPermission = await _requestCameraPermission(context);
      }

      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Permission to access ${imageSource == ImageSource.gallery ? 'photos' : 'camera'} was denied',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Select image from gallery or camera
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: imageSource,
        imageQuality: 85,
        maxWidth: 1200, // Reduced from 1920 for better compatibility
        maxHeight: 1200, // Reduced from 1080 for better compatibility
      );

      if (pickedFile == null) {
        // User canceled the picker
        return null;
      }

      // Show loading dialog
      if (context.mounted) {
        _showLoadingDialog(context);
      }

      try {
        // Create a File object from the XFile and verify it exists
        final File imageFile = File(pickedFile.path);
        if (!await imageFile.exists()) {
          throw Exception('Selected image file does not exist');
        }

        // Verify the file size
        final fileSize = await imageFile.length();
        if (fileSize == 0) {
          throw Exception('Selected image file is empty');
        }

        String result;

        // For anonymous users, save locally; for authenticated users, upload to Imgur
        if (isAnonymous) {
          // Save locally
          final LocalImageService localImageService = LocalImageService();
          result = await localImageService.saveLocalImage(imageFile);
        } else {
          // Upload to Imgur
          final String imageUrl =
              await ImageUploader.uploadImage(imageFile) ?? "";
          if (imageUrl.isEmpty) {
            throw Exception('Image upload failed');
          }
          result = imageUrl;
        }

        // Dismiss the loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        return result;
      } catch (e) {
        // Dismiss the loading dialog if it's showing
        if (context.mounted) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error processing image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      // Dismiss the loading dialog if it's showing
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Shows a loading dialog while the image is being processed
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Processing image...'),
              ],
            ),
          ),
        );
      },
    );
  }
}
