import 'package:flutter/material.dart';
import '../constants/tag_constants.dart';
import '../models/bucket_list_item.dart';

/// A utility class for working with bucket list item tags.
///
/// Provides helper methods for filtering, displaying, and managing tags.
class TagUtils {
  /// Prevents instantiation of this utility class
  TagUtils._();

  /// Returns a list of items that match the specified tag
  static List<BucketListItem> filterItemsByTag(
    List<BucketListItem> items,
    String tagId,
  ) {
    return items.where((item) => item.tags.contains(tagId)).toList();
  }

  /// Returns a widget to display a tag with appropriate styling
  static Widget buildTagChip({
    required String tagId,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    final String tagName = TagConstants.getTagName(tagId);
    final Color tagColor = TagConstants.getTagColor(tagId);
    final IconData tagIcon = TagConstants.getTagIcon(tagId);

    return Chip(
      avatar: Icon(tagIcon, size: 16, color: Colors.white),
      label: Text(tagName),
      backgroundColor: tagColor,
      labelStyle: const TextStyle(color: Colors.white),
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: onDelete,
    );
  }

  /// Adds a tag to a bucket list item and returns the updated item
  static BucketListItem addTag(BucketListItem item, String tagId) {
    // Don't add if it already exists
    if (item.tags.contains(tagId)) return item;

    // Create a new list with the added tag
    final List<String> updatedTags = List.from(item.tags)..add(tagId);
    return item.copyWith(tags: updatedTags);
  }

  /// Removes a tag from a bucket list item and returns the updated item
  static BucketListItem removeTag(BucketListItem item, String tagId) {
    // Create a new list without the specified tag
    final List<String> updatedTags = List.from(item.tags)
      ..removeWhere((t) => t == tagId);
    return item.copyWith(tags: updatedTags);
  }

  /// Returns all tags from a list of items as a unique set
  static Set<String> getAllUsedTags(List<BucketListItem> items) {
    final Set<String> usedTags = {};
    for (final item in items) {
      usedTags.addAll(item.tags);
    }
    return usedTags;
  }
}
