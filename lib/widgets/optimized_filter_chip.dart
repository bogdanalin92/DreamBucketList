import 'package:flutter/material.dart';
import 'package:bucketlist/widgets/cached_icon.dart';
import 'package:bucketlist/constants/tag_constants.dart';

class OptimizedFilterChip extends StatelessWidget {
  final String tagId;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final Color? textColor;

  const OptimizedFilterChip({
    required this.tagId,
    required this.isSelected,
    required this.onSelected,
    this.textColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pre-compute these values to avoid redundant calculations
    final tagName = TagConstants.getTagName(tagId);
    final tagColor = TagConstants.getTagColor(tagId);
    final tagIcon = TagConstants.getTagIcon(tagId);

    return FilterChip(
      label: Text(tagName),
      selected: isSelected,
      onSelected: onSelected,
      avatar: CachedIcon(
        icon: tagIcon,
        color: isSelected ? Colors.white : tagColor,
        size: 18,
      ),
      backgroundColor: tagColor.withOpacity(0.1),
      selectedColor: tagColor,
      labelStyle: TextStyle(
        color:
            isSelected
                ? Colors.white
                : textColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      checkmarkColor: Colors.white,
      elevation: isSelected ? 2 : 0,
      pressElevation: 2,
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap, // Optimize hit test area
      visualDensity:
          VisualDensity.compact, // Reduce size for better performance
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptimizedFilterChip &&
        other.tagId == tagId &&
        other.isSelected == isSelected &&
        other.textColor == textColor;
  }

  @override
  int get hashCode => Object.hash(tagId, isSelected, textColor);
}
