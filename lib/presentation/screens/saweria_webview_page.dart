import 'dart:async';

import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/services/appwrite_user_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SaweriaWebviewPage extends StatefulWidget {
  final String url;

  const SaweriaWebviewPage({super.key, required this.url});

  @override
  State<SaweriaWebviewPage> createState() => _SaweriaWebviewPageState();
}

class _SaweriaWebviewPageState extends State<SaweriaWebviewPage> {
  // Services
  late final WebViewController _controller;
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  final AppwriteUserService _userService = GetIt.I<AppwriteUserService>();

  // State variables
  double _progress = 0;
  bool _showLoading = true;
  bool _hasError = false;
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  int _pollingAttempts = 0;
  static const int maxPollingAttempts = 60; // 5 menit (60 * 5 detik)

  bool _isValidSaweriaUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.host.endsWith('saweria.co') || uri.host.endsWith('saweria.id')) &&
        uri.scheme == 'https';
  }

  bool _isValidDonationAmount(String? url) {
    if (url == null) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Cek jika URL mengandung parameter amount
    final amountParam = uri.queryParameters['amount'];
    if (amountParam != null) {
      final amount = int.tryParse(amountParam) ?? 0;
      return amount >= 30000;
    }

    // Jika tidak ada parameter amount, biarkan melewati (default Saweria akan menangani)
    return true;
  }

  // Helper methods
  void _logEvent(String event) {
    debugPrint('SaweriaWebview - $event');
  }

  void _logError(String error) {
    debugPrint('SaweriaWebview - ERROR - $error');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      Future.microtask(() => context.pop());
    }
  }

  @override
  void initState() {
    super.initState();
    _logEvent('Initializing WebView');

    if (!_isValidSaweriaUrl(widget.url)) {
      _showError('URL pembayaran tidak valid');
      return;
    }

    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _progress = progress / 100;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _showLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _showLoading = false;
                });
                if (!_isPollingActive) {
                  _startPolling();
                }
              }
            },
            onWebResourceError: (WebResourceError error) {
              _logError(
                'WebView Error ${error.errorCode}: ${error.description}',
              );
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _showLoading = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (!_isValidSaweriaUrl(request.url)) {
                _logEvent('Blocked navigation to external URL: ${request.url}');
                return NavigationDecision.prevent;
              }

              // Validasi nominal donasi
              if (!_isValidDonationAmount(request.url)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Minimum donasi adalah Rp 30.000'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } catch (e) {
      _logError('Initialize WebView: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat halaman pembayaran'),
            backgroundColor: Colors.red,
          ),
        );
        Future.microtask(() => context.pop());
      }
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        _logError('Check Premium: User not authenticated');
        _stopPolling();
        return;
      }

      final isPremium = await _userService.isUserPremium(currentUser.uid);
      _logEvent(
        'Premium status checked - isPremium: $isPremium, userId: ${currentUser.uid}',
      );

      if (isPremium) {
        _handlePaymentSuccess();
      } else if (_pollingAttempts >= maxPollingAttempts) {
        _handlePaymentTimeout();
      }
    } catch (e) {
      _logError('Check Premium: ${e.toString()}');
      // Continue polling on error, but log it
      if (_pollingAttempts >= maxPollingAttempts) {
        _handlePaymentTimeout();
      }
    }
  }

  Future<void> _startPolling() async {
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser?.uid == null) {
        _logError('Start Polling: User ID not found');
        _showError('Sesi tidak valid. Silakan login kembali.');
        return;
      }

      _logEvent('Starting polling for user: ${currentUser?.uid ?? 'unknown'}');

      if (mounted) {
        setState(() {
          _isPollingActive = true;
          _pollingAttempts = 0;
        });
      }

      _pollingTimer?.cancel(); // Cancel any existing timer
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_pollingAttempts >= maxPollingAttempts) {
          _handlePaymentTimeout();
          return;
        }

        await _checkPremiumStatus();

        if (mounted) {
          setState(() {
            _pollingAttempts++;
          });
        }
      });
    } catch (e) {
      _logError('Start Polling: ${e.toString()}');
      _showError('Gagal memulai pemantauan pembayaran');
    }
  }

  void _handlePaymentSuccess() {
    _logEvent('Payment successful. Attempts: $_pollingAttempts');
    _stopPolling();

    if (!mounted) return;

    // Close the WebView first
    if (context.canPop()) {
      Navigator.of(context).pop();
    }

    // Show success dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            "Pembayaran Berhasil!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Terima kasih! Status premium Anda akan segera aktif.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "ID Transaksi: #${DateTime.now().millisecondsSinceEpoch}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/'); // Navigate to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Kembali ke Beranda",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handlePaymentTimeout() {
    _logEvent('Payment timeout after $maxPollingAttempts attempts');
    _stopPolling();

    if (!mounted) return;

    if (context.canPop()) {
      Navigator.of(context).pop(); // Close WebView
    }

    // Show timeout dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            "Waktu Pembayaran Habis",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_off, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Pembayaran tidak terdeteksi dalam waktu yang ditentukan.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Silakan coba lagi nanti atau hubungi tim dukungan jika sudah melakukan pembayaran.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                "Percobaan: $_pollingAttempts/$maxPollingAttempts",
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Tutup"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startPolling(); // Retry polling
                  },
                  child: const Text("Coba Lagi"),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _stopPolling() {
    _logEvent('Stopping polling after $_pollingAttempts attempts');
    _pollingTimer?.cancel();
    _pollingTimer = null;

    if (mounted) {
      setState(() {
        _isPollingActive = false;
      });
    } else {
      _isPollingActive = false;
    }
  }

  @override
  void dispose() {
    _logEvent('Disposing WebView');
    _stopPolling();
    try {
      _controller.clearCache();
      // Clear any existing dialogs when disposing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _logError('Error during dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _stopPolling();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pembayaran Saweria',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _stopPolling();
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
          actions: [
            if (_isPollingActive)
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                child: Text(
                  'Memeriksa... ${_pollingAttempts * 5} detik',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            // Main content
            if (_hasError)
              _buildErrorView()
            else
              WebViewWidget(controller: _controller),

            // Loading indicator
            if (_showLoading) _buildLoadingIndicator(),

            // Overlay for polling status
            if (_isPollingActive) _buildPollingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 72),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat Halaman Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Pastikan koneksi internet Anda stabil dan coba lagi. Jika masalah berlanjut, silakan hubungi dukungan pelanggan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _showLoading = true;
                });
                _initializeWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress < 0 ? null : _progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 3,
        ),
        if (_progress > 0 && _progress < 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPollingOverlay() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Memeriksa status pembayaran...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_pollingAttempts * 5}s / ${maxPollingAttempts * 5}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
