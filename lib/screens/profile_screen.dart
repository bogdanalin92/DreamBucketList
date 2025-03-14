import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'login_screen.dart';
import 'privacy_security_screen.dart';
import '../services/preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _optionsExpanded = false;
  bool _photoConsent = false;
  late PreferencesService _preferencesService;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _preferencesService = await PreferencesService.getInstance();
    setState(() {
      _photoConsent = _preferencesService.getPhotoConsent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile'), elevation: 0),
          body:
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (authProvider.isAuthenticated)
                          _buildUserInfoCard(authProvider),
                        const SizedBox(height: 24),
                        _buildSettingsCard(),
                        const SizedBox(height: 24),
                        if (authProvider.isAuthenticated &&
                            !authProvider.isAnonymous)
                          _buildSignOutButton(context)
                        else
                          _buildSignInButton(context),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor:
            isDark
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.error,
        foregroundColor:
            isDark
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface,
        elevation: isDark ? 8 : 4,
      ),
      onPressed: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
      },
      child: const Text('Sign Out'),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: isDark ? Theme.of(context).colorScheme.primary : null,
        foregroundColor: isDark ? Colors.white : null,
        elevation: isDark ? 8 : 4,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: const Text('Sign In'),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDarkModeToggle(),
            const SizedBox(height: 8),
            _buildOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: themeProvider.isDarkMode,
      onChanged: (value) {
        themeProvider.toggleTheme();
      },
      secondary: Icon(
        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: const Text('Privacy & Security'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacySecurityScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Photo Cloud Storage'),
          subtitle: const Text(
            'Photos are stored on Imgur\'s servers',
            style: TextStyle(fontSize: 12),
          ),
          trailing: Switch(
            value: _getPhotoConsent(),
            onChanged: _updatePhotoConsent,
          ),
        ),
        if (!_getPhotoConsent())
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Photo upload is disabled. Enable to allow storing photos on Imgur\'s servers when adding images to your bucket list items.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  bool _getPhotoConsent() {
    return _photoConsent;
  }

  void _updatePhotoConsent(bool value) async {
    if (value) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Photo Cloud Storage Consent'),
              content: const Text(
                'By enabling photo storage, you agree that any photos you upload will be stored on Imgur\'s servers. This allows us to efficiently store and display images in your bucket list items. Your photos will be publicly accessible via their direct URLs, but will not be searchable or linked to your identity.\n\nYou can disable this feature at any time, but previously uploaded photos will remain on Imgur\'s servers.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _preferencesService.setPhotoConsent(true);
                    setState(() {
                      _photoConsent = true;
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('I Agree'),
                ),
              ],
            ),
      );
    } else {
      await _preferencesService.setPhotoConsent(false);
      setState(() {
        _photoConsent = false;
      });
    }
  }

  Widget _buildUserInfoCard(AuthProvider authProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 30,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.isAnonymous
                            ? 'Anonymous User'
                            : (authProvider
                                        .currentUser
                                        ?.displayName
                                        ?.isNotEmpty ==
                                    true
                                ? authProvider.currentUser!.displayName!
                                : (authProvider.userEmail.isNotEmpty
                                    ? authProvider.userEmail
                                    : 'Email not available')),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${authProvider.userId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.isAnonymous
                  ? 'You are currently signed in anonymously. Your data is stored anonymously and not synchronized between devices.'
                  : 'You are signed in with your email address. Your data is synchronized across your devices.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
