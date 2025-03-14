import 'package:flutter/material.dart';
import '../constants/tag_constants.dart';
import '../utils/tag_utils.dart';

/// A reusable widget for selecting tags in the application.
///
/// This widget allows users to select from predefined tags and
/// displays the current selection with appropriate styling.
class TagSelector extends StatelessWidget {
  /// Currently selected tags
  final List<String> selectedTags;

  /// Callback when tags are changed
  final Function(List<String>) onTagsChanged;

  /// Maximum number of tags that can be selected
  final int maxTags;

  /// Whether tags can be deselected
  final bool allowDeselect;

  /// Constructor for the TagSelector widget
  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.maxTags = 3,
    this.allowDeselect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected tags
        if (selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children:
                selectedTags.map((tagId) {
                  return TagUtils.buildTagChip(
                    tagId: tagId,
                    onDelete:
                        allowDeselect
                            ? () {
                              final newTags = List<String>.from(selectedTags);
                              newTags.remove(tagId);
                              onTagsChanged(newTags);
                            }
                            : null,
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Show available tags for selection
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              TagConstants.allTagIds
                  .where((tagId) => !selectedTags.contains(tagId))
                  .map((tagId) {
                    // Don't show already selected tags
                    return _buildAvailableTagChip(context, tagId);
                  })
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildAvailableTagChip(BuildContext context, String tagId) {
    final canAddMore = selectedTags.length < maxTags;

    return FilterChip(
      label: Text(TagConstants.getTagName(tagId)),
      avatar: Icon(
        TagConstants.getTagIcon(tagId),
        size: 16,
        color: canAddMore ? Colors.white : Colors.white.withOpacity(0.5),
      ),
      backgroundColor:
          canAddMore
              ? TagConstants.getTagColor(tagId)
              : TagConstants.getTagColor(tagId).withOpacity(0.5),
      labelStyle: TextStyle(
        color: canAddMore ? Colors.white : Colors.white.withOpacity(0.5),
      ),
      onSelected:
          canAddMore
              ? (_) {
                final newTags = List<String>.from(selectedTags);
                newTags.add(tagId);
                onTagsChanged(newTags);
              }
              : null,
      selected: false,
    );
  }
}
