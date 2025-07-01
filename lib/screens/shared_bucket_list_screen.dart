import 'dart:io';
import 'dart:async';
import 'package:bucketlist/widgets/list_tile_ad_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bucketlist/screens/qr_code_screen.dart';
import 'package:bucketlist/screens/qr_scanner_screen.dart';
import 'package:bucketlist/services/interfaces/firebase_service_interface.dart';
import 'package:bucketlist/utils/qr_scanner_util.dart';
import 'package:bucketlist/widgets/medium_rectangle_ad_widget.dart';
import 'package:bucketlist/widgets/native_ad_item_widget.dart';
import 'package:bucketlist/widgets/universal_image.dart';
import 'package:bucketlist/services/local_image_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/bucket_list_item.dart';
import '../services/ad_service.dart';
import '../services/firebase_services_factory.dart';

enum ViewMode { myShared, userShared }

class SharedBucketListScreen extends StatefulWidget {
  final FirebaseServiceInterface? firebaseService;
  const SharedBucketListScreen({super.key, this.firebaseService});

  @override
  State<SharedBucketListScreen> createState() => _SharedBucketListScreenState();
}

class _SharedBucketListScreenState extends State<SharedBucketListScreen>
    with SingleTickerProviderStateMixin {
  late final FirebaseServiceInterface _firebaseService;
  Stream<List<BucketListItem>>? _itemsStream;
  StreamSubscription<List<BucketListItem>>? _streamSubscription;
  final TextEditingController _uidController = TextEditingController();
  String? _currentUserUid;
  bool _isLoading = false;
  ViewMode _currentViewMode = ViewMode.myShared;
  late TabController _tabController;
  // Cache for user display names
  final Map<String, String> _userDisplayNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _firebaseService =
        widget.firebaseService ?? FirebaseServicesFactory().firestoreService;
    _loadUser();
    _loadOwnSharedItems();

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _loadOwnSharedItems();
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _uidController.dispose();
    _tabController.dispose();
    QRScannerUtil.dispose();
    super.dispose();
  }

  void _loadOwnSharedItems() {
    setState(() {
      _isLoading = true;
      _currentUserUid = _firebaseService.currentUser?.uid;
      _currentViewMode = ViewMode.myShared;
    });

    _streamSubscription?.cancel();

    final stream =
        _firebaseService.getBucketListStream().map((items) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return items
              .where((item) => item.shareable && item.userId == _currentUserUid)
              .toList();
        }).asBroadcastStream();

    setState(() {
      _itemsStream = stream;
    });
  }

  void _loadUserItems(String uid) {
    uid = uid.trim();
    if (uid.isEmpty) {
      _loadOwnSharedItems();
      return;
    }

    final currentUserId = _firebaseService.currentUser?.uid;
    if (currentUserId != null && uid == currentUserId) {
      _loadOwnSharedItems();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentUserUid = uid;
      _currentViewMode = ViewMode.userShared;
    });

    _streamSubscription?.cancel();

    final stream =
        _firebaseService.getSharedBucketListByUserId(uid).map((items) {
          if (mounted) setState(() => _isLoading = false);
          return currentUserId != null
              ? items.where((item) => item.userId != currentUserId).toList()
              : items;
        }).asBroadcastStream();

    setState(() {
      _itemsStream = stream;
    });
  }

  Future<void> _scanQRCode() async {
    final scannedUid = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedUid != null && scannedUid.isNotEmpty) {
      _uidController.text = scannedUid;
      _loadUserItems(scannedUid);
    }
  }

  Future<void> _uploadQRCodeImage() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String? scannedUid = await QRScannerUtil.scanQRFromImage(
        File(image.path),
      );

      setState(() => _isLoading = false);

      if (scannedUid == null || scannedUid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid QR code found in image')),
        );
        return;
      }

      _uidController.text = scannedUid;
      _loadUserItems(scannedUid);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning QR code: $e')));
    }
  }

  Future<String> _getUserDisplayName(String userId) async {
    if (_userDisplayNames.containsKey(userId)) {
      return _userDisplayNames[userId]!;
    }

    try {
      // First try to get display name from Firebase Auth if it's the current user
      if (userId == _firebaseService.currentUser?.uid) {
        final currentUser = _firebaseService.currentUser;
        if (currentUser?.displayName?.isNotEmpty == true) {
          _userDisplayNames[userId] = currentUser!.displayName!;
          return currentUser.displayName!;
        }
      }

      // If not current user or no display name, try Firestore
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final userData = await userRef.get();

      String displayName = userId;
      if (userData.exists) {
        displayName =
            userData.data()?['displayName'] ??
            userData.data()?['email']?.toString().split('@').first ??
            userId;
      }

      _userDisplayNames[userId] = displayName;
      return displayName;
    } catch (e) {
      return userId;
    }
  }

  // Method to handle converting local images to network URLs when sharing items
  Future<BucketListItem> _prepareItemForSharing(BucketListItem item) async {
    final LocalImageService _localImageService = LocalImageService();

    if (item.image != null && _localImageService.isLocalPath(item.image!)) {
      try {
        // Upload local image to Imgur
        final networkUrl = await _localImageService.convertLocalToNetworkImage(
          item.image!,
        );
        // Return a copy of the item with the network URL
        return item.copyWith(image: networkUrl);
      } catch (e) {
        // Log the error and continue with the original item
        debugPrint('Error uploading image for sharing: $e');
        return item;
      }
    }
    return item;
  }

  Widget _buildBucketListContent() {
    return StreamBuilder<List<BucketListItem>>(
      stream: _itemsStream,
      builder: (context, snapshot) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading shared items: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (_currentViewMode == ViewMode.myShared) {
            return const Center(
              child: Text(
                'You haven\'t shared any bucket list items yet.\n\n'
                'Make items shareable from your bucket list!',
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return Center(
              child: Text(
                'No shared items found for user ID: $_currentUserUid',
                textAlign: TextAlign.center,
              ),
            );
          }
        }

        final items = snapshot.data!;
        final adService = Provider.of<AdService>(context, listen: false);
        final itemsWithAds = <dynamic>[];

        // Add ListTileAdWidget at the beginning for user shared mode
        if (_currentViewMode == ViewMode.userShared && !_isLoading) {
          itemsWithAds.add('listTileAd');
        }

        // Insert ads into the list
        for (int i = 0; i < items.length; i++) {
          itemsWithAds.add(items[i]);

          // Insert an ad after every few items
          if (adService.shouldShowAdAtPosition(i)) {
            itemsWithAds.add('ad');
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: itemsWithAds.length,
          itemBuilder: (context, index) {
            final item = itemsWithAds[index];

            // Check if it's the ListTileAdWidget
            if (item == 'listTileAd') {
              return const ListTileAdWidget();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading:
                    item.complete
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.radio_button_unchecked),
                title: Text(
                  item.item,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    item.price != null
                        ? Text(
                          '\$${item.price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        : null,

                children: [
                  if (item.image != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: UniversalImage(
                          imagePath: item.image!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (item.details?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: Text(
                        item.details!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FutureBuilder<String>(
                            future: _getUserDisplayName(item.userId),
                            builder: (context, snapshot) {
                              final displayName =
                                  _userDisplayNames[item.userId];
                              return Text(
                                'Shared by: $displayName',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                        if (item.lastModified != null)
                          Text(
                            'Updated: ${_formatDate(item.lastModified!)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMySharedTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Theme.of(context).colorScheme.surfaceTint,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QRCodeScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Sharing QR Code',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view your QR code that others can scan',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Add a banner ad below the QR code section
        const MediumRectangleAdWidget(),

        Expanded(child: _buildBucketListContent()),
      ],
    );
  }

  Widget _buildSearchTab() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _uidController,
                    decoration: InputDecoration(
                      labelText: 'Enter User ID or Scan QR Code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanQRCode,
                            tooltip: 'Scan QR Code',
                          ),
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: _uploadQRCodeImage,
                            tooltip: 'Upload QR Code Image',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : () => _loadUserItems(_uidController.text),
                    icon: const Icon(Icons.search),
                    label: Text(
                      'Search Shared Dreams',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                        EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        theme.colorScheme.surfaceTint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Add a medium rectangle ad between search and results
        if (_currentViewMode == ViewMode.userShared)
          Expanded(child: _buildBucketListContent()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Dreams'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.surfaceTint,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'My Shared'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMySharedTab(), _buildSearchTab()],
      ),
    );
  }

  void _loadUser() {
    if (_firebaseService.currentUser != null &&
        _firebaseService.currentUser!.isAnonymous) {
      _currentUserUid = _firebaseService.currentUser!.uid;
    }
  }
}
