import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bucket_list_item.dart';

/// Interface for Firebase services that defines the contract for all Firebase operations.
///
/// This interface is implemented by concrete Firebase service classes and allows for:
/// - Authentication operations
/// - Bucket list item CRUD operations
/// - Data synchronization
///
/// Used by: SyncService, BucketListViewModel, AuthViewModel, SharedBucketListScreen
abstract class FirebaseServiceInterface {
  /// Get the current authenticated user or null if not authenticated
  User? get currentUser;

  /// Get the authentication state changes stream
  Stream<User?> get authStateChanges;

  /// Check if there is an authenticated user
  bool get isAuthenticated;

  /// Get bucket list items for the current user as a stream
  Stream<List<BucketListItem>> getBucketListStream();

  /// Add a bucket list item to Firestore
  Future<void> addBucketListItem(BucketListItem item);

  /// Update a bucket list item in Firestore
  Future<void> updateBucketListItem(BucketListItem item);

  /// Delete a bucket list item from Firestore by its ID
  Future<void> deleteBucketListItem(String id);

  /// Get shared bucket list items from a specific user by their user ID
  Stream<List<BucketListItem>> getSharedBucketListByUserId(String userId);

  /// Get all publicly shared bucket list items from all users
  Stream<List<BucketListItem>> getAllSharedBucketListItems();
}
