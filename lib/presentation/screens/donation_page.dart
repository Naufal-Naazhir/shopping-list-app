import 'dart:ui'; // For BackdropFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final String saweriaUsername = 'pembuataplikasi'; // Keep this

  @override
  void initState() {
    super.initState();
    // No Appwrite database/realtime initialization needed here for premium status
  }

  Future<void> _launchSaweria() async {
    // Email copying logic removed
    // SnackBar for email copying removed
    
    final Uri url = Uri.parse('https://saweria.co/$saweriaUsername');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka URL: $url')));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This page is now purely for donations, so no premium checks needed.
    return _buildDonationView();
  }

  Widget _buildDonationView() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // No premium status to refresh, just a placeholder for a pull-to-refresh
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1a2a3a), Color(0xFF2a4a6a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Ensures scroll is always possible for RefreshIndicator
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.favorite, // Changed icon for donation
                      size: 60,
                      color: Colors.redAccent, // Changed color for donation
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Dukung Aplikasi Ini",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Bantu kami terus mengembangkan aplikasi ini dengan donasi Anda.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureCard(),
                    const SizedBox(height: 24),
                    _buildInstructionCard(),
                    const SizedBox(height: 32),
                    _buildPaymentButton(),
                  ],
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: 40,
              left: 16,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Setiap dukungan Anda sangat berarti!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Donasi Anda membantu kami dalam biaya operasional, pengembangan fitur baru, dan menjaga aplikasi ini tetap gratis serta bebas iklan untuk semua pengguna.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Jumlah donasi sepenuhnya sukarela. Terima kasih atas kemurahan hati Anda!",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Instruksi Donasi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "1. Klik tombol \"Dukung Sekarang\" di bawah.",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            "2. Anda akan diarahkan ke halaman Saweria.",
            style: TextStyle(color: Colors.white70),
          ),
           SizedBox(height: 8),
          Text(
            "3. Masukkan jumlah donasi dan selesaikan pembayaran.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.orangeAccent.withOpacity(0.5),
      ),
      onPressed: _launchSaweria,
      icon: const Icon(Icons.favorite, size: 24), // Changed icon
      label: const Text(
        "Dukung Sekarang",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
