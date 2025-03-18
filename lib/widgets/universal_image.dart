import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A widget that displays an image from either a network URL, local file path, or asset path.
///
/// This widget automatically detects the image source type and uses the appropriate
/// image loading method with optimized caching.
class UniversalImage extends StatelessWidget {
  /// The path to the image, which can be a network URL, local file path, or asset path.
  final String imagePath;

  /// How to inscribe the image into the space allocated during layout.
  final BoxFit? fit;

  /// The width to which the image should be constrained.
  final double? width;

  /// The height to which the image should be constrained.
  final double? height;

  /// A widget to display while the image is loading.
  final Widget? placeholder;

  /// A widget to display when there's an error loading the image.
  final Widget? errorWidget;

  /// The scale to display the image at.
  final double scale;

  /// Memory cache size for network images
  static const int memoryCacheWidth = 400; // Limit cached image width
  static const int memoryCacheHeight = 400; // Limit cached image height

  const UniversalImage({
    Key? key,
    required this.imagePath,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to isolate this widget's rendering from its parent
    return RepaintBoundary(child: _buildImage());
  }

  Widget _buildImage() {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return _buildNetworkImage();
    } else if (imagePath.startsWith('assets/')) {
      return _buildAssetImage();
    } else {
      return _buildFileImage();
    }
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memoryCacheWidth,
      memCacheHeight: memoryCacheHeight,
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder:
          (context, url) =>
              placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget:
          (context, url, error) => errorWidget ?? const Icon(Icons.error),
      maxWidthDiskCache: 800, // Limit disk cache width
      maxHeightDiskCache: 800, // Limit disk cache height
    );
  }

  Widget _buildFileImage() {
    return FutureBuilder<bool>(
      // Check if file exists first to avoid exceptions
      future: File(imagePath).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Calculate safe cache dimensions that are not Infinity or NaN
          int? safeCacheWidth =
              (width != null && width!.isFinite)
                  ? width!.toInt()
                  : memoryCacheWidth;
          int? safeCacheHeight =
              (height != null && height!.isFinite)
                  ? height!.toInt()
                  : memoryCacheHeight;

          return Image.file(
            File(imagePath),
            fit: fit,
            width: width,
            height: height,
            scale: scale,
            cacheWidth: safeCacheWidth,
            cacheHeight: safeCacheHeight,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? const Icon(Icons.error);
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
          );
        } else {
          return errorWidget ?? const Icon(Icons.error);
        }
      },
    );
  }

  Widget _buildAssetImage() {
    return Image.asset(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      scale: scale,
      cacheWidth: width?.toInt() ?? memoryCacheWidth,
      cacheHeight: height?.toInt() ?? memoryCacheHeight,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}
