import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) {
        _showSnackBar(context, 'Tidak dapat membuka tautan');
      }
    } catch (_) {
      _showSnackBar(context, 'Tidak dapat membuka tautan');
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'belanjapintarkami@gmail.com',
      queryParameters: <String, String>{
        'subject': 'App Feedback',
        'body': 'Halo Tim Belanja Praktis,',
      },
    );

    await _launchUrl(context, emailUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Go back to previous screen
        ),
        title: const Text('Pengaturan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings List
              _buildSettingsItem(
                context,
                title: 'Remove Ads',
                onTap: () {
                  // TODO: Implement Remove Ads functionality
                  context.push('/upgrade');
                },
              ),
              _buildSettingsItem(
                context,
                title: 'Rate Us on Play Store',
                onTap: () {
                  // TODO: Implement Rate Us functionality
                  _launchUrl(
                    context,
                    'https://play.google.com/store/apps/details?id=com.belanjapintar.app',
                  );
                },
              ),
              _buildSettingsItem(
                context,
                title: 'Send Feedback',
                onTap: () {
                  // TODO: Implement Send Feedback functionality
                  _launchEmail(context);
                },
              ),
              _buildSettingsItem(
                context,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Implement Privacy Policy functionality
                  _launchUrl(context, 'https://sites.google.com/view/belanjapintar-privacy-policy/halaman-muka');
                },
              ),
              _buildSettingsItem(
                context,
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Implement Terms of Service functionality
                  _launchUrl(context, 'https://sites.google.com/view/belanjapintar-terms/halaman-muka');
                },
              ),
              const SizedBox(height: 40),
              // App Version
              const Center(
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF888888),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
