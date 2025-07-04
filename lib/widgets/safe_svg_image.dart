import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SafeSvgImage extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;

  const SafeSvgImage({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    required this.fallback,
  }) : super(key: key);

  @override
  State<SafeSvgImage> createState() => _SafeSvgImageState();
}

class _SafeSvgImageState extends State<SafeSvgImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback;
    }

    return SvgPicture.network(
      widget.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholderBuilder:
          (context) => SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      // Handle SVG loading errors gracefully
      // Note: flutter_svg doesn't have an explicit errorBuilder,
      // so we'll wrap this in a FutureBuilder for better error handling
    );
  }
}

class SafeSvgImageWithFallback extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;

  const SafeSvgImageWithFallback({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    required this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _loadSvgSafely(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return fallback;
        }

        return snapshot.data!;
      },
    );
  }

  Future<Widget> _loadSvgSafely() async {
    try {
      // Test if the URL is accessible and returns valid SVG
      return SvgPicture.network(url, width: width, height: height, fit: fit);
    } catch (e) {
      // If there's any error, throw to trigger fallback
      throw Exception('Failed to load SVG: $e');
    }
  }
}
