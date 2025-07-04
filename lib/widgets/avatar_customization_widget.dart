import 'dart:convert';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Current avatar display
        UserAvatar(user: widget.user, radius: 60),
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
                  backgroundColor: backgroundColor.value,
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
                  'colors': colors.map((c) => c.value).toList(),
                  'seed': widget.user.uid,
                };

                await userProvider.updateAvatar(
                  avatarData: jsonEncode(patternData),
                  avatarType: AvatarType.generated,
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
                  backgroundColor: backgroundColor.value,
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

class GeneratedAvatarPicker extends StatelessWidget {
  final Function(String pattern, List<Color> colors) onAvatarSelected;

  const GeneratedAvatarPicker({Key? key, required this.onAvatarSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userSeed = AvatarService.getUserSeed();

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
            'Choose Generated Avatar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

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
              onAvatarSelected(
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
                  onTap:
                      () => onAvatarSelected(
                        patternData['pattern'] as String,
                        (patternData['colors'] as List<int>)
                            .map((c) => Color(c))
                            .toList(),
                      ),
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
