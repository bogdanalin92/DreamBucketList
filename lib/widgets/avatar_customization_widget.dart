import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/avatar_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/pattern_avatar.dart';

class AvatarCustomizationWidget extends StatefulWidget {
  final UserModel user;
  final Function() onAvatarChanged;

  const AvatarCustomizationWidget({
    Key? key,
    required this.user,
    required this.onAvatarChanged,
  }) : super(key: key);

  @override
  State<AvatarCustomizationWidget> createState() =>
      _AvatarCustomizationWidgetState();
}

class _AvatarCustomizationWidgetState extends State<AvatarCustomizationWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.userModel ?? widget.user;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Current avatar display - uses current user data from provider
            UserAvatar(user: currentUser, radius: 60),
            const SizedBox(height: 24),

            // Customization options
            Text(
              'Choose Your Avatar Style',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Option buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildOptionButton(
                  context,
                  icon: Icons.face,
                  label: 'Emoji',
                  onTap: () => _showEmojiPicker(context),
                ),
                _buildOptionButton(
                  context,
                  icon: Icons.auto_awesome,
                  label: 'Generated',
                  onTap: () => _showGeneratedAvatars(context),
                ),
                _buildOptionButton(
                  context,
                  icon: Icons.text_fields,
                  label: 'Initials',
                  onTap: () => _showInitialsCustomizer(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => EmojiAvatarPicker(
            onEmojiSelected: (emoji, backgroundColor) async {
              try {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                await userProvider.updateAvatar(
                  avatarData: emoji,
                  avatarType: AvatarType.emoji,
                  backgroundColor: backgroundColor.toARGB32(),
                );
                widget.onAvatarChanged();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating avatar: $e')),
                );
              }
            },
          ),
    );
  }

  void _showGeneratedAvatars(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => GeneratedAvatarPicker(
            onAvatarSelected: (pattern, colors) async {
              try {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );

                // Create pattern data
                final patternData = {
                  'pattern': pattern,
                  'colors': colors.map((c) => c.toARGB32()).toList(),
                  'seed': widget.user.uid,
                };

                await userProvider.updateAvatar(
                  avatarData: jsonEncode(patternData),
                  avatarType: AvatarType.generated,
                  // For generated avatars, color data is encoded in the pattern itself, so no separate background color is needed.
                  backgroundColor: null,
                );
                widget.onAvatarChanged();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating avatar: $e')),
                );
              }
            },
          ),
    );
  }

  void _showInitialsCustomizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => InitialsCustomizer(
            user: widget.user,
            onColorSelected: (backgroundColor) async {
              try {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                await userProvider.updateAvatar(
                  avatarData: null,
                  avatarType: AvatarType.initials,
                  backgroundColor: backgroundColor.toARGB32(),
                );
                widget.onAvatarChanged();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating avatar: $e')),
                );
              }
            },
          ),
    );
  }
}

class EmojiAvatarPicker extends StatelessWidget {
  final Function(String emoji, Color backgroundColor) onEmojiSelected;

