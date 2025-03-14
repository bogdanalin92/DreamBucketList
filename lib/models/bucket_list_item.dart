import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BucketListItem {
  final String userId;
  final String id;
  final String item;
  final double? price;
  final String? image;
  final String? details;
  final bool complete;
  final bool shareable;
  final bool isDeleted;
  final DateTime? lastModified;
  final bool isSyncedWithFirebase;
  final List<String> tags; // New field for storing tags

  BucketListItem({
    required this.userId,
    required this.id,
    required this.item,
    this.price,
    this.image,
    this.details,
    this.complete = false,
    this.shareable = false,
    this.isDeleted = false,
    this.lastModified,
    this.isSyncedWithFirebase = false,
    this.tags = const [], // Default to empty list
  }) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
  }

  BucketListItem copyWith({
    String? userId,
    String? id,
    String? item,
    double? price,
    String? image,
    String? details,
    bool? complete,
    bool? shareable,
    bool? isDeleted,
    DateTime? lastModified,
    bool? isSyncedWithFirebase,
    List<String>? tags,
  }) {
    return BucketListItem(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      item: item ?? this.item,
      price: price ?? this.price,
      image: image ?? this.image,
      details: details ?? this.details,
      complete: complete ?? this.complete,
      shareable: shareable ?? this.shareable,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      isSyncedWithFirebase: isSyncedWithFirebase ?? this.isSyncedWithFirebase,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'id': id,
      'item': item,
      'price': price,
      'image': image,
      'details': details,
      'complete': complete,
      'shareable': shareable,
      'isDeleted': isDeleted,
      'lastModified': lastModified?.toIso8601String(),
      'isSyncedWithFirebase': isSyncedWithFirebase,
      'tags': tags, // Add tags to JSON output
    };
  }

  factory BucketListItem.fromJson(Map<String, dynamic> json) {
    // Get userId from json, fallback to anonymous ID if empty or null
    final userId = json['userId'] as String? ?? '';
    final finalUserId =
        userId.isEmpty
            ? FirebaseAuth.instance.currentUser?.uid ?? Uuid().v4()
            : userId;

    return BucketListItem(
      userId: finalUserId,
      id: json['id'] as String,
      item: json['item'] as String,
      price: json['price'] as double?,
      image: json['image'] as String?,
      details: json['details'] as String?,
      complete: json['complete'] as bool? ?? false,
      shareable: json['shareable'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      lastModified:
          json['lastModified'] != null
              ? DateTime.parse(json['lastModified'] as String)
              : null,
      isSyncedWithFirebase: json['isSyncedWithFirebase'] as bool? ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
    );
  }
}
