import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/presentation/screens/donation_page.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  final ThemeService _themeService = GetIt.I<ThemeService>();
  // final LanguageService _languageService = GetIt.I<LanguageService>();
  String _username = 'Tamu';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh user data when app resumes
      _refreshUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _username = user.username;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memuat data pengguna: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshUserData() async {
    try {
      await _authRepository.refreshUser();
      await _loadUserData();
      if (mounted) {
        debugPrint('User data refreshed from database');
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  Future<void> _handleLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Data Anda akan tetap tersimpan dengan aman.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Keluar'),
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
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showSnackBar('Tidak dapat membuka tautan');
      }
    }
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
                    title: 'Upgrade Premium',
                    subtitle: 'Hapus iklan & buka semua fitur',
                    onTap: () {
                      context.push('/upgrade');
                    },
                  ),
                  _buildMenuItem(
                    icon: '☕',
                    title: 'Dukung Kami',
                    subtitle: 'Bantu kami tetap berkembang',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DonationPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: '❤️',
                    title: 'Suka dengan aplikasi ini?',
                    subtitle: 'Beri kami ⭐⭐⭐⭐⭐ di Google Play',
                    onTap: () => _launchUrl(
                      'https://play.google.com/store/apps/details?id=com.belanjapintar.app',
                    ),
                  ),
                  _buildMenuItem(
                    icon: '💬',
                    title: 'Bantuan & Masukan',
                    onTap: () => _launchUrl(
                      'mailto:belanjapintarkami@gmail.com?subject=App Feedback&body=Hello Belanja Pintar Team,',
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
                          'https://sites.google.com/view/belanjapintar-privacy-policy/halaman-muka',
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
                          'https://sites.google.com/view/belanjapintar-terms/halaman-muka',
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
                    'App Version 1.0.0',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
