import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool alignLabelWithHint;
  final Widget? suffixIcon;
  final bool enabled;
  final VoidCallback? onTap;
  final bool readOnly;
  final String? hintText;

  // FlutterFlow-style properties
  final bool showAnimation;
  final Duration animationDuration;
  final Color? customFillColor;
  final Color? customBorderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final bool autoSize;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.alignLabelWithHint = false,
    this.suffixIcon,
    this.enabled = true,
    this.onTap,
    this.readOnly = false,
    this.hintText,

    // FlutterFlow-style defaults
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.customFillColor,
    this.customBorderColor,
    this.borderRadius = 25.0, // More rounded for pill shape
    this.contentPadding,
    this.autoSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget textField = TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        // Use hintText instead of labelText for placeholder effect
        hintText: hintText ?? labelText,
        hintStyle: TextStyle(
          color:
              theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          borderSide: BorderSide.none, // Remove border for clean look
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none, // No border for clean pill shape
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          borderSide: BorderSide(
            color: customBorderColor ?? theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        prefixIcon:
            prefixIcon != null
                ? Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(
                    prefixIcon,
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    size: 20,
                  ),
                )
                : null,
        suffixIcon: suffixIcon,
        // Remove labelStyle since we're not using labels
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor:
            customFillColor ??
            (theme.brightness == Brightness.dark
                ? Colors.grey[800]?.withOpacity(0.3)
                : Colors.grey[200]?.withOpacity(0.8)),
        // Remove label and use hintText for placeholder style
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      style: TextStyle(
        color: theme.colorScheme.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );

    // Apply FlutterFlow-style animation if enabled
    if (showAnimation) {
      return textField
          .animate()
          .fadeIn(duration: animationDuration)
          .slideY(begin: 0.2, end: 0, duration: animationDuration);
    }

    return textField;
  }
}
