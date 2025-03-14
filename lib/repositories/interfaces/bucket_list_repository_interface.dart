import '../../models/bucket_list_item.dart';
import 'repository_interface.dart';

/// Interface for bucket list repositories
///
/// Defines operations for accessing and manipulating bucket list items
/// across multiple data sources (cloud, local storage, etc.).
abstract class BucketListRepositoryInterface extends RepositoryInterface {
  /// Get all bucket list items as a stream
  Stream<List<BucketListItem>> getBucketListStream();

  /// Get list of bucket list items from local storage
  Future<List<BucketListItem>> getLocalItems();

  /// Add a bucket list item to both local storage and cloud (if authenticated)
  Future<void> addItem(BucketListItem item);

  /// Update an existing bucket list item in both local storage and cloud
  Future<void> updateItem(BucketListItem item);

  /// Delete a bucket list item from both local storage and cloud
  Future<void> deleteItem(String id);

  /// Get shared bucket list items from a specific user
  Stream<List<BucketListItem>> getSharedItemsByUserId(String userId);

  /// Get all publicly shared bucket list items
  Stream<List<BucketListItem>> getAllSharedItems();

  /// Force synchronization between local data and cloud
  Future<void> synchronize();
}
