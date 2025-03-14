import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConsentManager(context),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Data Storage & Caching',
              icon: Icons.storage_outlined,
              content:
                  'Your data is cached locally on your device using secure storage mechanisms. This allows you to access your items even when offline. Changes made while offline will automatically sync to the cloud when you reconnect.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Cloud Synchronization',
              icon: Icons.sync_outlined,
              content:
                  'When you\'re signed in with an account, your data is securely synchronized with Firebase services. This enables seamless access across all your devices. Only items marked as shareable are stored in the cloud. Non-shareable items remain exclusively on your device.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Anonymous Usage',
              icon: Icons.person_outline,
              content:
                  'If you use the app anonymously, your data is stored only on your current device and is not synchronized across devices. You can sign in anytime to enable synchronization without losing your existing data.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Data Security',
              icon: Icons.security_outlined,
              content:
                  'We employ industry-standard encryption and security practices to protect your data both on-device and in the cloud. Your personal information is never shared with third parties without your explicit consent.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Shared Items',
              icon: Icons.share_outlined,
              content:
                  'Items you mark as shareable can be viewed by other users if you explicitly share them. You maintain control over your shared items and can make them private at any time.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentManager(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAnonymous) {
          return const SizedBox.shrink();
        }

        final userModel = authProvider.userModel;
        final privacyConsent =
            userModel?.privacyConsent ?? const PrivacyConsent();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Preferences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Analytics Collection'),
                  subtitle: const Text(
                    'Allow collection of anonymous usage data to improve app functionality',
                  ),
                  value: privacyConsent.analyticsConsent,
                  onChanged:
                      (value) =>
                          _updateConsent(context, analyticsConsent: value),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Third-Party Data Sharing'),
                  subtitle: const Text(
                    'Allow sharing of non-personal data with trusted partners',
                  ),
                  value: privacyConsent.thirdPartyShareConsent,
                  onChanged:
                      (value) => _updateConsent(
                        context,
                        thirdPartyShareConsent: value,
                      ),
                ),
                if (privacyConsent.lastUpdated != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Last updated: ${_formatDate(privacyConsent.lastUpdated!)}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateConsent(
    BuildContext context, {
    bool? analyticsConsent,
    bool? thirdPartyShareConsent,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentConsent =
        authProvider.userModel?.privacyConsent ?? const PrivacyConsent();

    final newConsent = currentConsent.copyWith(
      analyticsConsent: analyticsConsent,
      thirdPartyShareConsent: thirdPartyShareConsent,
      lastUpdated: DateTime.now(),
    );

    try {
      await authProvider.updatePrivacyConsent(newConsent);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy preferences updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update privacy preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
