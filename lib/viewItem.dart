import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/bucket_list_item.dart';
import 'viewmodels/bucket_list_view_model.dart';
import 'utils/image_picker_helper.dart';
import 'widgets/medium_rectangle_ad_widget.dart';
import 'widgets/universal_image.dart';
import 'widgets/custom_text_form_field.dart';
import 'widgets/optimized_filter_chip.dart';
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color:
                    theme.brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tags (optional)',
                style: TextStyle(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  TagConstants.allTagIds.map((tagId) {
                    final isSelected = _selectedTags.contains(tagId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: OptimizedFilterChip(
                        key: ValueKey(tagId),
                        tagId: tagId,
                        isSelected: isSelected,
                        onSelected: (_) => _toggleTag(tagId),
                        textColor: theme.colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
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

    final updatedItem = widget.bucketlistitem.copyWith(
      item: itemController.text,
      price: _parsePrice(priceController.text),
      image: imageUrl,
      details: detailsController.text.isEmpty ? null : detailsController.text,
      complete: isComplete,
      shareable: isShareable,
      tags: List<String>.from(
        _selectedTags,
      ), // Ensure we create a new list from _selectedTags
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
            if (!_isEditMode)
              // Breadcrumb menu for non-edit mode actions
              PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'edit':
                      _toggleEditMode();
                      break;
                    case 'delete':
                      _showDeleteConfirmation();
                      break;
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: theme.colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit Dream',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete Dream',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                tooltip: 'More options',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                offset: const Offset(0, 40),
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
                          CustomTextFormField(
                            controller: itemController,
                            labelText: 'Dream Title',
                            prefixIcon: Icons.star_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your dream';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: priceController,
                            labelText: 'Estimated Price (optional)',
                            prefixIcon: Icons.attach_money,
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
                                child: CustomTextFormField(
                                  controller: imageController,
                                  labelText: 'Image (optional)',
                                  prefixIcon: Icons.image_outlined,
                                  keyboardType: TextInputType.url,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: ElevatedButton(
                                  onPressed:
                                      _isUploadingImage
                                          ? null
                                          : _pickAndUploadImage,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: detailsController,
                            labelText: 'Description (optional)',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 3,
                            alignLabelWithHint: true,
                          ),
                          const SizedBox(height: 24),
                          // Row with toggle buttons similar to addBucket
                          Row(
                            children: [
                              // Already Completed Toggle (compact)
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isComplete
                                          ? theme.colorScheme.primary
                                              .withOpacity(0.1)
                                          : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isComplete
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isComplete = !isComplete;
                                        });
                                      },
                                      icon: Icon(
                                        isComplete
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        color:
                                            isComplete
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline,
                                      ),
                                      tooltip: 'Mark as completed',
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Already Completed?',
                                                ),
                                                content: const Text(
                                                  'Mark this option if you\'ve already achieved this dream. '
                                                  'This helps you track your accomplishments.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('Got it'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: theme.colorScheme.outline,
                                      ),
                                      tooltip: 'More info',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Shareable Toggle (compact)
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isShareable
                                          ? theme.colorScheme.primary
                                              .withOpacity(0.1)
                                          : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isShareable
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed:
                                          _isUploadingImage
                                              ? null
                                              : () {
                                                setState(() {
                                                  isShareable = !isShareable;
                                                });
                                              },
                                      icon: Icon(
                                        isShareable
                                            ? Icons.share
                                            : Icons.share_outlined,
                                        color:
                                            isShareable
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline,
                                      ),
                                      tooltip: 'Make shareable',
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Shareable Dream',
                                                ),
                                                content: Consumer<AuthProvider>(
                                                  builder: (
                                                    context,
                                                    authProvider,
                                                    _,
                                                  ) {
                                                    String content =
                                                        'Allow sharing this dream through QR code with others.';
                                                    return Text(content);
                                                  },
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('Got it'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: theme.colorScheme.outline,
                                      ),
                                      tooltip: 'More info',
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
