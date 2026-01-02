// lib/presentation/screens/upgrade_screen.dart
import 'package:belanja_praktis/services/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ID Produk untuk langganan
const String _monthlySubscriptionId = 'premium_monthly';
const String _yearlySubscriptionId = 'premium_yearly';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen>
    with WidgetsBindingObserver {
  final IapService _iapService = GetIt.I<IapService>();
  bool _isLoading = true;
  String? _error;
  int _selectedPlanIndex = 0;
  List<ProductDetails> _displayProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeIapService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh premium status when app resumes
      _iapService.forceRefreshPremiumStatus();
    }
  }

  Future<void> _initializeIapService() async {
    try {
      setState(() => _isLoading = true);

      // Initialize IAP service
      await _iapService.initialize();

      // Load products - this will be handled by the productsNotifier listener
      await _iapService.loadProducts();

      // Add listener for product updates
      _iapService.productsNotifier.addListener(_updateProducts);
      _iapService.errorNotifier.addListener(_updateError);

      // Initial UI update
      _updateProducts();
      _updateError();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateProducts() {
    if (mounted) {
      setState(() {
        // Update the UI when products change
        if (_iapService.productsNotifier.value.isNotEmpty) {
          _displayProducts = _iapService.productsNotifier.value;
        }
      });
    }
  }

  void _updateError() {
    final msg = _iapService.errorNotifier.value;
    if (!mounted) return;
    if (msg.isEmpty) return;
    setState(() {
      _error = msg;
    });
  }

  @override
  void dispose() {
    _iapService.productsNotifier.removeListener(_updateProducts);
    _iapService.errorNotifier.removeListener(_updateError);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleSubscribe(ProductDetails product) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final success = await _iapService.purchaseSubscription(product);

      if (success) {
        // Force refresh premium status immediately (no delay)
        await _iapService.forceRefreshPremiumStatus();

        // Wait a moment untuk ensure UI state updated
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if premium status updated
        if (mounted && _iapService.isPremiumNotifier.value) {
          // 🎉 SUCCESS - Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "✅ Berhasil! Anda sekarang adalah member Premium!",
                ),
                backgroundColor: Colors.green.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Optional: Navigate after success
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // ⚠️ Payment succeeded but status not updated - show recovery options
          final errorMsg = _iapService.errorNotifier.value;
          if (mounted && errorMsg.isNotEmpty) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                title: const Text('❌ Error Update Database'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Pembayaran berhasil di Google Play!\n'
                        '⚠️ Tapi gagal update database:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          errorMsg,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '💡 Solusi:\n'
                        '1. Klik "Coba Manual Update" untuk retry\n'
                        '2. Atau tunggu beberapa detik & refresh app\n'
                        '3. Jika tetap gagal, hubungi developer',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // Dismiss parent dialog too
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    },
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      // Try manual update
                      try {
                        if (mounted) {
                          setState(() => _isLoading = true);
                        }

                        // Clear error
                        _iapService.errorNotifier.value = '';

                        // Trigger manual update
                        await _iapService.forceUpdatePremiumManual(product.id);

                        // Wait untuk ensure database updated
                        await Future.delayed(const Duration(seconds: 1));

                        // Refresh status
                        await _iapService.forceRefreshPremiumStatus();

                        if (mounted) {
                          setState(() => _isLoading = false);

                          // Check if success
                          if (_iapService.isPremiumNotifier.value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  '✅ Manual update berhasil! Premium status diperbarui.',
                                ),
                                backgroundColor: Colors.green.shade400,
                                duration: const Duration(seconds: 3),
                              ),
                            );

                            // Navigate back
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          } else {
                            // Still not updated
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  '⚠️ Manual update ditjalankan tapi status belum berubah.\n'
                                  'Silakan tunggu beberapa saat & refresh app.',
                                ),
                                backgroundColor: Colors.orange.shade400,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Manual update gagal: $e'),
                              backgroundColor: Colors.red.shade400,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Coba Manual Update'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // ❌ Purchase failed at Google Play
        final errorMsg = _iapService.errorNotifier.value;
        if (mounted && errorMsg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Pembayaran gagal: $errorMsg'),
              backgroundColor: Colors.red.shade400,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Unexpected error
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan: $e';
        });

        // Show error dialog dengan lebih detail
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('❌ Error'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terjadi kesalahan saat memproses pembayaran:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$e',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan coba lagi atau hubungi developer jika masalah berlanjut.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: _iapService.isPremiumNotifier,
          builder: (context, isPremium, _) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            try {
              return isPremium
                  ? _buildPremiumActiveView()
                  : _buildUpgradeView();
            } catch (e, stackTrace) {
              print('Error in build: $e');
              print('Stack trace: $stackTrace');
              return _buildErrorView(
                _error ?? 'Terjadi kesalahan. Silakan coba lagi.',
              );
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      print('Fatal error in UpgradeScreen: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        body: _buildErrorView('Terjadi kesalahan. Silakan coba lagi.'),
      );
    }
  }

  Widget _buildErrorView(String error) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _initializeIapService();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW: SUDAH PREMIUM ---
  Widget _buildPremiumActiveView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Anda adalah Member Premium",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Nikmati akses tanpa batas ke semua fitur aplikasi. Terima kasih atas dukungan Anda!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Kembali ke Aplikasi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- VIEW: BELUM PREMIUM (UPGRADE) ---
  Widget _buildUpgradeView() {
    // Create default products in case _displayProducts is empty
    final defaultMonthly = _createMockProduct(
      _monthlySubscriptionId,
      'Rp 30.000',
    );
    final defaultYearly = _createMockProduct(
      _yearlySubscriptionId,
      'Rp 300.000',
    );

    final bool canPurchaseSelected = _displayProducts.any(
      (p) =>
          p.id ==
          (_selectedPlanIndex == 0
              ? _monthlySubscriptionId
              : _yearlySubscriptionId),
    );

    // Safely get products with fallback to defaults
    ProductDetails monthly;
    ProductDetails yearly;

    try {
      monthly = _displayProducts.isNotEmpty
          ? _displayProducts.cast<ProductDetails>().firstWhere(
              (p) => p.id == _monthlySubscriptionId,
              orElse: () => defaultMonthly,
            )
          : defaultMonthly;
    } catch (e) {
      print('Error getting monthly product: $e');
      monthly = defaultMonthly;
    }

    try {
      yearly = _displayProducts.isNotEmpty
          ? _displayProducts.cast<ProductDetails>().firstWhere(
              (p) => p.id == _yearlySubscriptionId,
              orElse: () => defaultYearly,
            )
          : defaultYearly;
    } catch (e) {
      print('Error getting yearly product: $e');
      yearly = defaultYearly;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0),
            const Color(0xFF6A1B9A),
            Colors.deepPurple.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Use Positioned.fill to ensure Column has constraints for Expanded
            Positioned.fill(
              child: Column(
                children: [
                  // Custom App Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            "Upgrade Premium",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Hero Icon with glow effect
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.diamond,
                                size: 70,
                                color: Colors.amber,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "Buka Potensi Penuh",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Tanpa Iklan. Tanpa Batas. Fitur AI.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Features Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildFeatureRow(
                                  Icons.block,
                                  "Bebas Iklan Sepenuhnya",
                                  Colors.orange.shade600,
                                ),
                                const SizedBox(height: 20),
                                _buildFeatureRow(
                                  Icons.auto_awesome,
                                  "Rekomendasi AI Smart",
                                  Colors.purple.shade600,
                                ),
                                const SizedBox(height: 20),
                                _buildFeatureRow(
                                  Icons.list_alt_rounded,
                                  "Unlimited Daftar Belanja",
                                  Colors.blue.shade600,
                                ),
                                const SizedBox(height: 20),
                                _buildFeatureRow(
                                  Icons.cloud_done_rounded,
                                  "Prioritas Cloud Sync",
                                  Colors.green.shade600,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Subscription Plans Title
                          const Text(
                            "Pilih Paket Langganan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // KARTU LANGGANAN - LANGSUNG DITAMPILKAN
                          _buildModernPlanCard(
                            title: "Bulanan",
                            price: monthly.price,
                            period: "/bulan",
                            description: "Fleksibel, bisa berhenti kapan saja",
                            isSelected: _selectedPlanIndex == 0,
                            onTap: () {
                              setState(() => _selectedPlanIndex = 0);
                            },
                            product: monthly,
                          ),
                          const SizedBox(height: 16),
                          _buildModernPlanCard(
                            title: "Tahunan",
                            price: yearly.price,
                            period: "/tahun",
                            description: "Hemat 17% - Pilihan Terbaik!",
                            isSelected: _selectedPlanIndex == 1,
                            isBestValue: true,
                            onTap: () {
                              setState(() => _selectedPlanIndex = 1);
                            },
                            product: yearly,
                          ),

                          const SizedBox(height: 32),

                          // Subscribe Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _handleSubscribe(
                                      _selectedPlanIndex == 0
                                          ? monthly
                                          : yearly,
                                    ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                backgroundColor: canPurchaseSelected
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                                foregroundColor: canPurchaseSelected
                                    ? Colors.black87
                                    : Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: canPurchaseSelected ? 8 : 0,
                                shadowColor: Colors.amber.withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black87,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      canPurchaseSelected
                                          ? "Mulai Langganan Sekarang"
                                          : "Langganan (Mode Test/Debug)",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : _iapService.restorePurchases,
                            child: Text(
                              "Sudah berlangganan? Pulihkan Pembelian",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildFeatureRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Icon(Icons.check_circle, color: color, size: 20),
      ],
    );
  }

  Widget _buildModernPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required ProductDetails product,
    bool isBestValue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isBestValue
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade600,
                              fontWeight: isBestValue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          period,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Best Value Badge
            if (isBestValue)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "TERPOPULER",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Selection indicator
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.amber : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.amber : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.black87)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ProductDetails _createMockProduct(String id, String price) {
    try {
      return ProductDetails(
        id: id,
        title: id == _monthlySubscriptionId
            ? 'Premium Bulanan'
            : 'Premium Tahunan',
        description: 'Akses penuh ke semua fitur premium',
        price: price,
        rawPrice: id == _monthlySubscriptionId ? 30000.0 : 300000.0,
        currencyCode: 'IDR',
      );
    } catch (e) {
      print('Error creating mock product: $e');
      // Return a minimal valid ProductDetails object as fallback
      return ProductDetails(
        id: id,
        title: id == _monthlySubscriptionId
            ? 'Premium Bulanan'
            : 'Premium Tahunan',
        description: 'Akses penuh ke semua fitur premium',
        price: price,
        rawPrice: id == _monthlySubscriptionId ? 30000.0 : 300000.0,
        currencyCode: 'IDR',
      );
    }
  }
}
