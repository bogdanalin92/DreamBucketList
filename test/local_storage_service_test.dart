import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bucketlist/services/local_storage_service.dart';
import 'package:bucketlist/models/bucket_list_item.dart';

void main() {
  late LocalStorageService storageService;
  late SharedPreferences prefs;

  setUp(() async {
    // Initialize SharedPreferences
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(prefs);
  });

  group('LocalStorageService Tests', () {
    test('initially returns empty list when no items are stored', () async {
      final items = await storageService.getBucketListItems();
      expect(items, isEmpty);
    });

    test('can add and retrieve a bucket list item', () async {
      // Create a test item
      final testItem = BucketListItem(
        userId: 'test-user',
        id: 'test-id',
        item: 'Test Bucket List Item',
        price: 100.0,
        details: 'Test details',
        complete: false,
        shareable: true,
      );

      // Add the item
      await storageService.addBucketListItem(testItem);

      // Retrieve items
      final items = await storageService.getBucketListItems();

      // Verify
      expect(items, hasLength(1));
      expect(items.first.id, equals(testItem.id));
      expect(items.first.item, equals(testItem.item));
      expect(items.first.price, equals(testItem.price));
      expect(items.first.details, equals(testItem.details));
      expect(items.first.complete, equals(testItem.complete));
      expect(items.first.shareable, equals(testItem.shareable));
    });

    test('can update an existing item', () async {
      // Create and add initial item
      final initialItem = BucketListItem(
        userId: 'test-user',
        id: 'test-id',
        item: 'Initial Item',
        complete: false,
      );
      await storageService.addBucketListItem(initialItem);

      // Create updated version
      final updatedItem = initialItem.copyWith(
        item: 'Updated Item',
        complete: true,
      );

      // Update the item
      await storageService.updateBucketListItem(updatedItem);

      // Retrieve and verify
      final items = await storageService.getBucketListItems();
      expect(items, hasLength(1));
      expect(items.first.item, equals('Updated Item'));
      expect(items.first.complete, isTrue);
    });

    test('can delete an item', () async {
      // Create and add an item
      final testItem = BucketListItem(
        userId: 'test-user',
        id: 'test-id',
        item: 'Test Item',
      );
      await storageService.addBucketListItem(testItem);

      // Verify item was added
      var items = await storageService.getBucketListItems();
      expect(items, hasLength(1));

      // Delete the item
      await storageService.deleteBucketListItem(testItem.id);

      // Verify item was deleted
      items = await storageService.getBucketListItems();
      expect(items, isEmpty);
    });

    test('can save and retrieve multiple items', () async {
      // Create test items
      final items = [
        BucketListItem(userId: 'user1', id: 'id1', item: 'Item 1'),
        BucketListItem(userId: 'user1', id: 'id2', item: 'Item 2'),
        BucketListItem(userId: 'user1', id: 'id3', item: 'Item 3'),
      ];

      // Save all items
      await storageService.saveBucketListItems(items);

      // Retrieve and verify
      final retrievedItems = await storageService.getBucketListItems();
      expect(retrievedItems, hasLength(3));
      expect(
        retrievedItems.map((item) => item.id).toList(),
        equals(['id1', 'id2', 'id3']),
      );
    });
  });
}
