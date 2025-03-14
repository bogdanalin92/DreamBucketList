import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bucket_list_item.dart';
import 'interfaces/firebase_service_interface.dart';

/// Implementation of the Firebase Service Interface
///
/// Provides concrete implementations for all Firebase Firestore operations
/// related to bucket list items. This class handles data persistence, retrieval,
/// updates, and deletion in Firebase Firestore.
///
/// Used by: SyncService, BucketListViewModel, SharedBucketListScreen
class FirebaseServiceImpl implements FirebaseServiceInterface {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String collectionName;

  /// Creates a FirebaseServiceImpl with optional Firestore and Auth instances for testing
  FirebaseServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.collectionName = 'bucket_list_items',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Stream<List<BucketListItem>> getBucketListStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]); // Return empty list for unauthenticated users
    }

    try {
      // Get items for the current user, including anonymous
      return _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('lastModified', descending: true)
          .snapshots()
          .handleError((error) {
            print('Firestore error: $error');
            return [];
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    final userId = data['userId'] as String? ?? '';
                    if (userId.isEmpty) {
                      print('Skipping item ${doc.id} due to empty userId');
                      return null;
                    }

                    // Extract tags from the document
                    List<String> tags = [];
                    if (data['tags'] != null) {
                      tags = List<String>.from(data['tags']);
                    }

                    return BucketListItem(
                      userId: userId,
                      id: doc.id,
                      item: data['item'] as String? ?? '',
                      price: (data['price'] as num?)?.toDouble(),
                      details: data['details'] as String? ?? '',
                      complete: data['complete'] as bool? ?? false,
                      shareable: data['shareable'] as bool? ?? false,
                      image: data['image'] as String?,
                      isDeleted: data['isDeleted'] as bool? ?? false,
                      lastModified:
                          (data['lastModified'] as Timestamp?)?.toDate(),
                      isSyncedWithFirebase: true,
                      tags: tags, // Include tags in the item
                    );
                  })
                  .where((item) => item != null)
                  .cast<BucketListItem>()
                  .toList();
            } catch (e) {
              print('Error parsing Firestore data: $e');
              return [];
            }
          });
    } catch (e) {
      print('Error setting up Firestore stream: $e');
      return Stream.value([]);
    }
  }

  @override
  Future<void> addBucketListItem(BucketListItem item) async {
    try {
      if (!isAuthenticated) {
        print('Cannot add item: User is not authenticated');
        throw Exception('User is not authenticated');
      }

      await _firestore.collection(collectionName).doc(item.id).set({
        'userId': item.userId,
        'item': item.item,
        'price': item.price,
        'details': item.details,
        'complete': item.complete,
        'shareable': item.shareable,
        'image': item.image,
        'isDeleted': false,
        'lastModified': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'tags': item.tags, // Add tags to Firebase document
      });
    } catch (e) {
      print('Error adding bucket list item: $e');
      throw e; // Rethrow to handle in SyncService
    }
  }

  @override
  Future<void> updateBucketListItem(BucketListItem item) async {
    if (!isAuthenticated) {
      print('Cannot update item: User is not authenticated');
      throw Exception('User is not authenticated');
    }

    final docRef = _firestore.collection(collectionName).doc(item.id);
    try {
      // Use a transaction to ensure atomic update
      await _firestore.runTransaction((transaction) async {
        transaction.set(docRef, {
          'userId': item.userId,
          'item': item.item,
          'price': item.price,
          'details': item.details,
          'complete': item.complete,
          'shareable': item.shareable,
          'image': item.image,
          'isDeleted': false,
          'lastModified': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
          'tags': item.tags, // Add tags to Firebase document
        });
      });
    } catch (e) {
      print('Error updating bucket list item: $e');
      throw e;
    }
  }

  @override
  Future<void> deleteBucketListItem(String id) async {
    try {
      if (!isAuthenticated) {
        print('Cannot delete item: User is not authenticated');
        throw Exception('User is not authenticated');
      }

      // First check if the document exists
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (!doc.exists) {
        print('Document does not exist, possibly already deleted');
        return;
      }

      // Actually delete the document completely from Firestore
      await _firestore.collection(collectionName).doc(id).delete();
      print('Document successfully deleted from Firestore');
    } catch (e) {
      print('Error deleting bucket list item: $e');
      rethrow;
    }
  }

  @override
  Stream<List<BucketListItem>> getSharedBucketListByUserId(String userId) {
    try {
      if (!isAuthenticated) {
        return Stream.value([]); // Return empty list for unauthenticated users
      }

      return _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('shareable', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            print('Firestore error in getSharedBucketListByUserId: $error');
            return [];
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    final userId = data['userId'] as String? ?? '';
                    if (userId.isEmpty) {
                      print(
                        'Skipping shared item ${doc.id} due to empty userId',
                      );
                      return null;
                    }

                    // Extract tags from the document
                    List<String> tags = [];
                    if (data['tags'] != null) {
                      tags = List<String>.from(data['tags']);
                    }

                    return BucketListItem(
                      userId: userId,
                      id: doc.id,
                      item: data['item'] as String? ?? '',
                      price: (data['price'] as num?)?.toDouble(),
                      details: data['details'] as String? ?? '',
                      complete: data['complete'] as bool? ?? false,
                      shareable: data['shareable'] as bool? ?? false,
                      image: data['image'] as String?,
                      isDeleted: data['isDeleted'] as bool? ?? false,
                      lastModified:
                          (data['lastModified'] as Timestamp?)?.toDate(),
                      isSyncedWithFirebase: true,
                      tags: tags, // Include tags in the item
                    );
                  })
                  .where((item) => item != null)
                  .cast<BucketListItem>()
                  .toList();
            } catch (e) {
              print('Error parsing Firestore data: $e');
              return [];
            }
          });
    } catch (e) {
      print('Error setting up Firestore stream: $e');
      return Stream.value([]);
    }
  }

  @override
  Stream<List<BucketListItem>> getAllSharedBucketListItems() {
    try {
      if (!isAuthenticated) {
        return Stream.value([]); // Return empty list for unauthenticated users
      }

      return _firestore
          .collection(collectionName)
          .where('shareable', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            print('Firestore error in getAllSharedBucketListItems: $error');
            return [];
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    final userId = data['userId'] as String? ?? '';
                    if (userId.isEmpty) {
                      print(
                        'Skipping shared item ${doc.id} due to empty userId',
                      );
                      return null;
                    }

                    // Extract tags from the document
                    List<String> tags = [];
                    if (data['tags'] != null) {
                      tags = List<String>.from(data['tags']);
                    }

                    return BucketListItem(
                      userId: userId,
                      id: doc.id,
                      item: data['item'] as String? ?? '',
                      price: (data['price'] as num?)?.toDouble(),
                      details: data['details'] as String? ?? '',
                      complete: data['complete'] as bool? ?? false,
                      shareable: data['shareable'] as bool? ?? false,
                      image: data['image'] as String?,
                      isDeleted: data['isDeleted'] as bool? ?? false,
                      lastModified:
                          (data['lastModified'] as Timestamp?)?.toDate(),
                      isSyncedWithFirebase: true,
                      tags: tags, // Include tags in the item
                    );
                  })
                  .where((item) => item != null)
                  .cast<BucketListItem>()
                  .toList();
            } catch (e) {
              print('Error parsing Firestore data: $e');
              return [];
            }
          });
    } catch (e) {
      print('Error setting up Firestore stream: $e');
      return Stream.value([]);
    }
  }
}
