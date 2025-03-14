/// Base interface for repositories
///
/// Defines common operations that all repositories should implement.
/// Specific repository interfaces can extend this interface to add their own operations.
abstract class RepositoryInterface {
  /// Initialize the repository
  Future<void> initialize();

  /// Dispose of any resources used by the repository
  void dispose();
}
