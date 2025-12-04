import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // New import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  final ThemeService _themeService = GetIt.I<ThemeService>();
  // final LanguageService _languageService = GetIt.I<LanguageService>();
  String _username = 'Tamu';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      setState(() {
        _username = user.username;
      });
    }
  }

  Future<void> _handleLogout() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text('Sampai Jumpa!', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Data Anda akan tetap tersimpan.',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await _authRepository.logout();
                Navigator.of(dialogContext).pop();
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      _showSnackBar('Tidak dapat membuka $urlString');
    }
  }

  Future<void> _showPremiumInfoDialog() async {
    final isPremium = await _authRepository.isCurrentUserPremium();
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text('Hapus Iklan', style: TextStyle(color: Colors.white)),
          content: isPremium
              ? const Text(
                  'Anda sudah pengguna premium! Nikmati pengalaman bebas iklan.',
                  style: TextStyle(color: Colors.white),
                )
              : const Text(
                  'Upgrade ke Premium untuk menghapus iklan dan membuka fitur eksklusif!',
                  style: TextStyle(color: Colors.white),
                ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            if (!isPremium)
              TextButton(
                child: const Text('Upgrade Sekarang',
                    style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  final user = await _authRepository.getCurrentUser();
                  Navigator.of(dialogContext).pop(); // Close the dialog first
                  if (user != null) {
                    context.push(
                      '/upgrade',
                      extra: {'userEmail': user.email, 'userId': user.uid},
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tidak dapat mengambil data pengguna. Silakan coba lagi.',
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showThemeDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Tema'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<ThemeMode>(
                    title: const Text('Standar Sistem'),
                    value: ThemeMode.system,
                    groupValue: _themeService.themeMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        _themeService.setThemeMode(value);
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Tema Terang'),
                    value: ThemeMode.light,
                    groupValue: _themeService.themeMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        _themeService.setThemeMode(value);
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Tema Gelap'),
                    value: ThemeMode.dark,
                    groupValue: _themeService.themeMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        _themeService.setThemeMode(value);
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Greeting
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Halo! 👋',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selamat datang, $_username!',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                ],
              ),
            ),

            // Logout Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE53935), // Red color
                        Color(0xFFC62828), // Darker red
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KELUAR →',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // White text for better contrast
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keluar dari akun Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(
                                0.9,
                              ), // Slightly transparent white for the subtitle
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: '⚙️',
                    title: 'Pengaturan',
                    onTap: () => context.push('/settings'),
                  ),
                  _buildMenuItem(
                    icon: '🎨',
                    title: 'Tampilan',
                    onTap: _showThemeDialog,
                  ),
                  _buildMenuItem(
                    icon: '💎',
                    title: 'Hapus Iklan',
                    onTap: _showPremiumInfoDialog,
                  ),
                  _buildMenuItem(
                    icon: '❤️',
                    title: 'Suka dengan aplikasi ini?',
                    subtitle: 'Beri kami ⭐⭐⭐⭐⭐ di Google Play',
                    onTap: () => _launchUrl(
                      'https://play.google.com/store/apps/details?id=com.example.belanja_praktis',
                    ),
                  ),
                  _buildMenuItem(
                    icon: '💬',
                    title: 'Bantuan & Masukan',
                    onTap: () => _launchUrl(
                      'mailto:support@belanjapraktis.com?subject=App Feedback&body=Hello Belanja Praktis Team,',
                    ),
                  ),
                  // _buildMenuItem(
                  //   icon: '🌐',
                  //   title: 'Ganti Bahasa',
                  //   subtitle: _languageService.currentLanguage,
                  //   onTap: () {
                  //     _languageService.toggleLanguage();
                  //     _showSnackBar(
                  //       'Bahasa diubah ke ${_languageService.currentLanguage}',
                  //     );
                  //   },
                  // ),
                  const SizedBox(
                    height: 20,
                  ), // Add some space before the footer
                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _launchUrl(
                          'https://www.example.com/privacy',
                        ), // Placeholder URL
                        child: const Text(
                          'KEBIJAKAN PRIVASI',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Color(0xFFDDDDDD)),
                      ),
                      TextButton(
                        onPressed: () => _launchUrl(
                          'https://www.example.com/terms',
                        ), // Placeholder URL
                        child: const Text(
                          'SYARAT LAYANAN',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Versi 0.1.0 Beta',
                    style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                  ),
                  const SizedBox(height: 20), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ), // Adjusted font size
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF999999),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