  const EmojiAvatarPicker({Key? key, required this.onEmojiSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Choose an Emoji Avatar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Random selection button
          ElevatedButton.icon(
            onPressed: () {
              final randomEmoji = AvatarService.getRandomEmoji();
              final randomColor = AvatarService.getRandomColor();
              onEmojiSelected(randomEmoji, randomColor);
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Surprise Me!'),
          ),
          const SizedBox(height: 16),

          // Emoji grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: AvatarService.avatarEmojis.length,
              itemBuilder: (context, index) {
                final emoji = AvatarService.avatarEmojis[index];
                return GestureDetector(
                  onTap: () => _selectEmojiWithColor(context, emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectEmojiWithColor(BuildContext context, String emoji) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Choose Background Color'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AvatarService.avatarColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        onEmojiSelected(emoji, color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}

class GeneratedAvatarPicker extends StatefulWidget {
  final Function(String pattern, List<Color> colors) onAvatarSelected;

  const GeneratedAvatarPicker({Key? key, required this.onAvatarSelected})
    : super(key: key);

  @override
  State<GeneratedAvatarPicker> createState() => _GeneratedAvatarPickerState();
}

class _GeneratedAvatarPickerState extends State<GeneratedAvatarPicker> {
  String? selectedPattern;
  List<Color> selectedColors = [];

  @override
  Widget build(BuildContext context) {
    final userSeed = AvatarService.getUserSeed();

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            selectedPattern == null
                ? 'Choose Avatar Style'
                : 'Customize Colors',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (selectedPattern == null) ...[
            // Random selection button
            ElevatedButton.icon(
              onPressed: () {
                final randomStyle =
                    AvatarService.generatedAvatarStyles[Random().nextInt(
                      AvatarService.generatedAvatarStyles.length,
                    )];
                final patternData = AvatarService.generateAvatarPattern(
                  randomStyle['style']!,
                  '$userSeed-${DateTime.now().millisecondsSinceEpoch}',
                );
                widget.onAvatarSelected(
                  patternData['pattern'] as String,
                  (patternData['colors'] as List<int>)
                      .map((c) => Color(c))
                      .toList(),
                );
              },
              icon: const Icon(Icons.shuffle),
              label: const Text('Surprise Me!'),
            ),
            const SizedBox(height: 16),

            // Avatar styles grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AvatarService.generatedAvatarStyles.length,
                itemBuilder: (context, index) {
                  final style = AvatarService.generatedAvatarStyles[index];
                  final patternData = AvatarService.generateAvatarPattern(
                    style['style']!,
                    userSeed,
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPattern = style['style']!;
                        selectedColors =
                            (patternData['colors'] as List<int>)
                                .map((c) => Color(c))
                                .toList();
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipOval(
                            child: PatternAvatar(
                              patternData: patternData,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          style['name']!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // Color customization section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Preview of selected pattern
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: ClipOval(
                      child: PatternAvatar(
                        patternData: {
                          'pattern': selectedPattern!,
                          'colors':
                              selectedColors.map((c) => c.toARGB32()).toList(),
                          'seed': userSeed,
                        },
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap colors to customize:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap any color circle below to change it',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Color selection grid
            Expanded(
              child: Column(
                children: [
                  // Current colors display
                  Wrap(
                    spacing: 8,
                    children:
                        selectedColors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final color = entry.value;
                          return GestureDetector(
                            onTap: () => _showColorPicker(context, index),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AvatarService.getContrastColor(color),
                                size: 20,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Regenerate colors button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedColors =
                            AvatarService.regenerateColorsForPattern(
                              selectedPattern!,
                            );
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate Colors'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedPattern = null;
                              selectedColors = [];
                            });
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onAvatarSelected(
                              selectedPattern!,
                              selectedColors,
                            );
                          },
                          child: const Text('Use Avatar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, int colorIndex) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Choose Color ${colorIndex + 1}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: AvatarService.avatarColors.length,
                itemBuilder: (context, index) {
                  final color = AvatarService.avatarColors[index];
                  final isSelected = selectedColors[colorIndex] == color;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColors[colorIndex] = color;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: AvatarService.getContrastColor(color),
                                size: 20,
                              )
                              : null,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}

class InitialsCustomizer extends StatelessWidget {
  final UserModel user;
  final Function(Color backgroundColor) onColorSelected;

  const InitialsCustomizer({
    Key? key,
    required this.user,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initials = AvatarService.getInitials(user.displayName);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Choose Background Color',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Random selection button
          ElevatedButton.icon(
            onPressed: () {
              final randomColor = AvatarService.getRandomColor();
              onColorSelected(randomColor);
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Random Color'),
          ),
          const SizedBox(height: 16),

          // Color options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children:
                AvatarService.avatarColors.map((color) {
                  return GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AvatarService.getContrastColor(color),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
