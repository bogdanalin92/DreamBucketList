import 'package:bucketlist/constants/tag_constants.dart';
import 'package:bucketlist/widgets/cached_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../addBucket.dart';
import '../viewItem.dart';
import 'models/bucket_list_item.dart';
import 'viewmodels/bucket_list_view_model.dart';
import 'screens/profile_screen.dart';
import 'screens/shared_bucket_list_screen.dart';
import 'services/ad_service.dart';
import 'widgets/native_ad_item_widget.dart';
import 'widgets/universal_image.dart'; // Import the UniversalImage widget

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => MainscreenState();
}

class MainscreenState extends State<Mainscreen>
    with AutomaticKeepAliveClientMixin {
  int currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  static const cardBorderRadius = BorderRadius.all(Radius.circular(16));
  static const containerBorderRadius = BorderRadius.all(Radius.circular(12));

  final List<Widget> _cachedPages = List.generate(3, (_) => Container());

  String _searchQuery = '';
  final Set<String> _selectedFilterTags = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();

    // Call applyFilters with empty values after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<BucketListViewModel>(
        context,
        listen: false,
      );
      _applyFilters(viewModel);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _getPage(int index) {
    if (_cachedPages[index] is Container) {
      Widget page;
      switch (index) {
        case 0:
          page = _buildHomeContent();
          break;
        case 1:
          page = const AddBucketListScreen();
          break;
        case 2:
          page = const ProfileScreen();
          break;
        default:
          page = Container();
      }
      _cachedPages[index] = page;
    }
    return _cachedPages[index];
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: containerBorderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  brightness == Brightness.dark
                      ? [theme.colorScheme.surface, theme.colorScheme.surface]
                      : [Colors.blue.shade50, Colors.white],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildViewFilterBar(),
              Expanded(
                child: Consumer<BucketListViewModel>(
                  builder: (context, viewModel, child) {
                    return RefreshIndicator(
                      color: theme.colorScheme.primary,
                      onRefresh: () => viewModel.fetchBucketList(),
                      child: _buildBucketListView(viewModel),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBucketListView(BucketListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.items.isEmpty) {
      // Only show loading indicator if we don't have any items yet
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.hasError) {
      return Center(child: Text('Error: ${viewModel.errorMessage}'));
    }

    if (viewModel.items.isEmpty) {
      return const Center(
        child: Text('No dreams added yet. Add your first dream!'),
      );
    }

    // Calculate the total count with ads
    final adService = Provider.of<AdService>(context, listen: false);
    final itemsWithAds = <dynamic>[];

    // Prepare the list with ads
    for (int i = 0; i < viewModel.items.length; i++) {
      itemsWithAds.add(viewModel.items[i]);

      // Insert an ad after every few items
      if (adService.shouldShowAdAtPosition(i)) {
        itemsWithAds.add('ad'); // Placeholder for ad
      }
    }

    // Using ListView.builder with better performance optimizations
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: itemsWithAds.length,
      // Add cacheExtent to pre-render more items
      cacheExtent: 200,
      // Add findChildIndexCallback for more efficient item finding
      findChildIndexCallback: (Key key) {
        if (key is! ValueKey<String>) return null;

        final ValueKey<String> valueKey = key;
        final index = viewModel.items.indexWhere(
          (item) => item.id == valueKey.value,
        );
        return index >= 0 ? index : null;
      },
      itemBuilder: (context, index) {
        final item = itemsWithAds[index];

        // Check if it's an ad placeholder
        if (item == 'ad') {
          return const NativeAdItemWidget();
        }

        // Otherwise build the normal item
        return _buildBucketListItem(item);
      },
    );
  }

  Widget _buildBucketListItem(BucketListItem item) {
    final theme = Theme.of(context);

    // Use RepaintBoundary to isolate painting operations
    return RepaintBoundary(
      child: Card(
        key: ValueKey(item.id),
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
        child: InkWell(
          borderRadius: cardBorderRadius,
          onTap: () => _onItemTap(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (item.image != null) _buildItemImage(item),
                if (item.image != null) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.item,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (item.price != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '\$${item.price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Color.alphaBlend(
                              Color.alphaBlend(
                                Colors.grey.withAlpha(77),
                                theme.colorScheme.onSurface,
                              ),
                              theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Sync status icon based on shareable flag and sync status
                if (item.shareable) ...[
                  if (item.isSyncedWithFirebase)
                    CachedIcon(
                      icon: Icons.cloud_done,
                      size: 20,
                      color: theme.colorScheme.primary,
                    )
                  else
                    CachedIcon(
                      icon: Icons.cloud_upload,
                      size: 20,
                      color: theme.colorScheme.primary.withAlpha(55),
                    ),
                ] else if (!item.shareable) ...[
                  CachedIcon(
                    icon: Icons.cloud_off,
                    size: 20,
                    color: theme.colorScheme.error.withAlpha(55),
                  ),
                ],
                const SizedBox(width: 12),
                CachedIcon(
                  icon:
                      item.complete
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                  color:
                      item.complete
                          ? theme.colorScheme.primary
                          : Color.alphaBlend(
                            Colors.grey.withAlpha(55),
                            theme.colorScheme.onSurface,
                          ),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Extract image widget to a separate method for better readability and optimization
  Widget _buildItemImage(BucketListItem item) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      // Wrap image in fixed size container to prevent layout shifts
      child: SizedBox(
        width: 60,
        height: 60,
        child: Hero(
          tag: 'image_${item.id}',
          child: UniversalImage(
            imagePath: item.image!,
            fit: BoxFit.cover,
            placeholder: Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
            ),
            errorWidget: Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            "My Bucket List",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SharedBucketListScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.share_outlined,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: "View Shared Items",
          ),
          IconButton(
            onPressed: showAboutApp,
            icon: Icon(Icons.info_outline, color: theme.colorScheme.onSurface),
            tooltip: "About",
          ),
        ],
      ),
    );
  }

  void showAboutApp() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.beach_access, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "About Bucket List",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Version 1.0",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.alphaBlend(
                      Colors.grey.withOpacity(0.4),
                      theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Features:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFeatureItem("Add your dream items"),
                _buildFeatureItem("Track completion status"),
                _buildFeatureItem("Set price goals"),
                _buildFeatureItem("Add beautiful images"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  Widget _buildFeatureItem(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }

  void _onItemTap(BucketListItem item) {
    // Hide keyboard before navigating to details
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewItemBucket(bucketlistitem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      // Hide keyboard when tapping outside of any input field
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: _getPage(currentIndex), // Get the appropriate page
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: currentIndex,
          onTap: (position) {
            // Hide keyboard when switching tabs
            FocusScope.of(context).unfocus();
            setState(() => currentIndex = position);
          },
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.list_alt),
              title: const Text("Dreams"),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.add_circle),
              title: const Text("Add Dream"),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person),
              title: const Text("Profile"),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  _buildViewFilterBar() {
    final theme = Theme.of(context);
    final viewModel = Provider.of<BucketListViewModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your dreams...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters(viewModel);
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters(viewModel);
              });
            },
          ),
        ),

        // Tag filter section with horizontal scrolling
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Consumer<BucketListViewModel>(
            builder: (context, viewModel, _) {
              return Row(
                children: [
                  Text(
                    'Filter by: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  // Show Clear All button when ANY filter exists (search or tags)
                  if (_searchQuery.isNotEmpty || _selectedFilterTags.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear All Filters'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedFilterTags.clear();
                          // Use the new clearFilters method
                          viewModel.clearFilters();
                        });
                      },
                    ),
                ],
              );
            },
          ),
        ),

        // Tag filter section with horizontal scrolling
        SizedBox(
          height: 50,
          child: Consumer<BucketListViewModel>(
            builder: (context, viewModel, _) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children:
                    TagConstants.allTagIds.map((tagId) {
                      final isSelected = _selectedFilterTags.contains(tagId);
                      final tagName = TagConstants.getTagName(tagId);
                      final tagColor = TagConstants.getTagColor(tagId);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          key: ValueKey('tag_${tagId}_${isSelected}'),
                          label: Text(tagName),
                          selected: isSelected,
                          checkmarkColor: Colors.white,
                          selectedColor: tagColor,
                          backgroundColor: tagColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFilterTags.add(tagId);
                              } else {
                                _selectedFilterTags.remove(tagId);
                              }
                              _applyFilters(viewModel);
                            });
                          },
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ),

        // Active filter indicators
        Consumer<BucketListViewModel>(
          builder: (context, viewModel, _) {
            if (_searchQuery.isNotEmpty || _selectedFilterTags.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Chip(
                        label: Text('Search: $_searchQuery'),
                        onDeleted: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters(viewModel);
                          });
                        },
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ..._selectedFilterTags.map((tagId) {
                      return Chip(
                        label: Text(TagConstants.getTagName(tagId)),
                        onDeleted: () {
                          setState(() {
                            _selectedFilterTags.remove(tagId);
                            _applyFilters(viewModel);
                          });
                        },
                        backgroundColor: TagConstants.getTagColor(
                          tagId,
                        ).withOpacity(0.2),
                      );
                    }),
                  ],
                ),
              );
            }
            return const SizedBox.shrink(); // Return empty widget when no filters
          },
        ),
      ],
    );
  }

  void _applyFilters(BucketListViewModel viewModel) {
    viewModel.applyFilters(_searchQuery, _selectedFilterTags.toList());
  }
}
