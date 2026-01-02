import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Production Native Ad Unit ID from AdMob Console
  final adUnitId = 'ca-app-pub-3782639799703896/9834326592';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    debugPrint('🔄 Starting to load native ad...');
    debugPrint('Native Ad Unit ID: $adUnitId');

    // Set timeout to hide loading after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading && !_isLoaded) {
        debugPrint('⏱️ Native ad loading timeout - hiding widget');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Timeout';
        });
      }
    });

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ NATIVE AD LOADED SUCCESSFULLY');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
              _errorMessage = null;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ NATIVE AD FAILED TO LOAD');
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
          _nativeAd = null;

          // Auto retry after 5 seconds if error code is 3 (no fill)
          if (error.code == 3) {
            debugPrint('⏳ No fill - will retry in 5 seconds...');
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && !_isLoaded) {
                debugPrint('🔄 Retrying native ad load...');
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
          debugPrint('📱 Native ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('❌ Native ad closed');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        // Template type
        templateType: TemplateType.medium,
        // Main background color
        mainBackgroundColor: Colors.white,
        // Corner radius
        cornerRadius: 12.0,
        // Call to action style
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.purple,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        // Primary text style (headline)
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        // Secondary text style (body)
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        // Tertiary text style (advertiser)
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black45,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // Ad loaded successfully
    if (_nativeAd != null && _isLoaded) {
      debugPrint('✅ Rendering native ad widget');
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _nativeAd!),
        ),
      );
    }

    // Ad failed to load - hide widget completely
    if (_errorMessage != null && !_isLoading) {
      debugPrint('❌ Native ad failed, hiding widget completely');
      return const SizedBox.shrink();
    }

    // Loading state - hide after timeout
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _nativeAd?.dispose();
    }
    super.dispose();
  }
}
