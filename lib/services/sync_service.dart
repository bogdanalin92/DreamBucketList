import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bucket_list_item.dart';
import 'interfaces/local_storage_service_interface.dart';
import 'interfaces/firebase_service_interface.dart';

/// Service responsible for synchronizing data between local storage and Firebase Firestore.
///
/// This service handles the bidirectional synchronization of bucket list items between
/// the device's local storage and Firebase Firestore. It maintains consistency and
/// handles conflict resolution when items are modified in multiple places.
///
/// Used by: BucketListViewModel
class SyncService {
  final FirebaseServiceInterface _firebaseService;
  final LocalStorageServiceInterface _localStorageService;
  final Set<String> _deletedItemIds = {};
  Timer? _syncDebouncer;
  bool _isInitialized = false;
  static const _syncDelay = Duration(seconds: 2);
  static const _initRetryDelay = Duration(milliseconds: 500);
  int _initRetryCount = 0;
  static const _maxInitRetries = 3;

  SyncService({
    required FirebaseServiceInterface firebaseService,
    required LocalStorageServiceInterface localStorageService,
  }) : _firebaseService = firebaseService,
       _localStorageService = localStorageService {
    _initializeWithRetry();
  }

  Future<void> _initializeWithRetry() async {
    while (!_isInitialized && _initRetryCount < _maxInitRetries) {
      try {
        await _localStorageService.getBucketListItems();
        _isInitialized = true;
        _initSyncListener();
        return;
      } catch (e) {
        debugPrint('Initialization attempt ${_initRetryCount + 1} failed: $e');
        _initRetryCount++;
        if (_initRetryCount < _maxInitRetries) {
          await Future.delayed(_initRetryDelay);
        }
      }
    }
    if (!_isInitialized) {
      debugPrint(
        'Failed to initialize SyncService after $_maxInitRetries attempts',
      );
    }
  }

  Stream<List<BucketListItem>> getBucketListStream() {
    return _localStorageService
        .getBucketListStream()
        .map((items) {
          // Filter out deleted items and ensure valid userId
          return items.where((item) => !_deletedItemIds.contains(item.id)).map((
            item,
          ) {
            if (item.userId.isEmpty) {
              // Ensure item has current user's ID if empty
              return item.copyWith(
                userId: _firebaseService.currentUser?.uid ?? '',
              );
            }

            // Ensure isSyncedWithFirebase is correctly set based on authentication status and shareable flag
            if (_firebaseService.isAuthenticated && item.shareable) {
              return item.copyWith(isSyncedWithFirebase: true);
            } else {
              return item.copyWith(
                isSyncedWithFirebase: false,
              ); // Not synced if not shareable or not authenticated
            }
          }).toList();
        })
        .handleError((error) {
          debugPrint('Error in bucket list stream: $error');
          return <BucketListItem>[];
        });
  }

  Future<void> addBucketListItem(BucketListItem item) async {
    if (item.userId.isEmpty && _firebaseService.currentUser != null) {
      item = item.copyWith(userId: _firebaseService.currentUser!.uid);
    }
    if (item.userId.isEmpty) {
      throw Exception('Cannot add item without userId');
    }

    // Local storage operations are fast and can stay on the main thread
    await _localStorageService.addBucketListItem(item);

    // Firebase operations should be offloaded from the main thread
    // Only sync with Firebase if the item is shareable and user is authenticated
    if (_firebaseService.isAuthenticated && item.shareable) {
      try {
        await _firebaseService.addBucketListItem(item);
        // Mark as synced after successful Firebase add
        await _localStorageService.updateBucketListItem(
          item.copyWith(isSyncedWithFirebase: true),
        );
      } catch (e) {
        debugPrint('Failed to add item to Firebase: $e');
        // Ensure item is marked as not synced
        await _localStorageService.updateBucketListItem(
          item.copyWith(isSyncedWithFirebase: false),
        );
        // Schedule a sync to retry later
        _syncWithFirebase();
      }
    }
  }

  Future<void> updateBucketListItem(BucketListItem item) async {
    if (item.userId.isEmpty && _firebaseService.currentUser != null) {
      item = item.copyWith(userId: _firebaseService.currentUser!.uid);
    }

    if (item.userId.isEmpty) {
      throw Exception('Cannot update item without userId');
    }

    // Get the existing item to check if shareable status changed
    final existingItem = await _localStorageService.getBucketListItem(item.id);
    final bool wasShareable = existingItem?.shareable ?? false;

    // Local update remains on main thread as it's usually fast
    await _localStorageService.updateBucketListItem(
      item.copyWith(isSyncedWithFirebase: false),
    );

    // If item was shareable but is no longer shareable, delete from Firebase
    if (wasShareable && !item.shareable && _firebaseService.isAuthenticated) {
      try {
        await _firebaseService.deleteBucketListItem(item.id);
        // Update local item to reflect it's no longer in Firebase
        await _localStorageService.updateBucketListItem(
          item.copyWith(isSyncedWithFirebase: false),
        );
        return; // Skip Firebase update since we deleted it
      } catch (e) {
        debugPrint('Failed to delete non-shareable item from Firebase: $e');
      }
    }

    // Only sync with Firebase if the item is shareable and user is authenticated
    if (_firebaseService.isAuthenticated && item.shareable) {
      try {
        // If item is newly shareable or was already shareable, update/add it
        if (!wasShareable) {
          await _firebaseService.addBucketListItem(item);
        } else {
          await _firebaseService.updateBucketListItem(item);
        }

        // Update again with synced status after successful Firebase update
        await _localStorageService.updateBucketListItem(
          item.copyWith(isSyncedWithFirebase: true),
        );
      } catch (e) {
        debugPrint('Failed to update item in Firebase: $e');
        // Schedule a sync to retry later
        _syncWithFirebase();
      }
    }
  }

