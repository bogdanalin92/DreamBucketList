import '../services/firebase_services_factory.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import 'bucket_list_repository.dart';
import 'interfaces/bucket_list_repository_interface.dart';

/// Factory class for creating BucketListRepository instances with proper dependencies
class BucketListRepositoryFactory {
  static BucketListRepositoryFactory? _instance;
  BucketListRepositoryInterface? _repository;

  BucketListRepositoryFactory._();

  static BucketListRepositoryFactory get instance {
    _instance ??= BucketListRepositoryFactory._();
    return _instance!;
  }

  /// Get or create a singleton instance of BucketListRepository
  Future<BucketListRepositoryInterface> getRepository() async {
    if (_repository != null) {
      return _repository!;
    }

    // Create and initialize local storage service
    final localStorageService = await LocalStorageService.create();

    // Get Firebase service
    final firebaseService = FirebaseServicesFactory().firestoreService;

    // Create sync service with both storage implementations
    final syncService = SyncService(
      firebaseService: firebaseService,
      localStorageService: localStorageService,
    );

    // Create and initialize repository
    _repository = BucketListRepository(syncService, firebaseService);
    await _repository!.initialize();

    return _repository!;
  }

  /// Dispose of the current repository instance
  void dispose() {
    _repository?.dispose();
    _repository = null;
  }
}
