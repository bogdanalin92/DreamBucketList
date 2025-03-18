import 'package:flutter/material.dart';
import 'circular_loader.dart';

/// A loading overlay that displays a CircularLoader with an optional message
///
/// This widget can be used to show a loading state over any content
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the loading overlay
  final bool isLoading;

  /// The child widget to display under the loading overlay
  final Widget child;

  /// Optional message to display below the loader
  final String? message;

  /// Size of the loading indicator
  final double loaderSize;

  /// Background color of the overlay
  final Color backgroundColor;

  /// Text style for the message
  final TextStyle? messageStyle;

  /// Creates a loading overlay
  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.loaderSize = 100,
    this.backgroundColor = const Color(0x99FFFFFF),
    this.messageStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    );

    return Stack(
      children: [
        // Main content
        child,

        // Loading overlay (only shown when isLoading is true)
        if (isLoading)
          Container(
            color: backgroundColor,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularLoader(size: loaderSize),
                  if (message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      message!,
                      style: messageStyle ?? defaultTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Static method to wrap a widget with the LoadingOverlay
  static Widget wrap({
    required bool isLoading,
    required Widget child,
    String? message,
  }) {
    return LoadingOverlay(isLoading: isLoading, message: message, child: child);
  }
}
