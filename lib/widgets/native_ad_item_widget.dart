import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import 'native_ad_widget.dart';

/// A widget that handles showing native ads within lists
class NativeAdItemWidget extends StatelessWidget {
  const NativeAdItemWidget({
    Key? key,
    this.height = 100,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
  }) : super(key: key);

  final double height;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: NativeAdWidget(factoryId: 'listTile', height: height),
      ),
    );
  }
}
