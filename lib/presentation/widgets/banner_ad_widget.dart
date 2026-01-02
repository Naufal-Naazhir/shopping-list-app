import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Production Banner Ad Unit ID from AdMob Console
  final adUnitId = 'ca-app-pub-3782639799703896/5679459162';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    debugPrint('🔄 Starting to load banner ad...');
    debugPrint('Ad Unit ID: $adUnitId');
    debugPrint('Debug mode: $kDebugMode');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ BANNER AD LOADED SUCCESSFULLY');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
              _errorMessage = null;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ BANNER AD FAILED TO LOAD');
          debugPrint('Error code: ${error.code}');
          debugPrint('Error message: ${error.message}');
          debugPrint('Error domain: ${error.domain}');

          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Code ${error.code}: ${error.message}';
            });
          }

          ad.dispose();
          _bannerAd = null;

          // Auto retry after 5 seconds if error code is 3 (no fill)
          if (error.code == 3) {
            debugPrint('⏳ No fill - will retry in 5 seconds...');
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && !_isLoaded) {
                debugPrint('🔄 Retrying ad load...');
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadAd();
              }
            });
          }
        },
        onAdOpened: (ad) {
          debugPrint('📱 Ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('❌ Ad closed');
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // Ad loaded successfully
    if (_bannerAd != null && _isLoaded) {
      debugPrint('✅ Rendering banner ad widget');
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    // Ad failed to load - hide widget completely instead of showing error
    if (_errorMessage != null && !_isLoading) {
      debugPrint('❌ Ad failed, hiding widget completely');
      // Return empty widget - no error message shown to user
      return const SizedBox.shrink();
    }

    // Loading state - with timeout
    if (_isLoading) {
      // Set timeout to hide loading after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isLoading && !_isLoaded) {
          debugPrint('⏱️ Ad loading timeout - hiding widget');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Timeout';
          });
        }
      });
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading ad...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _bannerAd?.dispose();
    }
    super.dispose();
  }
}
