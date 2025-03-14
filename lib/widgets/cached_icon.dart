import 'package:flutter/material.dart';

class CachedIcon extends StatelessWidget {
  static final Map<String, Icon> _cache = {};

  final IconData icon;
  final Color color;
  final double size;

  const CachedIcon({
    required this.icon,
    required this.color,
    required this.size,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String cacheKey = '${icon.codePoint}_${color.value}_$size';
    return _cache.putIfAbsent(
      cacheKey,
      () => Icon(icon, color: color, size: size),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedIcon &&
        other.icon == icon &&
        other.color.toARGB32() == color.toARGB32() &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(icon, color.toARGB32(), size);
}
