import '../models/bucket_list_item.dart';
import '../services/sync_service.dart';
import '../services/interfaces/firebase_service_interface.dart';
import 'interfaces/bucket_list_repository_interface.dart';

/// Repository implementation for bucket list operations that combines multiple services
///
/// This implementation uses SyncService for local storage sync and FirebaseService
/// for shared item operations, providing a clean abstraction for bucket list operations.
class BucketListRepository implements BucketListRepositoryInterface {
  final SyncService _syncService;
  final FirebaseServiceInterface _firebaseService;

  BucketListRepository(this._syncService, this._firebaseService);

  @override
  Future<void> initialize() async {
    // Remove initialization as SyncService doesn't have an initialize method
    // It's automatically initialized through its constructor
  }

  @override
  Stream<List<BucketListItem>> getBucketListStream() {
    return _syncService.getBucketListStream();
  }

  @override
  Future<List<BucketListItem>> getLocalItems() async {
    // Use the stream to get current items since there's no direct getLocalItems method
    return await _syncService.getBucketListStream().first;
  }

  @override
  Future<void> addItem(BucketListItem item) {
    return _syncService.addBucketListItem(item);
  }

  @override
  Future<void> updateItem(BucketListItem item) {
    return _syncService.updateBucketListItem(item);
  }

  @override
  Future<void> deleteItem(String id) {
    return _syncService.deleteBucketListItem(id);
  }

  @override
  Stream<List<BucketListItem>> getSharedItemsByUserId(String userId) {
    return _firebaseService.getSharedBucketListByUserId(userId);
  }

  @override
  Stream<List<BucketListItem>> getAllSharedItems() {
    return _firebaseService.getAllSharedBucketListItems();
  }

  @override
  Future<void> synchronize() async {
    // SyncService automatically handles synchronization
    // through its internal _syncWithFirebase method
  }

  @override
  void dispose() {
    // No explicit dispose needed as SyncService handles cleanup internally
  }
}
