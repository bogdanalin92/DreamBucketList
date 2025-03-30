import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarImagePath;
  final String? backgroundImagePath;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onSolidButtonPressed;
  final String buttonText;
  final String solidButtonText;

  const ProfileCard({
    Key? key,
    this.name = "Cameron Williamson",
    this.subtitle = "Web Development",
    this.avatarImagePath,
    this.backgroundImagePath,
    this.onButtonPressed,
    this.onSolidButtonPressed,
    this.buttonText = "Button",
    this.solidButtonText = "Button",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 384,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Card image (background)
          Container(
            height: 192,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              image:
                  backgroundImagePath != null
                      ? DecorationImage(
                        image: AssetImage(backgroundImagePath ?? ""),
                        fit: BoxFit.cover,
                      )
                      : null,
              gradient:
                  backgroundImagePath == null
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.red.shade300],
                      )
                      : null,
            ),
          ),

          const SizedBox(height: 60), // Space for avatar that overlaps
          // Title
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 15),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Outline Button
              OutlinedButton(
                onPressed: onButtonPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  backgroundColor: Colors.black,
                  minimumSize: const Size(76, 31),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(buttonText.toUpperCase()),
              ),

              const SizedBox(width: 10),

              // Solid Button
              ElevatedButton(
                onPressed: onSolidButtonPressed,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  minimumSize: const Size(76, 31),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(solidButtonText.toUpperCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget that displays the avatar positioned over the card
class ProfileCardWithAvatar extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget? avatar;
  final String? avatarImageUrl; // Add support for image URL
  final String? backgroundImagePath;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onSolidButtonPressed;
  final String buttonText;
  final String solidButtonText;

  const ProfileCardWithAvatar({
    Key? key,
    this.name = "Cameron Williamson",
    this.subtitle = "Web Development",
    this.avatar,
    this.avatarImageUrl,
    this.backgroundImagePath,
    this.onButtonPressed,
    this.onSolidButtonPressed,
    this.buttonText = "Button",
    this.solidButtonText = "Button",
  }) : assert(
         avatar != null || avatarImageUrl != null,
         'Either avatar or avatarImageUrl must be provided',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base card
        ProfileCard(
          name: name,
          subtitle: subtitle,
          backgroundImagePath: backgroundImagePath,
          onButtonPressed: onButtonPressed,
          onSolidButtonPressed: onSolidButtonPressed,
          buttonText: buttonText,
          solidButtonText: solidButtonText,
        ),

        // Avatar positioned to overlap between image and content
        Positioned(
          top: 135, // Positioned to overlap the top half
          child: Container(
            width: 114,
            height: 114,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: ClipOval(
              child:
                  avatarImageUrl != null
                      ? Image.network(
                        avatarImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.red[400],
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                      : avatar!,
            ),
          ),
        ),
      ],
    );
  }
}

/// Example usage of the profile card with image URL
class ProfileCardExample extends StatelessWidget {
  const ProfileCardExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: ProfileCardWithAvatar(
          name: "Cameron Williamson",
          subtitle: "Web Development",
          // Example with avatar widget
          avatar: Container(
            color: Colors.redAccent,
            child: const Center(
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          // Example with avatar image URL (uncomment to use)
          // avatarImageUrl: 'https://example.com/avatar.jpg',
          onButtonPressed: () {
            print("Button pressed!");
          },
          onSolidButtonPressed: () {
            print("Solid button pressed!");
          },
        ),
      ),
    );
  }
}
