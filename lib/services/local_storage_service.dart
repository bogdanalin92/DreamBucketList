import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bucket_list_item.dart';
import 'interfaces/local_storage_service_interface.dart';

/// Implementation of local storage operations using SharedPreferences
///
/// This class handles persisting bucket list items to device storage using
/// SharedPreferences. It provides a consistent interface for local storage
/// operations and includes proper error handling and logging.
class LocalStorageService implements LocalStorageServiceInterface {
  static const String _bucketListKey = 'bucket_list_items';
  final SharedPreferences? _prefs;
  late final StreamController<List<BucketListItem>> _itemsController;
  bool _isInitialized = false;
  bool _isDisposed = false;
  List<BucketListItem>? _cachedItems;

  /// Create a new LocalStorageService with an optional SharedPreferences instance
  LocalStorageService([this._prefs]) {
    _itemsController = StreamController<List<BucketListItem>>.broadcast(
      onListen: () async {
        // Emit current items when someone starts listening
        if (!_isDisposed && !_itemsController.isClosed) {
          final items = await getBucketListItems();
          _itemsController.add(items);
        }
      },
    );
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }

      _isInitialized = true;
      await _updateStream();
    } catch (e) {
      debugPrint('Error initializing LocalStorageService: $e');
      rethrow;
    }
  }

  Future<void> _updateStream() async {
    if (_isDisposed) return;

    try {
      final items = await getBucketListItems();
      _cachedItems = items;
      if (!_isDisposed && !_itemsController.isClosed) {
        _itemsController.add(items);
      }
    } catch (e) {
      debugPrint('Error updating stream: $e');
      if (!_isDisposed && !_itemsController.isClosed) {
        _itemsController.addError(e);
      }
    }
  }

  @override
  Future<List<BucketListItem>> getBucketListItems() async {
    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }

      final String? itemsJson = _prefs.getString(_bucketListKey);
      if (itemsJson == null || itemsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedItems = jsonDecode(itemsJson);
      final items =
          decodedItems
              .map(
                (item) => BucketListItem.fromJson(item as Map<String, dynamic>),
              )
              .where(
                (item) => !item.isDeleted,
              ) // Only filter deleted items, keep all others regardless of userId
              .toList();
      _cachedItems = items;
      return items;
    } catch (e) {
      debugPrint('Error getting bucket list items: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveBucketListItems(List<BucketListItem> items) async {
    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }

      final encodedItems = items.map((item) => item.toJson()).toList();
      await _prefs.setString(_bucketListKey, jsonEncode(encodedItems));
      await _updateStream(); // Added explicit stream update
    } catch (e) {
      debugPrint('Error saving bucket list items: $e');
      rethrow;
    }
  }

  @override
  Future<BucketListItem?> getBucketListItem(String id) async {
    try {
      final items = await getBucketListItems();
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addBucketListItem(BucketListItem item) async {
    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }

      final items = await getBucketListItems();
      if (items.any((existingItem) => existingItem.id == item.id)) {
        throw Exception('Item with ID ${item.id} already exists');
      }

      items.add(item);
      await saveBucketListItems(items);
    } catch (e) {
      debugPrint('Error adding bucket list item: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBucketListItem(BucketListItem updatedItem) async {
    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }

      final items = await getBucketListItems();
      final index = items.indexWhere((item) => item.id == updatedItem.id);
      if (index == -1) {
        throw Exception('Item with ID ${updatedItem.id} not found');
      }

      items[index] = updatedItem;
      await saveBucketListItems(items);
    } catch (e) {
      debugPrint('Error updating bucket list item: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBucketListItem(String id) async {
    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }

      final items = await getBucketListItems();
      items.removeWhere((item) => item.id == id);
      //      await saveBucketListItems(items);
      await _prefs.setString(_bucketListKey, jsonEncode(items));
      await _updateStream(); // Added explicit stream update
    } catch (e) {
      debugPrint('Error deleting bucket list item: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearBucketList() async {
    try {
      if (_prefs == null) {
        throw Exception('SharedPreferences not initialized');
      }
      await _prefs.remove(_bucketListKey);
      _cachedItems = [];
      if (!_isDisposed && !_itemsController.isClosed) {
        _itemsController.add([]);
      }
    } catch (e) {
      debugPrint('Error clearing bucket list: $e');
      rethrow;
    }
  }

  @override
  Stream<List<BucketListItem>> getBucketListStream() => _itemsController.stream;

  @override
  Future<List<BucketListItem>> getAllBucketListItems() async {
    return getBucketListItems();
  }

  /// Dispose of resources used by this service
  void dispose() {
    _isDisposed = true;
    _itemsController.close();
  }

  /// Factory method to create a new instance with initialized SharedPreferences
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service.initialize();
    return service;
  }
}