  Future<void> deleteBucketListItem(String id) async {
    final item = await _localStorageService.getBucketListItem(id);
    if (item != null) {
      _deletedItemIds.add(id);

      // Local deletion is fast
      await _localStorageService.deleteBucketListItem(id);

      // Only delete from Firebase if item is shareable and user is authenticated
      if (_firebaseService.isAuthenticated && item.isSyncedWithFirebase) {
        try {
          await _firebaseService.deleteBucketListItem(id);
          _deletedItemIds.remove(id);
        } catch (e) {
          debugPrint('Failed to delete item from Firebase: $e');
          // Schedule a sync to retry later
          _syncWithFirebase();
        }
      }
    }
  }

  Future<void> _syncWithFirebase() async {
    // For anonymous users, skip Firebase sync but keep local data
    if (!_firebaseService.isAuthenticated) return;

    // Cancel any pending sync
    _syncDebouncer?.cancel();

    // Schedule a new sync with debouncing
    _syncDebouncer = Timer(_syncDelay, () async {
      // Start sync in the background using compute
      await _startSync();
    });
  }

  Future<void> _startSync() async {
    try {
      final localItems = await _localStorageService.getBucketListItems();
      final firebaseItems = await _firebaseService.getBucketListStream().first;

      final processedIds = <String>{};
      final itemsToUpdate = <BucketListItem>[];

      // Process Firebase items first
      for (final firebaseItem in firebaseItems) {
        processedIds.add(firebaseItem.id);

        // Skip deleted items
        if (_deletedItemIds.contains(firebaseItem.id)) continue;

        // Find matching local item
        final localItem = localItems.firstWhere(
          (item) => item.id == firebaseItem.id,
          orElse: () => firebaseItem,
        );

        // If item exists in both places, use the most recently modified one
        final localModified =
            localItem.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final firebaseModified =
            firebaseItem.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);

        // If local item is not shareable anymore, delete from Firestore
        if (!localItem.shareable && localItem.id == firebaseItem.id) {
          try {
            await _firebaseService.deleteBucketListItem(firebaseItem.id);
            continue; // Skip further processing for this item
          } catch (e) {
            debugPrint('Failed to delete non-shareable item during sync: $e');
          }
        }

        if (localModified.isAfter(firebaseModified)) {
          // Local item is newer
          final updatedItem = localItem.copyWith(isSyncedWithFirebase: false);
          itemsToUpdate.add(updatedItem);

          // Only sync with Firebase if the item is shareable
          if (updatedItem.shareable) {
            try {
              await _firebaseService.updateBucketListItem(updatedItem);
              // Update local item to reflect synced status
              await _localStorageService.updateBucketListItem(
                updatedItem.copyWith(isSyncedWithFirebase: true),
              );
            } catch (e) {
              debugPrint('Failed to update item in Firebase during sync: $e');
            }
          }
        } else {
          // Firebase item is newer or same age
          final syncedFirebaseItem = firebaseItem.copyWith(
            isSyncedWithFirebase: true,
          );
          itemsToUpdate.add(syncedFirebaseItem);
          await _localStorageService.updateBucketListItem(syncedFirebaseItem);
        }
      }

      // Process local items that don't exist in Firebase
      for (final localItem in localItems) {
        // Skip already processed items
        if (processedIds.contains(localItem.id)) continue;

        // Skip deleted items
        if (_deletedItemIds.contains(localItem.id)) continue;

        // Only sync shareable items with Firebase
        if (localItem.shareable && _firebaseService.isAuthenticated) {
          // Mark as not synced initially
          final updatedItem = localItem.copyWith(isSyncedWithFirebase: false);
          itemsToUpdate.add(updatedItem);
          try {
            await _firebaseService.addBucketListItem(updatedItem);
            // Update again after successful Firebase add
            await _localStorageService.updateBucketListItem(
              updatedItem.copyWith(isSyncedWithFirebase: true),
            );
          } catch (e) {
            debugPrint('Failed to add item to Firebase during sync: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  Future<void> forceSyncItem(String itemId) async {
    if (!_firebaseService.isAuthenticated) return;

    try {
      // Get the item from Firebase
      final firebaseItems = await _firebaseService.getBucketListStream().first;
      final firebaseItem = firebaseItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item not found in Firebase'),
      );

      // Add or update in local storage
      try {
        await _localStorageService.updateBucketListItem(firebaseItem);
      } catch (e) {
        // If update fails because item doesn't exist locally, add it
        await _localStorageService.addBucketListItem(firebaseItem);
      }
    } catch (e) {
      debugPrint('Error syncing item $itemId: $e');
      rethrow;
    }
  }

  void _initSyncListener() {
    _firebaseService.authStateChanges.listen((user) {
      if (user != null) {
        _syncWithFirebase();
      }
    });
  }
}

/// Helper function to avoid having to use `unawaited` explicitly
extension FutureExtension<T> on Future<T> {
  void fireAndForget() {
    // ignore: avoid_function_literals_in_foreach_calls
    then((_) {}).catchError((e) => debugPrint('Error: $e'));
  }
}
