import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../services/avatar_service.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showEditButton;
  final VoidCallback? onTap;

  const UserAvatar({
    Key? key,
    required this.user,
    this.radius = 30,
    this.showEditButton = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: _getBackgroundColor(context),
            child: _buildAvatarContent(context),
          ),
          if (showEditButton)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: radius * 0.6,
                height: radius * 0.6,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: radius * 0.3,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (user.backgroundColor != null) {
      return Color(user.backgroundColor!);
    }
    return Theme.of(context).primaryColor;
  }

  Widget _buildAvatarContent(BuildContext context) {
    switch (user.avatarType) {
      case AvatarType.emoji:
        if (user.avatarData != null) {
          return Text(
            user.avatarData!,
            style: TextStyle(fontSize: radius * 0.8),
          );
        }
        break;

      case AvatarType.generated:
        if (user.avatarData != null) {
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.avatarData!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AvatarService.getContrastColor(
                        _getBackgroundColor(context),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => _buildInitialsAvatar(context),
            ),
          );
        }
        return _buildInitialsAvatar(context);

      case AvatarType.uploaded:
        if (user.photoURL != null) {
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.photoURL!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AvatarService.getContrastColor(
                        _getBackgroundColor(context),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => _buildInitialsAvatar(context),
            ),
          );
        }
        break;

      case AvatarType.initials:
        return _buildInitialsAvatar(context);
    }

    // Fallback to initials
    return _buildInitialsAvatar(context);
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initials = AvatarService.getInitials(user.displayName);
    final backgroundColor = _getBackgroundColor(context);
    final textColor = AvatarService.getContrastColor(backgroundColor);

    return Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.6,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}
