import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/bucket_list_item.dart';
import 'viewmodels/bucket_list_view_model.dart';
import 'utils/image_picker_helper.dart';
import 'widgets/medium_rectangle_ad_widget.dart';
import 'widgets/universal_image.dart';
import 'services/local_image_service.dart';
import 'providers/auth_provider.dart';
import 'constants/tag_constants.dart'; // Import tag constants

class ViewItemBucket extends StatefulWidget {
  final BucketListItem bucketlistitem;
  const ViewItemBucket({super.key, required this.bucketlistitem});

  @override
  State<ViewItemBucket> createState() => _ViewItemBucketState();
}

class _ViewItemBucketState extends State<ViewItemBucket> {
  late TextEditingController itemController;
  late TextEditingController priceController;
  late TextEditingController imageController;
  late TextEditingController detailsController;
  late bool isComplete;
  late bool isShareable; // Add shareable state
  late List<String> _selectedTags; // For storing selected tags
  bool _isEditMode = false;
  bool _isUploadingImage = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    itemController = TextEditingController(text: widget.bucketlistitem.item);
    priceController = TextEditingController(
      text: widget.bucketlistitem.price?.toString() ?? '',
    );
    imageController = TextEditingController(
      text: widget.bucketlistitem.image ?? '',
    );
    detailsController = TextEditingController(
      text: widget.bucketlistitem.details ?? '',
    );
    isComplete = widget.bucketlistitem.complete;
    isShareable = widget.bucketlistitem.shareable; // Initialize shareable state
    _selectedTags = List<String>.from(
      widget.bucketlistitem.tags,
    ); // Initialize selected tags
  }

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    imageController.dispose();
    detailsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Toggle tag selection
  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else {
        _selectedTags.add(tagId);
      }
    });
  }

  // Widget to build tag selector chips for edit mode
  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Tags (optional)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              TagConstants.allTagIds.map((tagId) {
                final isSelected = _selectedTags.contains(tagId);
                final tagName = TagConstants.getTagName(tagId);
                final tagColor = TagConstants.getTagColor(tagId);
                final tagIcon = TagConstants.getTagIcon(tagId);

                return FilterChip(
                  label: Text(tagName),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tagId),
                  avatar: Icon(
                    tagIcon,
                    color: isSelected ? Colors.white : tagColor,
                    size: 18,
                  ),
                  backgroundColor: tagColor.withOpacity(0.1),
                  selectedColor: tagColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  checkmarkColor: Colors.white,
                  elevation: isSelected ? 2 : 0,
                  pressElevation: 2,
                );
              }).toList(),
        ),
      ],
    );
  }

  // Widget to display tags in view mode
  Widget _buildTagsDisplay() {
    if (_selectedTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Tags:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              _selectedTags.map((tagId) {
                final tagName = TagConstants.getTagName(tagId);
                final tagColor = TagConstants.getTagColor(tagId);
                final tagIcon = TagConstants.getTagIcon(tagId);

                return Chip(
                  label: Text(tagName),
                  avatar: Icon(tagIcon, color: Colors.white, size: 16),
                  backgroundColor: tagColor,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
        ),
      ],
    );
  }

  double? _parsePrice(String? text) {
    if (text == null || text.isEmpty) return null;
    final cleanString = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanString);
  }

  Future<void> _pickAndUploadImage() async {
    // Set uploading state to prevent multiple simultaneous uploads
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ImagePickerHelper.pickAndUploadImage(context);

      if (imageUrl != null) {
        setState(() {
          imageController.text = imageUrl;
        });
      }
    } finally {
      // Reset uploading state
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _updateItem() async {
    // Hide keyboard before updating
    FocusScope.of(context).unfocus();

    final viewModel = context.read<BucketListViewModel>();
    final localImageService = LocalImageService();
    final authProvider = context.read<AuthProvider>();

    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving changes...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Handle image conversion for shareable items before submitting
    String? imageUrl =
        imageController.text.isEmpty ? null : imageController.text;

    try {
      // Case 1: Making the item shareable and it has a local image
      if (isShareable &&
          imageUrl != null &&
          localImageService.isLocalPath(imageUrl)) {
        // Show upload progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image for sharing...')),
        );

        // Upload the local image to Imgur
        imageUrl = await localImageService.convertLocalToNetworkImage(imageUrl);
      }
      // Case 2: Making the item non-shareable and it has a network image
      else if (!isShareable &&
          imageUrl != null &&
          !localImageService.isLocalPath(imageUrl) &&
          authProvider.isAnonymous) {
        // Show download progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Converting to local storage...')),
        );

        final String networkUrl = imageUrl;

        // Download the image and store it locally
        final String localPath = await localImageService
            .convertNetworkToLocalImage(networkUrl);

        // Delete the network image from Imgur
        await localImageService.deleteNetworkImage(networkUrl);

        // Update the image URL to local path
        imageUrl = localPath;
      }
    } catch (e) {
      // If there's an error with image conversion, show it but continue with save
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    final updatedItem = BucketListItem(
      userId: widget.bucketlistitem.userId,
      id: widget.bucketlistitem.id,
      item: itemController.text,
      price: _parsePrice(priceController.text),
      image: imageUrl,
      details: detailsController.text.isEmpty ? null : detailsController.text,
      complete: isComplete,
      shareable: isShareable, // Include shareable in updates
      tags: _selectedTags, // Include updated tags in the item
    );

    // Navigate back immediately
    if (mounted) {
      Navigator.pop(context);
    }

    // Perform the update in the background
    try {
      await viewModel.updateBucketListItem(updatedItem);
    } catch (e) {
      // If there's an error, show it to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleComplete() async {
    final viewModel = context.read<BucketListViewModel>();

    // Create updated item with toggled complete status
    final updatedItem = widget.bucketlistitem.copyWith(complete: isComplete);

    try {
      await viewModel.updateBucketListItem(updatedItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Revert the state if updating fails
        setState(() {
          isComplete = !isComplete;
        });
      }
    }
  }

  Future<void> _toggleShareable() async {
    final viewModel = context.read<BucketListViewModel>();
    final authProvider = context.read<AuthProvider>();
    final localImageService = LocalImageService();

    // Case 1: Making the item shareable and it has a local image
    if (isShareable &&
        imageController.text.isNotEmpty &&
        localImageService.isLocalPath(imageController.text)) {
      try {
        // Show upload progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image for sharing...')),
        );

        // Upload the local image to Imgur
        final String networkUrl = await localImageService
            .convertLocalToNetworkImage(imageController.text);

        // Update the image URL
        setState(() {
          imageController.text = networkUrl;
        });

        // Create the updated item with shareable and the new network image
        final updatedItem = widget.bucketlistitem.copyWith(
          shareable: isShareable,
          image: networkUrl,
          tags: _selectedTags, // Include current tags when updating
        );

        await viewModel.updateBucketListItem(updatedItem);
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error uploading image for sharing: ${e.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          // Revert the state if updating fails
          setState(() {
            isShareable = !isShareable;
          });
          return;
        }
      }
    }
    // Case 2: Making the item non-shareable and it has a network image
    else if (!isShareable &&
        imageController.text.isNotEmpty &&
        !localImageService.isLocalPath(imageController.text) &&
        authProvider.isAnonymous) {
      try {
        // Show download progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Converting to local storage...')),
        );

        final String networkUrl = imageController.text;

        // Download the image and store it locally
        final String localPath = await localImageService
            .convertNetworkToLocalImage(networkUrl);

        // Delete the network image from Imgur
        await localImageService.deleteNetworkImage(networkUrl);

        // Update the image URL to local path
        setState(() {
          imageController.text = localPath;
        });

        // Create the updated item with non-shareable and the new local image
        final updatedItem = widget.bucketlistitem.copyWith(
          shareable: isShareable,
          image: localPath,
          tags: _selectedTags, // Include current tags when updating
        );

        await viewModel.updateBucketListItem(updatedItem);
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error converting to local storage: ${e.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          // Revert the state if updating fails
          setState(() {
            isShareable = !isShareable;
          });
          return;
        }
      }
    }

    // Normal flow for cases that don't need image conversion
    final updatedItem = widget.bucketlistitem.copyWith(
      shareable: isShareable,
      tags: _selectedTags, // Include current tags when updating
    );
    try {
      await viewModel.updateBucketListItem(updatedItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating sharing status: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Revert the state if updating fails
        setState(() {
          isShareable = !isShareable;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    final viewModel = context.read<BucketListViewModel>();

    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting dream...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Navigate back immediately
    if (mounted) {
      Navigator.pop(context);
    }

    // Delete in background
    try {
      await viewModel.deleteBucketListItem(widget.bucketlistitem.id);
    } catch (e) {
      // If there's an error, show it to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting dream: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Dream'),
            content: const Text('Are you sure you want to delete this dream?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _deleteItem();
    }
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      // Hide keyboard when exiting edit mode
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Hide keyboard when navigating back
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditMode ? 'Edit Dream' : 'Dream Details',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          backgroundColor: theme.colorScheme.surface,
          actions: [
            if (!_isEditMode)
              IconButton(
                icon: Icon(Icons.edit, color: theme.colorScheme.onSurface),
                onPressed: _toggleEditMode,
                tooltip: 'Edit',
              ),
            if (!_isEditMode)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: _showDeleteConfirmation,
                tooltip: 'Delete',
              ),
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: _updateItem,
                tooltip: 'Save',
              ),
            if (_isEditMode)
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.error),
                onPressed: _toggleEditMode,
                tooltip: 'Cancel',
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_isEditMode && widget.bucketlistitem.image != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'image_${widget.bucketlistitem.id}',
                              child: UniversalImage(
                                imagePath: widget.bucketlistitem.image!,
                                fit: BoxFit.cover,
                                placeholder: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: Icon(
                                  Icons.error,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditMode) ...[
                          Text(
                            widget.bucketlistitem.item,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.bucketlistitem.price != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '\$${widget.bucketlistitem.price!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Display tags in view mode (if any exists)
                          if (_selectedTags.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Tags:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children:
                                  _selectedTags.map((tagId) {
                                    final tagName = TagConstants.getTagName(
                                      tagId,
                                    );
                                    final tagColor = TagConstants.getTagColor(
                                      tagId,
                                    );
                                    final tagIcon = TagConstants.getTagIcon(
                                      tagId,
                                    );

                                    return Chip(
                                      label: Text(tagName),
                                      avatar: Icon(
                                        tagIcon,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      backgroundColor: tagColor,
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],

                          const SizedBox(height: 16),
                          if (widget.bucketlistitem.details?.isNotEmpty ==
                              true) ...[
                            Text(
                              widget.bucketlistitem.details!,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          ListTile(
                            title: Text(
                              'Completed',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color:
                                    isComplete
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.2,
                                        )
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                isComplete ? 'Yes' : 'No',
                                style: TextStyle(
                                  color:
                                      isComplete
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          ListTile(
                            title: Text(
                              'Shareable',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Allow sharing through QR code',
                              style: TextStyle(
                                color: Color.alphaBlend(
                                  Colors.grey.withAlpha(33),
                                  theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color:
                                    isShareable
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.2,
                                        )
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                isShareable ? 'Yes' : 'No',
                                style: TextStyle(
                                  color:
                                      isShareable
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_isEditMode) ...[
                          TextFormField(
                            controller: itemController,
                            decoration: InputDecoration(
                              labelText: 'Dream Title',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Price (optional)',
                              prefixText: '\$ ',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Add tag selector in edit mode
                          _buildTagSelector(),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: imageController,
                                  decoration: InputDecoration(
                                    labelText: 'Image URL (optional)',
                                    border: const OutlineInputBorder(),
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    _isUploadingImage
                                        ? null
                                        : _pickAndUploadImage,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(15),
                                  backgroundColor: theme.colorScheme.onSurface,
                                ),
                                child:
                                    _isUploadingImage
                                        ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  theme.colorScheme.onPrimary,
                                                ),
                                          ),
                                        )
                                        : const Icon(Icons.add_a_photo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: detailsController,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Already Completed?',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            value: isComplete,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (bool value) {
                              setState(() {
                                isComplete = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: Text(
                              'Shareable',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Allow sharing through QR code',
                              style: TextStyle(
                                color: Color.alphaBlend(
                                  Colors.grey.withAlpha(33),
                                  theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            value: isShareable,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (bool value) {
                              setState(() {
                                isShareable = value;
                              });
                              // Don't call _toggleShareable() here - we'll handle it when saving the form
                            },
                          ),
                        ],

                        // Add native ad at the bottom of view
                        const SizedBox(height: 32),
                        const MediumRectangleAdWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
