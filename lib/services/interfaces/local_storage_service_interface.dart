import '../../models/bucket_list_item.dart';

/// Interface for local storage operations
///
/// Defines operations for storing and retrieving bucket list items
/// in local device storage. This interface ensures consistent local storage
/// behavior across different implementations.
abstract class LocalStorageServiceInterface {
  /// Initialize the local storage service
  Future<void> initialize();

  /// Get all bucket list items from local storage
  Future<List<BucketListItem>> getBucketListItems();

  /// Get a specific bucket list item by ID
  Future<BucketListItem?> getBucketListItem(String id);

  /// Get all bucket list items (alias for getBucketListItems)
  Future<List<BucketListItem>> getAllBucketListItems();

  /// Get bucket list items as a stream for real-time updates
  Stream<List<BucketListItem>> getBucketListStream();

  /// Add a bucket list item to local storage
  Future<void> addBucketListItem(BucketListItem item);

  /// Update an existing bucket list item in local storage
  Future<void> updateBucketListItem(BucketListItem item);

  /// Delete a bucket list item from local storage
  Future<void> deleteBucketListItem(String itemId);

  /// Save a list of bucket list items to local storage
  Future<void> saveBucketListItems(List<BucketListItem> items);

  /// Clear all bucket list items from local storage
  Future<void> clearBucketList();
}
