import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AvatarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predefined emoji avatars
  static const List<String> avatarEmojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '🤗',
    '🤔',
    '🤨',
    '😐',
    '😑',
    '😶',
    '🙄',
    '😏',
    '😣',
    '😥',
    '🤐',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🤡',
    '🥳',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '🤧',
    '🥵',
    '🥶',
    '🥴',
    '😵',
    '🤯',
    '🤠',
    '🥳',
    '😎',
    '🤓',
    '🧐',
    '😈',
    '👿',
    '👹',
    '👺',
    '💀',
    '👻',
    '👽',
    '👾',
    '🤖',
    '🎃',
    '😺',
    '😸',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐯',
    '🦁',
    '🐮',
    '🐷',
    '🐸',
    '🐵',
    '🙈',
    '🙉',
    '🙊',
    '🐒',
    '🐔',
    '🐧',
    '🐦',
    '🐤',
    '🐣',
    '🐥',
    '🦆',
    '🦅',
  ];

  // Predefined background colors
  static const List<Color> avatarColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF6B7280), // Gray
    Color(0xFF84CC16), // Lime
  ];

  // Generated avatar styles using local patterns instead of DiceBear API
  static const List<Map<String, String>> generatedAvatarStyles = [
    {'name': 'Geometric', 'style': 'geometric'},
    {'name': 'Abstract', 'style': 'abstract'},
    {'name': 'Gradient', 'style': 'gradient'},
  ];

  /// Save emoji avatar to Firestore
  static Future<void> saveEmojiAvatar(
    String emoji,
    Color backgroundColor,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(user.uid).update({
      'avatarData': emoji,
      'avatarType': AvatarType.emoji.name,
      'backgroundColor': backgroundColor.toARGB32(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Save generated avatar pattern to Firestore
  static Future<void> saveGeneratedAvatar(
    String pattern,
    List<Color> colors,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Store pattern data as JSON string
    final patternData = {
      'pattern': pattern,
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'seed': user.uid,
    };

    // Convert to JSON string for proper storage
    final jsonString = jsonEncode(patternData);

    await _firestore.collection('users').doc(user.uid).update({
      'avatarData': jsonString,
      'avatarType': AvatarType.generated.name,
      'backgroundColor': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Save initials avatar to Firestore
  static Future<void> saveInitialsAvatar(Color backgroundColor) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(user.uid).update({
      'avatarData': null,
      'avatarType': AvatarType.initials.name,
      'backgroundColor': backgroundColor.value,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Generate a random emoji avatar
  static String getRandomEmoji() {
    final random = Random();
    return avatarEmojis[random.nextInt(avatarEmojis.length)];
  }

  /// Generate a random background color
  static Color getRandomColor() {
    final random = Random();
    return avatarColors[random.nextInt(avatarColors.length)];
  }

  /// Generate avatar pattern data instead of URL
  static Map<String, dynamic> generateAvatarPattern(String style, String seed) {
    final random = Random(seed.hashCode);

    // Generate colors based on style
    List<Color> colors;
    switch (style) {
      case 'geometric':
        colors = [_generateRandomColor(random), _generateRandomColor(random)];
        break;
      case 'gradient':
        final baseColor = avatarColors[random.nextInt(avatarColors.length)];
        final secondColor = avatarColors[random.nextInt(avatarColors.length)];
        // Ensure we have two distinct colors for a better gradient effect
        colors =
            baseColor != secondColor
                ? [baseColor, secondColor]
                : [baseColor, _lightenColor(baseColor, 0.4)];
        break;
      case 'abstract':
        colors = List.generate(3, (_) => _generateRandomColor(random));
        break;
      default:
        colors = [avatarColors[random.nextInt(avatarColors.length)]];
    }

    return {
      'pattern': style,
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'seed': seed,
    };
  }

  static Color _generateRandomColor(Random random) {
    return avatarColors[random.nextInt(avatarColors.length)];
  }

  static Color _lightenColor(Color color, double factor) {
    return Color.lerp(color, Colors.white, factor) ?? color;
  }

  /// Get initials from display name
  static String getInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '?';

    final words = displayName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }

  /// Get a unique seed for the user (for consistent generated avatars)
  static String getUserSeed() {
    final user = _auth.currentUser;
    if (user == null) return 'default';
    return user.uid;
  }

  /// Get contrast color for text (white or black based on background)
  static Color getContrastColor(Color backgroundColor) {
    // Calculate luminance
    final luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;

    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Regenerate colors for a specific pattern style
  static List<Color> regenerateColorsForPattern(String style) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);

    List<Color> colors;
    switch (style) {
      case 'geometric':
        colors = [_generateRandomColor(random), _generateRandomColor(random)];
        break;
      case 'gradient':
        final baseColor = avatarColors[random.nextInt(avatarColors.length)];
        final secondColor = avatarColors[random.nextInt(avatarColors.length)];
        // Ensure we have two distinct colors for a better gradient effect
        colors =
            baseColor != secondColor
                ? [baseColor, secondColor]
                : [baseColor, _lightenColor(baseColor, 0.4)];
        break;
      case 'abstract':
        colors = List.generate(3, (_) => _generateRandomColor(random));
        break;
      default:
        colors = [avatarColors[random.nextInt(avatarColors.length)]];
    }

    return colors;
  }
}
