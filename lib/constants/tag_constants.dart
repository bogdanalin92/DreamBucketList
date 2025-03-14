import 'package:flutter/material.dart';

/// A class that holds all available tags for bucket list items.
///
/// This provides centralized access to predefined tags throughout the application.
/// Each tag includes a unique name, color, and icon for consistent display.
class TagConstants {
  /// Private constructor to prevent instantiation
  TagConstants._();

  /// Map of all available tags with their display properties
  ///
  /// Keys are tag IDs, values are maps containing name, color, and icon
  static const Map<String, Map<String, dynamic>> tagDictionary = {
    'travel': {'name': 'Travel', 'color': Colors.blue, 'icon': Icons.flight},
    'adventure': {
      'name': 'Adventure',
      'color': Colors.green,
      'icon': Icons.terrain,
    },
    'career': {'name': 'Career', 'color': Colors.amber, 'icon': Icons.work},
    'education': {
      'name': 'Education',
      'color': Colors.purple,
      'icon': Icons.school,
    },
    'personal': {
      'name': 'Personal',
      'color': Colors.red,
      'icon': Icons.favorite,
    },
  };

  /// Returns a list of all available tag IDs
  static List<String> get allTagIds => tagDictionary.keys.toList();

  /// Returns a list of all available tag names
  static List<String> get allTagNames =>
      tagDictionary.values.map((tag) => tag['name'] as String).toList();

  /// Get tag name from tag ID
  static String getTagName(String tagId) =>
      tagDictionary[tagId]?['name'] as String? ?? 'Unknown';

  /// Get tag color from tag ID
  static Color getTagColor(String tagId) =>
      tagDictionary[tagId]?['color'] as Color? ?? Colors.grey;

  /// Get tag icon from tag ID
  static IconData getTagIcon(String tagId) =>
      tagDictionary[tagId]?['icon'] as IconData? ?? Icons.label;
}
