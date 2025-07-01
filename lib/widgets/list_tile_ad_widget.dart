import 'package:flutter/material.dart';
import '../widgets/native_ad_widget.dart';

/// A widget that displays a native ad in a list tile format
class ListTileAdWidget extends StatelessWidget {
  const ListTileAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: NativeAdWidget(
          factoryId: 'listTile',
          height: 100,
          customOptions: const {'listTileStyle': true},
        ),
      ),
    );
  }
}
