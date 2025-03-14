import '../models/bucket_list_item.dart';
import '../services/sync_service.dart';
import 'base_view_model.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// ViewModel for managing bucket list items and operations
///
/// This class handles state management for bucket list items, including fetching,
/// adding, updating, and deleting items. It uses the SyncService to synchronize
/// data between local storage and Firebase Firestore.
class BucketListViewModel extends BaseViewModel {
  final SyncService _syncService;
  List<BucketListItem> _items = [];
  StreamSubscription? _bucketListSubscription;
  bool _isInitialized = false;
  bool _isFetchingData = false;

  // Cache for filtered item lists
  List<BucketListItem>? _cachedCompletedItems;
  List<BucketListItem>? _cachedPendingItems;
  int _lastFilterVersion = 0; // Used to invalidate cache when items change

  // Add these properties to BucketListViewModel
  List<BucketListItem> _allItems = [];
  List<BucketListItem> _filteredItems = [];
  String _currentSearchQuery = '';
  List<String> _currentTagFilters = [];

  // Add these to track if filters are currently active
  bool _searchActive = false;
  bool _tagFiltersActive = false;

  /// Creates a new BucketListViewModel with the provided SyncService
  BucketListViewModel({required SyncService syncService})
    : _syncService = syncService {
    // Start initialization but don't await it - this prevents blocking the UI
    _initialize();
  }

  // Getters
  List<BucketListItem> get items =>
      _filteredItems.isNotEmpty || _searchActive || _tagFiltersActive
          ? _filteredItems
          : _allItems;

  // Use compute to filter items in a separate isolate if the list is large
  Future<List<BucketListItem>> get completedItems async {
    // Return cached results if available and still valid
    if (_cachedCompletedItems != null &&
        _lastFilterVersion == _items.hashCode) {
      return _cachedCompletedItems!;
    }

    List<BucketListItem> result;
    if (_items.length > 100) {
      // For large lists, use compute to filter in an isolate
      result = await compute(_filterCompletedItems, _items);
    } else {
      // For small lists, do it synchronously
      result = _items.where((item) => item.complete).toList();
    }

    // Cache the results for future use
    _cachedCompletedItems = result;
    _lastFilterVersion = _items.hashCode;
    return result;
  }

  // Use compute to filter items in a separate isolate if the list is large
  Future<List<BucketListItem>> get pendingItems async {
    // Return cached results if available and still valid
    if (_cachedPendingItems != null && _lastFilterVersion == _items.hashCode) {
      return _cachedPendingItems!;
    }

    List<BucketListItem> result;
    if (_items.length > 100) {
      // For large lists, use compute to filter in an isolate
      result = await compute(_filterPendingItems, _items);
    } else {
      // For small lists, do it synchronously
      result = _items.where((item) => !item.complete).toList();
    }

    // Cache the results for future use
    _cachedPendingItems = result;
    _lastFilterVersion = _items.hashCode;
    return result;
  }

  // Static methods for compute to work in isolates
  static List<BucketListItem> _filterCompletedItems(
    List<BucketListItem> items,
  ) {
    return items.where((item) => item.complete).toList();
  }

  static List<BucketListItem> _filterPendingItems(List<BucketListItem> items) {
    return items.where((item) => !item.complete).toList();
  }

  /// Initialize the view model asynchronously
  Future<void> _initialize() async {
    if (_isInitialized) return;

    // We still indicate loading but don't block for initialization
    setLoading(true);

    try {
      // Initialize stream first so we get updates as they come in
      _initializeStream();

      // Use a timeout to prevent blocking indefinitely
      final items = await _syncService.getBucketListStream().first.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Initial data loading timed out, showing empty state');
          return [];
        },
      );

