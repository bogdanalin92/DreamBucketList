import 'package:bucketlist/providers/auth_provider.dart';
import 'package:bucketlist/widgets/cached_icon.dart';
import 'package:bucketlist/widgets/medium_rectangle_ad_widget.dart';
import 'package:bucketlist/widgets/optimized_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/bucket_list_item.dart';
import 'viewmodels/bucket_list_view_model.dart';
import 'mainScreen.dart';
import 'utils/image_picker_helper.dart';
import 'widgets/universal_image.dart';
import 'services/local_image_service.dart';
import 'constants/tag_constants.dart'; // Import tag constants

class AddBucketListScreen extends StatefulWidget {
  const AddBucketListScreen({super.key});

  @override
  State<AddBucketListScreen> createState() => _AddBucketListScreenState();
}

class _AddBucketListScreenState extends State<AddBucketListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isComplete = false;
  bool _isShareable = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  final LocalImageService _localImageService = LocalImageService();

  // List to store selected tags
  final List<String> _selectedTags = [];
  final List<String> _tagIds = TagConstants.allTagIds;

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _itemController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    _descriptionController.clear();
    setState(() {
      _isComplete = false;
      _isShareable = false;
      _isSubmitting = false;
      _selectedTags.clear(); // Clear selected tags
    });
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

  // Widget to build tag selector chips
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
              _tagIds.map((tagId) {
                final isSelected = _selectedTags.contains(tagId);

                return OptimizedFilterChip(
                  key: ValueKey(tagId),
                  tagId: tagId,
                  isSelected: isSelected,
                  onSelected: (_) => _toggleTag(tagId),
                  textColor: Theme.of(context).colorScheme.onSurface,
                );
              }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage() async {
    // Set uploading state to prevent multiple simultaneous uploads
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imagePath = await ImagePickerHelper.pickAndUploadImage(context);
      if (imagePath != null) {
        setState(() {
          _imageUrlController.text = imagePath;
        });
      }
    } finally {
      // Reset uploading state
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // Handle toggling shareability state and image storage management
  Future<void> _handleShareableToggle(bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isAnonymous = authProvider.isAnonymous;
    final LocalImageService localImageService = LocalImageService();

    // Only need special handling for anonymous users with images
    if (isAnonymous && _imageUrlController.text.isNotEmpty) {
      // Case 1: Making the item shareable and has a local image - need to upload to Imgur
      if (value && localImageService.isLocalPath(_imageUrlController.text)) {
        setState(() {
          _isShareable = value;
          _isUploadingImage = true;
        });

        try {
          // Show upload progress
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading image for sharing...')),
          );

          // Upload the local image to Imgur
          final String networkUrl = await localImageService
              .convertLocalToNetworkImage(_imageUrlController.text);

          // Update the image URL
          setState(() {
            _imageUrlController.text = networkUrl;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error uploading image for sharing: ${e.toString()}',
                ),
                backgroundColor: Colors.red,
              ),
            );
            // Revert the state if uploading fails
            setState(() {
              _isShareable = !value;
            });
          }
        } finally {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
      // Case 2: Making the item non-shareable and has a network image - convert to local
      else if (!value &&
          !localImageService.isLocalPath(_imageUrlController.text)) {
        setState(() {
          _isShareable = value;
          _isUploadingImage = true;
        });

        try {
          // Show download progress
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Converting to local storage...')),
          );

          final String networkUrl = _imageUrlController.text;

          // Download the image and store it locally
          final String localPath = await localImageService
              .convertNetworkToLocalImage(networkUrl);

          // Delete the network image from Imgur
          await localImageService.deleteNetworkImage(networkUrl);

          // Update the image URL to local path
          setState(() {
            _imageUrlController.text = localPath;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error converting to local storage: ${e.toString()}',
                ),
                backgroundColor: Colors.red,
              ),
            );
            // Revert the state if conversion fails
            setState(() {
              _isShareable = !value;
            });
          }
        } finally {
          setState(() {
            _isUploadingImage = false;
          });
        }
      } else {
        // Simple case: No image conversion needed
        setState(() {
          _isShareable = value;
        });
      }
    } else {
      // Non-anonymous users or no image - just update the state
      setState(() {
        _isShareable = value;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      // Hide keyboard
      FocusScope.of(context).unfocus();

      try {
        // Get the userId - we know it will exist since we always have at least anonymous auth
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.userId;
        final bool isAnonymous = authProvider.isAnonymous;

        String? imagePath =
            _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim();

        // If the item is shareable and has a local image, we need to upload it to Imgur
        if (_isShareable &&
            imagePath != null &&
            isAnonymous &&
            _localImageService.isLocalPath(imagePath)) {
          // Show upload progress
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploading image for sharing...')),
            );
          }

          // Upload the local image to Imgur
          imagePath = await _localImageService.convertLocalToNetworkImage(
            imagePath,
          );
        }

        final item = BucketListItem(
          userId: userId,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          item: _itemController.text.trim(),
          price: double.tryParse(_priceController.text),
          image: imagePath,
          details:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          complete: _isComplete,
          shareable: _isShareable,
          tags: List<String>.from(
            _selectedTags,
          ), // Ensure we create a new list from _selectedTags
        );

        // Show immediate feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding dream...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Reset form and navigate immediately
        _resetForm();
        if (context.mounted) {
          final mainScreenState =
              context.findAncestorStateOfType<MainscreenState>();
          if (mainScreenState != null) {
            mainScreenState.setState(
              () => mainScreenState.currentIndex = 0,
            ); // Switch to Dreams tab
          }
        }

        // Add item in the background
        if (context.mounted) {
          await context.read<BucketListViewModel>().addBucketListItem(item);
        }
      } catch (e) {
        // If there's an error, show it to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding dream: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Dream',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: 'Dream Title',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.star_outline,
                          color: theme.colorScheme.primary,
                        ),
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                      ),
                      style: TextStyle(color: theme.colorScheme.onBackground),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your dream';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Estimated Price (optional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: theme.colorScheme.primary,
                        ),
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                      ),
                      style: TextStyle(color: theme.colorScheme.onBackground),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Add tag selector
                    _buildTagSelector(),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: 'Image (optional)',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.image_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              labelStyle: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.onBackground,
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ElevatedButton(
                            onPressed:
                                _isUploadingImage ? null : _pickAndUploadImage,
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
                    if (_imageUrlController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: UniversalImage(
                          imagePath: _imageUrlController.text,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.description_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        alignLabelWithHint: true,
                      ),
                      style: TextStyle(color: theme.colorScheme.onBackground),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Already Completed?',
                        style: TextStyle(color: theme.colorScheme.onBackground),
                      ),
                      subtitle: Text(
                        'Mark if you\'ve already achieved this dream',
                        style: TextStyle(
                          color: Color.alphaBlend(
                            Colors.grey.withOpacity(0.3),
                            theme.colorScheme.onBackground,
                          ),
                        ),
                      ),
                      value: _isComplete,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (bool value) {
                        setState(() {
                          _isComplete = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Shareable',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      subtitle: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          String subtitle =
                              'Allow sharing this dream through QR code';
                          if (authProvider.isAnonymous &&
                              _imageUrlController.text.isNotEmpty) {
                            if (_isShareable &&
                                _localImageService.isLocalPath(
                                  _imageUrlController.text,
                                )) {
                              subtitle +=
                                  '\nNote: Local image will be uploaded to Imgur when shared';
                            } else if (!_isShareable &&
                                !_localImageService.isLocalPath(
                                  _imageUrlController.text,
                                )) {
                              subtitle +=
                                  '\nNote: Network image will be saved locally and removed from Imgur';
                            }
                          }
                          return Text(
                            subtitle,
                            style: TextStyle(
                              color: Color.alphaBlend(
                                Colors.grey.withOpacity(0.3),
                                theme.colorScheme.onBackground,
                              ),
                            ),
                          );
                        },
                      ),
                      value: _isShareable,
                      activeColor: theme.colorScheme.primary,
                      onChanged:
                          _isUploadingImage ? null : _handleShareableToggle,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Add to Bucket List',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),

                    // Add native ad at bottom of form
                    const SizedBox(height: 32),
                    const MediumRectangleAdWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
