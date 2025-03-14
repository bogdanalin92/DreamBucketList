import 'package:flutter/material.dart';
import '../widgets/native_ad_widget.dart';

/// A widget that displays a medium rectangle native ad
/// This is typically used at the bottom of detail views or as standalone ads
class MediumRectangleAdWidget extends StatelessWidget {
  const MediumRectangleAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Sponsored',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: NativeAdWidget(
                factoryId: 'mediumRectangle',
                height: 300,
                customOptions: const {'backgroundColor': 0xFFFFFFFF},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