      // Set both _items and _allItems
      _items = items;
      _allItems = items;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during initialization: $e');
      setError(e.toString());
    } finally {
      // Always set loading to false to prevent getting stuck
      setLoading(false);
    }
  }

  /// Initialize the stream of bucket list items
  void _initializeStream() {
    _bucketListSubscription?.cancel();
    _bucketListSubscription = _syncService.getBucketListStream().listen(
      (items) {
        _updateItemsAsync(items);
      },
      onError: (error) {
        setError(error.toString());
      },
    );
  }

  // Update items asynchronously to avoid UI jank
  Future<void> _updateItemsAsync(List<BucketListItem> newItems) async {
    // If the lists are identical (by reference equality), do nothing
    if (identical(_items, newItems)) return;

    // For large lists, use compute to compare them
    bool areEqual = newItems.length == _items.length;
    if (areEqual && newItems.length > 100) {
      areEqual = await compute(_areListsEqual, {
        'list1': _items.map((e) => e.toJson()).toList(),
        'list2': newItems.map((e) => e.toJson()).toList(),
      });
    } else if (areEqual) {
      areEqual = _areListsEqualSync(_items, newItems);
    }

    // Only update and notify if there are actual changes
    if (!areEqual) {
      _items = newItems;
      _allItems = newItems; // Make sure _allItems is also updated

      // Invalidate caches
      _lastFilterVersion = _items.hashCode;
      _cachedCompletedItems = null;
      _cachedPendingItems = null;

      // Reapply any active filters to the new data
      if (_searchActive || _tagFiltersActive) {
        applyFilters(_currentSearchQuery, _currentTagFilters);
      }

      notifyListeners();
    }
  }

  /// Check if two lists of items are equal by comparing their contents
  bool _areListsEqualSync(
    List<BucketListItem> list1,
    List<BucketListItem> list2,
  ) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].item != list2[i].item ||
          list1[i].price != list2[i].price ||
          list1[i].complete != list2[i].complete ||
          list1[i].details != list2[i].details ||
          list1[i].shareable != list2[i].shareable ||
          list1[i].image != list2[i].image) {
        return false;
      }

      // Check tags equality
      if (list1[i].tags.length != list2[i].tags.length) return false;

      for (int j = 0; j < list1[i].tags.length; j++) {
        if (list1[i].tags[j] != list2[i].tags[j]) return false;
      }
    }
    return true;
  }

  /// Static method for compute to compare lists in isolate
  static bool _areListsEqual(Map<String, List<dynamic>> params) {
    final list1 = params['list1']!;
    final list2 = params['list2']!;

    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id'] ||
          list1[i]['item'] != list2[i]['item'] ||
          list1[i]['price'] != list2[i]['price'] ||
          list1[i]['complete'] != list2[i]['complete'] ||
          list1[i]['details'] != list2[i]['details'] ||
          list1[i]['shareable'] != list2[i]['shareable'] ||
          list1[i]['image'] != list2[i]['image']) {
        return false;
      }

      // Compare tags (if they exist)
      final List<dynamic>? tags1 = list1[i]['tags'];
      final List<dynamic>? tags2 = list2[i]['tags'];

      final bool tagsEqual =
          (tags1 == null && tags2 == null) ||
          (tags1 != null &&
              tags2 != null &&
              tags1.length == tags2.length &&
              tags1.every((tag) => tags2.contains(tag)));

      if (!tagsEqual) {
        return false;
      }
    }
    return true;
  }

  /// Fetch bucket list items - manual refresh
  Future<void> fetchBucketList() async {
    if (_isFetchingData) return; // Prevent multiple simultaneous fetches

    _isFetchingData = true;

    // Only set loading if we don't have items yet to prevent flickering
    if (_items.isEmpty) {
      setLoading(true);
    }

    clearError();

    try {
      final items = await _syncService.getBucketListStream().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // If timeout occurs and we already have items, keep the existing items
          if (_items.isNotEmpty) {
            return _items;
          }
          throw TimeoutException('Data fetch timed out');
        },
      );
      await _updateItemsAsync(items);

      _allItems = items;

      // If filters were active, reapply them to the new data
      if (_searchActive || _tagFiltersActive) {
        // Reapply existing filters if any
        // You'll need to store the current search and tags as class properties
        applyFilters(_currentSearchQuery ?? '', _currentTagFilters ?? []);
      }
      // Don't set _filteredItems = [] when no filters are active
      // Let the items getter handle returning the appropriate list
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
      _isFetchingData = false;
    }
  }

  /// Add a new bucket list item
  Future<void> addBucketListItem(BucketListItem item) async {
    if (_isFetchingData) return;

    try {
      _isFetchingData = true;

      // Don't set loading state for fast operations to prevent UI flicker
      await _syncService.addBucketListItem(item);
      clearError();

      // Invalidate filter caches
      _lastFilterVersion = 0;
      _cachedCompletedItems = null;
      _cachedPendingItems = null;
    } catch (e) {
      setError(e.toString());
    } finally {
      _isFetchingData = false;
    }
  }

  /// Update an existing bucket list item
  Future<void> updateBucketListItem(BucketListItem item) async {
    if (_isFetchingData) return;

    try {
      _isFetchingData = true;
      try {
        await _syncService.updateBucketListItem(item);
        clearError();

        // Invalidate filter caches
        _lastFilterVersion = 0;
        _cachedCompletedItems = null;
        _cachedPendingItems = null;
      } catch (e) {
        // If item not found, try to force sync it first
        if (e.toString().contains('not found')) {
          await _syncService.forceSyncItem(item.id);
          // Try update again after sync
          await _syncService.updateBucketListItem(item);
          clearError();
        } else {
          rethrow;
        }
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      _isFetchingData = false;
    }
  }

  /// Delete a bucket list item by ID
  Future<void> deleteBucketListItem(String id) async {
    if (_isFetchingData) return;

    try {
      _isFetchingData = true;
      await _syncService.deleteBucketListItem(id);
      clearError();

      // Invalidate filter caches
      _lastFilterVersion = 0;
      _cachedCompletedItems = null;
      _cachedPendingItems = null;
    } catch (e) {
      setError(e.toString());
    } finally {
      _isFetchingData = false;
    }
  }

  /// Toggle the completion status of a bucket list item
  Future<void> toggleItemComplete(BucketListItem item) async {
    final updatedItem = item.copyWith(complete: !item.complete);
    await updateBucketListItem(updatedItem);
  }

  /// Toggle the shareability status of a bucket list item
  Future<void> toggleItemShareable(BucketListItem item) async {
    try {
      _isFetchingData = true;

      // Create an updated item with toggled shareable status and preserve all other properties
      final updatedItem = item.copyWith(
        shareable: !item.shareable,
        // Explicitly include tags to ensure they're preserved during the toggle
        tags: List<String>.from(item.tags),
      );

      // If making non-shareable and had a userId, we need to ensure it's removed from Firestore
      if (item.shareable && item.userId.isNotEmpty) {
        await _syncService.deleteBucketListItem(item.id);
      }

      // Update the item in local storage (and Firestore if shareable and authenticated)
      await updateBucketListItem(updatedItem);
      clearError();

      // Invalidate filter caches
      _lastFilterVersion = 0;
      _cachedCompletedItems = null;
      _cachedPendingItems = null;
    } catch (e) {
      setError(e.toString());
    } finally {
      _isFetchingData = false;
    }
  }

  // Add a method to apply filters
  void applyFilters(String searchQuery, List<String> tags) {
    _currentSearchQuery = searchQuery.toLowerCase();
    _currentTagFilters = tags;

    _searchActive = searchQuery.isNotEmpty;
    _tagFiltersActive = tags.isNotEmpty;

    // When no filters are active, clear _filteredItems and return all items
    if (!_searchActive && !_tagFiltersActive) {
      _filteredItems = []; // Set to empty so the getter returns _allItems
      notifyListeners();
      return;
    }

    // Apply filters
    _filteredItems =
        _allItems.where((item) {
          // Search filter
          bool matchesSearch =
              !_searchActive ||
              item.item.toLowerCase().contains(_currentSearchQuery) ||
              (item.details?.toLowerCase().contains(_currentSearchQuery) ??
                  false);

          // Tag filter
          bool matchesTags =
              !_tagFiltersActive ||
              _currentTagFilters.any((tag) => item.tags.contains(tag));

          return matchesSearch && matchesTags;
        }).toList();

    notifyListeners();
  }

  /// Clear all active filters and reset to showing all items
  void clearFilters() {
    // Reset filter state variables
    _currentSearchQuery = '';
    _currentTagFilters = [];
    _searchActive = false;
    _tagFiltersActive = false;
    _filteredItems = []; // Set to empty so the items getter returns _allItems

    // Notify listeners to update UI
    notifyListeners();
  }

  @override
  void dispose() {
    _bucketListSubscription?.cancel();
    super.dispose();
  }
}
