import 'dart:ui'; // For BackdropFilter

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/premium_success_dialog.dart';

class PaymentPage extends StatefulWidget {
  final String userEmail;
  final String userId;
  final Client client;

  const PaymentPage({
    super.key, // Use super-parameters
    required this.userEmail,
    required this.userId,
    required this.client,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Database configuration from environment variables
  late final String databaseId;
  late final String collectionId;
  final String saweriaUsername = 'pembuataplikasi';

  late Databases databases;
  late Realtime realtime;
  RealtimeSubscription? subscription;

  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize database configuration
    databaseId = dotenv.get('APPWRITE_DATABASE_ID');
    collectionId = dotenv.get('APPWRITE_USERS_COLLECTION_ID');

    databases = Databases(widget.client);
    realtime = Realtime(widget.client);
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _checkInitialPremiumStatus();
    if (mounted && !_isPremium) {
      _subscribeToUserChanges();
    }
  }

  Future<void> _checkInitialPremiumStatus() async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: widget.userId,
      );
      if (document.data['isPremium'] == true) {
        if (mounted) {
          setState(() => _isPremium = true);
        }
      }
    } catch (e) {
      print("--- [Initial Check] Error checking initial status: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToUserChanges() {
    final channel =
        'databases.$databaseId.collections.$collectionId.documents.${widget.userId}';
    try {
      subscription = realtime.subscribe([channel]);
      subscription!.stream.listen(
        (response) {
          if (response.payload.isNotEmpty &&
              response.payload['isPremium'] == true) {
            if (mounted) {
              showSuccessDialog();
              subscription?.close();
            }
          }
        },
        onError: (e, _) {
          // You might want to log this error to a crashlytics service in production
        },
      );
    } on AppwriteException catch (e, _) {
      // You might want to log this error to a crashlytics service in production
    }
  }

  Future<void> _launchSaweria() async {
    await Clipboard.setData(ClipboardData(text: widget.userEmail));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Email berhasil disalin! Tempel di kolom Pesan Saweria nanti.',
          ),
        ),
      );
    }

    final Uri url = Uri.parse('https://saweria.co/$saweriaUsername');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka URL: $url')));
      }
    }
  }

  void showSuccessDialog() {
    // If a subscription exists, close it, as we no longer need it.
    subscription?.close();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => const PremiumSuccessDialog(),
    ).then((_) {
      // After the dialog is closed by the user, pop the PaymentPage to go back.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // If we can't pop, at least rebuild the UI to the premium view.
        setState(() {
          _isPremium = true;
        });
      }
    });
  }

  @override
  void dispose() {
    subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isPremium ? _buildPremiumView() : _buildUpgradeView();
  }

  Widget _buildPremiumView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Status Premium"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1a2a3a),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: Colors.greenAccent, size: 120),
            const SizedBox(height: 24),
            Text(
              "Anda Adalah Pengguna Premium",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nikmati semua fitur tanpa batas!",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeView() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _checkInitialPremiumStatus,
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
                      Icons.rocket_launch,
                      size: 60,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Go Premium",
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
                      "Buka semua fitur canggih dengan sekali bayar.",
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

  // All _build... methods for UI remain the same as the previous version
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
            "Rp 30.000",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "SEKALI BAYAR UNTUK SELAMANYA",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const Divider(height: 30, color: Colors.white24),
          _buildFeatureItem(Icons.list_alt, "Buat Daftar Belanja Tanpa Batas"),
          _buildFeatureItem(Icons.auto_awesome, "Rekomendasi AI Tanpa Batas"),
          _buildFeatureItem(Icons.analytics, "Akses ke Fitur Analisis Belanja"),
          _buildFeatureItem(Icons.ads_click, "Bebas dari Semua Iklan"),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
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
        children: [
          const Text(
            "Instruksi Pembayaran",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "1. Email Anda akan otomatis disalin saat klik tombol bayar.",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, height: 1.5),
              children: [
                const TextSpan(
                  text: "2. WAJIB tempel (paste) email ini di kolom ",
                ),
                const TextSpan(
                  text: "'Pesan'",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                const TextSpan(text: " di halaman Saweria."),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    widget.userEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.userEmail),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('Email berhasil disalin!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, color: Colors.orangeAccent),
                  tooltip: 'Salin Email',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
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
      icon: const Icon(Icons.payment, size: 24),
      label: const Text(
        "Bayar Sekarang",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
